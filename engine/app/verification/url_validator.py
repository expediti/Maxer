"""
REXAM URL VALIDATION & OFFICIAL DESTINATION VERIFICATION SERVICE
Validates syntax, DNS resolution, HTTPS certificates, HTTP response status,
and redirect chains for official recruitment application and notification URLs.

CRITICAL INVARIANTS:
1. NEVER blindly prepend 'www.' — many legitimate government and university domains
   do not use 'www' (e.g., upsc.gov.in, ssc.gov.in, ibps.in).
2. NEVER strip required query parameters or fragment identifiers.
3. Fallback to GET with stream=True when servers block HTTP HEAD requests.
4. Temporary server timeouts must NOT permanently invalidate legitimate official portals.
"""

import socket
import ssl
import logging
import re
from typing import Dict, Any, Optional, List, Tuple
from urllib.parse import urlparse, urljoin, urlunparse, parse_qs, urlencode
from datetime import datetime, timezone
import requests

logger = logging.getLogger("rexam.url_validator")

# Predefined trusted top-level and institutional domain suffixes
OFFICIAL_GOV_DOMAINS = (
    ".gov.in",
    ".nic.in",
    ".ac.in",
    ".res.in",
    ".edu.in",
    ".org.in",
    ".mil.in",
    ".bank.in",
    ".aero",
)

# Legitimate third-party application portals trusted by government bodies
TRUSTED_THIRD_PARTY_PORTALS = {
    "online-inspire.gov.in",
    "pmrf.in",
    "ibps.in",
    "nta.ac.in",
    "tcsion.com",
    "cbtexam.in",
    "cdn.digialm.com",
    "applycareer.co.in",
    "beciljobs.com",
    "recruitmentindia.in",
}

class URLValidationStatus:
    VERIFIED = "VERIFIED"
    REDIRECTED_VERIFIED = "REDIRECTED_VERIFIED"
    TEMPORARILY_UNAVAILABLE = "TEMPORARILY_UNAVAILABLE"
    INVALID_DNS = "INVALID_DNS"
    INVALID_URL = "INVALID_URL"
    DOMAIN_MISMATCH = "DOMAIN_MISMATCH"
    NEEDS_REVIEW = "NEEDS_REVIEW"

class URLValidationResult:
    def __init__(
        self,
        original_url: str,
        validated_url: Optional[str] = None,
        final_redirect_url: Optional[str] = None,
        http_status: Optional[int] = None,
        dns_status: str = "UNKNOWN",
        validation_status: str = URLValidationStatus.NEEDS_REVIEW,
        error_message: Optional[str] = None,
        redirect_chain: Optional[List[str]] = None,
        is_https: bool = False,
    ):
        self.original_url = original_url
        self.validated_url = validated_url or original_url
        self.final_redirect_url = final_redirect_url or self.validated_url
        self.http_status = http_status
        self.dns_status = dns_status
        self.validation_status = validation_status
        self.error_message = error_message
        self.redirect_chain = redirect_chain or []
        self.is_https = is_https
        self.last_checked_at = datetime.now(timezone.utc).isoformat()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "original_url": self.original_url,
            "validated_url": self.validated_url,
            "final_redirect_url": self.final_redirect_url,
            "http_status": self.http_status,
            "dns_status": self.dns_status,
            "validation_status": self.validation_status,
            "error_message": self.error_message,
            "redirect_chain": self.redirect_chain,
            "is_https": self.is_https,
            "last_checked_at": self.last_checked_at,
        }

    def get(self, key: str, default: Any = None) -> Any:
        if key in ("status", "validation_status"):
            return self.validation_status
        if key in ("resolved_url", "final_redirect_url"):
            return self.final_redirect_url or self.validated_url
        if key == "is_valid":
            return self.validation_status in (URLValidationStatus.VERIFIED, URLValidationStatus.REDIRECTED_VERIFIED)
        if key in ("status_code", "http_status_code", "http_status"):
            return self.http_status
        return self.to_dict().get(key, default)

    def __getitem__(self, key: str) -> Any:
        val = self.get(key)
        if val is None and key not in self.to_dict():
            raise KeyError(key)
        return val

class OfficialURLValidator:
    def __init__(self, timeout_seconds: int = 10):
        self.timeout = timeout_seconds
        self.user_agent = (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 (Rexam Official Verification Engine)"
        )

    def normalize_link(self, raw_link: str, base_source_url: Optional[str] = None) -> Optional[str]:
        """
        Cleans and normalizes URL preserving legitimate parameters.
        Does NOT inject 'www.' blindly.
        """
        if not raw_link or not isinstance(raw_link, str):
            return None

        link = raw_link.strip()
        # Discard placeholder and javascript strings
        if link.lower().startswith(("javascript:", "#", "mailto:", "tel:", "void(0)")):
            return None

        # Resolve relative URLs
        if base_source_url and not link.startswith(("http://", "https://")):
            link = urljoin(base_source_url, link)

        if not link.startswith(("http://", "https://")):
            # If scheme missing, default to https without adding www
            link = f"https://{link}"

        try:
            parsed = urlparse(link)
            if not parsed.hostname:
                return None

            hostname = parsed.hostname.lower()
            # Incomplete domain check (e.g. single word without TLD)
            if "." not in hostname:
                return None

            # Reconstruct clean URL preserving query params and path
            clean_url = urlunparse((
                parsed.scheme.lower(),
                hostname if not parsed.port else f"{hostname}:{parsed.port}",
                parsed.path or "/",
                parsed.params,
                parsed.query,
                parsed.fragment,
            ))
            return clean_url
        except Exception:
            return None

    def check_dns(self, hostname: str) -> Tuple[bool, str]:
        """Resolves DNS for a hostname."""
        try:
            socket.getaddrinfo(hostname, None)
            return True, "RESOLVED"
        except socket.gaierror as e:
            return False, f"DNS_RESOLUTION_FAILED: {e}"
        except Exception as e:
            return False, f"DNS_ERROR: {e}"

    def validate_url(
        self,
        raw_url: str,
        base_source_url: Optional[str] = None,
        expected_organisation: Optional[str] = None,
        expected_official_domain: Optional[str] = None,
    ) -> URLValidationResult:
        """
        Runs comprehensive multi-stage validation:
        1. Syntax check & normalization.
        2. DNS resolution.
        3. HTTPS / HTTP request (handling HEAD block via GET stream).
        4. Redirect chain evaluation.
        5. Domain authenticity check.
        """
        if not raw_url or not isinstance(raw_url, str):
            return URLValidationResult(
                original_url=str(raw_url or ""),
                validation_status=URLValidationStatus.INVALID_URL,
                error_message="Empty or non-string URL provided."
            )

        clean_url = self.normalize_link(raw_url, base_source_url)
        if not clean_url:
            return URLValidationResult(
                original_url=raw_url,
                validation_status=URLValidationStatus.INVALID_URL,
                error_message="Could not parse or normalize URL structure."
            )

        parsed = urlparse(clean_url)
        hostname = (parsed.hostname or "").lower()

        # Step 2: DNS Resolution
        dns_ok, dns_msg = self.check_dns(hostname)
        if not dns_ok:
            # Check if domain has a known alias (e.g. www vs non-www fallback attempt)
            alt_hostname = hostname[4:] if hostname.startswith("www.") else f"www.{hostname}"
            alt_dns_ok, _ = self.check_dns(alt_hostname)
            if alt_dns_ok:
                # Redirect to valid alternative hostname
                clean_url = clean_url.replace(hostname, alt_hostname, 1)
                hostname = alt_hostname
                dns_ok = True
                dns_msg = "RESOLVED_VIA_CANONICAL_ALTERNATIVE"
            else:
                return URLValidationResult(
                    original_url=raw_url,
                    validated_url=clean_url,
                    dns_status=dns_msg,
                    validation_status=URLValidationStatus.INVALID_DNS,
                    error_message=f"DNS resolution failed for hostname: {hostname}",
                    is_https=parsed.scheme == "https",
                )

        # Step 3: Network Check (HTTP/HTTPS)
        headers = {
            "User-Agent": self.user_agent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
        }

        redirect_chain: List[str] = [clean_url]
        http_status: Optional[int] = None
        final_url = clean_url

        try:
            # Attempt HEAD first for bandwidth efficiency
            session = requests.Session()
            session.headers.update(headers)

            response = None
            try:
                response = session.head(
                    clean_url,
                    allow_redirects=True,
                    timeout=self.timeout,
                    verify=True,
                )
                http_status = response.status_code
            except (requests.exceptions.SSLError, requests.exceptions.RequestException):
                # Fallback to GET with stream=True if HEAD is 403, 405, method not allowed or SSL issues
                pass

            if response is None or response.status_code in (403, 405, 501, 503):
                try:
                    response = session.get(
                        clean_url,
                        allow_redirects=True,
                        timeout=self.timeout,
                        stream=True,
                        verify=True,
                    )
                    http_status = response.status_code
                    # Close stream immediately
                    response.close()
                except requests.exceptions.SSLError as ssl_err:
                    # Some Indian government servers (.gov.in / .nic.in) use national CCA root certs
                    try:
                        response = session.get(
                            clean_url,
                            allow_redirects=True,
                            timeout=self.timeout,
                            stream=True,
                            verify=False,
                        )
                        http_status = response.status_code
                        response.close()
                        logger.warning(f"URL {clean_url} required non-strict SSL verification: {ssl_err}")
                    except Exception as e:
                        return URLValidationResult(
                            original_url=raw_url,
                            validated_url=clean_url,
                            dns_status="RESOLVED",
                            validation_status=URLValidationStatus.TEMPORARILY_UNAVAILABLE,
                            error_message=f"SSL or connection error: {e}",
                            is_https=parsed.scheme == "https",
                        )
                except (requests.exceptions.Timeout, requests.exceptions.ConnectTimeout):
                    return URLValidationResult(
                        original_url=raw_url,
                        validated_url=clean_url,
                        dns_status="RESOLVED",
                        validation_status=URLValidationStatus.TEMPORARILY_UNAVAILABLE,
                        error_message="Server connection timed out. Marked temporarily unavailable.",
                        is_https=parsed.scheme == "https",
                    )
                except requests.exceptions.RequestException as req_err:
                    return URLValidationResult(
                        original_url=raw_url,
                        validated_url=clean_url,
                        dns_status="RESOLVED",
                        validation_status=URLValidationStatus.TEMPORARILY_UNAVAILABLE,
                        error_message=f"Request failed: {req_err}",
                        is_https=parsed.scheme == "https",
                    )

            if response is not None:
                http_status = response.status_code
                final_url = response.url
                if response.history:
                    redirect_chain = [r.url for r in response.history] + [final_url]

        except Exception as e:
            logger.warning(f"Unexpected error validating {clean_url}: {e}")
            return URLValidationResult(
                original_url=raw_url,
                validated_url=clean_url,
                dns_status=dns_msg,
                validation_status=URLValidationStatus.TEMPORARILY_UNAVAILABLE,
                error_message=f"Validation error: {e}",
            )

        # Step 4: Evaluate Final Destination & Authenticity
        final_parsed = urlparse(final_url)
        final_hostname = (final_parsed.hostname or "").lower()

        # Check domain mismatch if an expected official domain was specified
        is_trusted_gov = any(final_hostname.endswith(sfx) for sfx in OFFICIAL_GOV_DOMAINS)
        is_trusted_portal = any(portal in final_hostname for portal in TRUSTED_THIRD_PARTY_PORTALS)

        if expected_official_domain:
            exp_clean = expected_official_domain.lower().replace("https://", "").replace("http://", "").split("/")[0]
            if not (final_hostname.endswith(exp_clean) or exp_clean.endswith(final_hostname) or is_trusted_portal):
                logger.info(f"Domain mismatch for {raw_url}: final={final_hostname} vs expected={exp_clean}")
                return URLValidationResult(
                    original_url=raw_url,
                    validated_url=clean_url,
                    final_redirect_url=final_url,
                    http_status=http_status,
                    dns_status="RESOLVED",
                    validation_status=URLValidationStatus.DOMAIN_MISMATCH,
                    error_message=f"Destination hostname {final_hostname} does not match expected {exp_clean}",
                    redirect_chain=redirect_chain,
                    is_https=final_parsed.scheme == "https",
                )

        # Step 5: Assign final status based on HTTP code
        if http_status and (200 <= http_status < 400):
            if len(redirect_chain) > 1:
                v_status = URLValidationStatus.REDIRECTED_VERIFIED
            else:
                v_status = URLValidationStatus.VERIFIED
        elif http_status in (401, 403):
            # Many application portals require login or block automated crawlers (Cloudflare/WAF)
            # If DNS resolved and it is a trusted gov or recruitment portal, mark as VERIFIED or NEEDS_REVIEW
            if is_trusted_gov or is_trusted_portal:
                v_status = URLValidationStatus.VERIFIED
            else:
                v_status = URLValidationStatus.NEEDS_REVIEW
        elif http_status in (404, 410):
            v_status = URLValidationStatus.INVALID_URL
        else:
            v_status = URLValidationStatus.TEMPORARILY_UNAVAILABLE

        return URLValidationResult(
            original_url=raw_url,
            validated_url=clean_url,
            final_redirect_url=final_url,
            http_status=http_status,
            dns_status="RESOLVED",
            validation_status=v_status,
            redirect_chain=redirect_chain,
            is_https=final_parsed.scheme == "https",
        )

url_validator = OfficialURLValidator()

