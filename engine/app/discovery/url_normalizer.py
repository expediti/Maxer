import re
from urllib.parse import urljoin, urlparse, urlunparse, parse_qs, urlencode

def normalize_url(base_url: str, link: str) -> str:
    """Combines relative link with base URL and removes tracking parameters."""
    if not link:
        return ""
    absolute_url = urljoin(base_url, link.strip())
    parsed = urlparse(absolute_url)

    # Filter out analytics query parameters
    query_params = parse_qs(parsed.query)
    clean_params = {k: v for k, v in query_params.items() if not k.startswith("utm_") and k not in {"fbclid", "gclid"}}
    clean_query = urlencode(clean_params, doseq=True)

    clean_url = urlunparse((
        parsed.scheme.lower(),
        parsed.netloc.lower(),
        parsed.path,
        parsed.params,
        clean_query,
        "" # discard fragment
    ))
    return clean_url

def slugify(text: str) -> str:
    """Converts a title or name into a clean, URL-safe slug."""
    text = text.lower().strip()
    text = re.sub(r'[\(\)\[\]\{\}\'"\.,:;`]', '', text)
    text = re.sub(r'[\s_/-]+', '-', text)
    text = re.sub(r'^-+|-+$', '', text)
    return text[:100]

