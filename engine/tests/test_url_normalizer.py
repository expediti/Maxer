import pytest
from engine.app.discovery.url_normalizer import normalize_url, slugify

def test_normalize_url_removes_utm_and_resolves_relative():
    base = "https://upsc.gov.in/examinations/active-exams"
    relative_link = "/sites/default/files/cse_2026.pdf?utm_source=twitter&utm_medium=social"
    clean_url = normalize_url(base, relative_link)
    assert clean_url == "https://upsc.gov.in/sites/default/files/cse_2026.pdf"

def test_slugify():
    title = "Civil Services Examination (Preliminary) 2026"
    slug = slugify(title)
    assert slug == "civil-services-examination-preliminary-2026"

def test_slugify_with_special_characters():
    title = "Scientist/Engineer 'SC' — Computer Science & Engineering"
    slug = slugify(title)
    assert "scientist" in slug
    assert "engineer" in slug
    assert "'" not in slug
    assert "/" not in slug

