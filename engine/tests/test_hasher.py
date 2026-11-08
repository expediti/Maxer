import pytest
from engine.app.deduplication.hasher import compute_sha256

def test_compute_sha256_known_value():
    data = b"REXAM Examination Notification Test Content"
    hash1 = compute_sha256(data)
    hash2 = compute_sha256(data)
    assert hash1 == hash2
    assert len(hash1) == 64
    assert isinstance(hash1, str)

def test_compute_sha256_different_values():
    h1 = compute_sha256(b"Notification 1")
    h2 = compute_sha256(b"Notification 2")
    assert h1 != h2

