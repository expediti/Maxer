import os
import time
import asyncio
import logging
import httpx
from pathlib import Path
from typing import Optional, Tuple
from engine.app.config.settings import settings
from engine.app.deduplication.hasher import compute_sha256

logger = logging.getLogger("rexam.downloader")

class DocumentDownloader:
    def __init__(self):
        self.storage_dir = Path(settings.STORAGE_DIR)
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self.headers = {
            "User-Agent": settings.CRAWLER_USER_AGENT,
            "Accept": "application/pdf,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9,hi;q=0.8",
        }

    async def download_file(self, url: str) -> Optional[Tuple[str, str, bytes]]:
        """
        Downloads a document from the specified URL.
        Returns: Tuple of (file_path_on_disk, sha256_hash, raw_bytes) or None on failure.
        """
        logger.info(f"Downloading document from {url}...")
        try:
            async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_SECONDS, follow_redirects=True) as client:
                response = await client.get(url, headers=self.headers)
                if response.status_code != 200:
                    logger.warning(f"Download failed with status {response.status_code} for {url}")
                    return None

                content = response.content
                doc_hash = compute_sha256(content)

                # Determine extension
                content_type = response.headers.get("content-type", "").lower()
                ext = ".pdf" if "pdf" in content_type or url.lower().endswith(".pdf") else ".html"

                file_name = f"{doc_hash}{ext}"
                file_path = self.storage_dir / file_name

                with open(file_path, "wb") as f:
                    f.write(content)

                logger.info(f"Saved {len(content)} bytes to {file_path} (Hash: {doc_hash[:12]})")
                return str(file_path), doc_hash, content
        except Exception as e:
            logger.error(f"Error downloading {url}: {e}")
            return None

downloader = DocumentDownloader()

