import hashlib
from pathlib import Path

def compute_sha256(data: bytes) -> str:
    """Computes SHA-256 hash of byte content."""
    return hashlib.sha256(data).hexdigest()

def compute_file_sha256(file_path: str) -> str:
    """Computes SHA-256 hash of a file on disk."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()

