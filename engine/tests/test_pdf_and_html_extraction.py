import pytest
from engine.app.extraction.html_extractor import html_extractor
from engine.app.extraction.pdf_extractor import pdf_extractor

def test_html_table_notice_extraction():
    sample_html = """
    <html>
      <head><title>Active Examinations - Recruitment Commission</title></head>
      <body>
        <table>
          <thead>
            <tr><th>Sr No</th><th>Exam Title</th><th>Last Date</th><th>Notification</th></tr>
          </thead>
          <tbody>
            <tr>
              <td>1</td>
              <td>Combined Graduate Level Examination 2026</td>
              <td>15-06-2026</td>
              <td><a href="/docs/Notice_CGL_2026.pdf">Download PDF</a></td>
            </tr>
            <tr>
              <td>2</td>
              <td>Junior Engineer (Civil, Mechanical) 2026</td>
              <td>20-07-2026</td>
              <td><a href="/docs/Notice_JE_2026.pdf">View Advertisement</a></td>
            </tr>
          </tbody>
        </table>
      </body>
    </html>
    """
    res = html_extractor.extract_links_and_tables(sample_html, "https://commission.gov.in")
    assert res["title"] == "Active Examinations - Recruitment Commission"
    assert len(res["table_notices"]) >= 2
    assert "Combined Graduate Level" in res["table_notices"][0]["title"]
    assert res["table_notices"][0]["pdf_url"].endswith("Notice_CGL_2026.pdf")
    assert "Junior Engineer" in res["table_notices"][1]["title"]

def test_pdf_section_patterns():
    from engine.app.extraction.pdf_extractor import SECTION_PATTERNS
    sample_text = """
    GOVERNMENT OF INDIA
    1. DETAILS OF VACANCIES: Total vacancies are 150.
    2. MINIMUM EDUCATIONAL QUALIFICATION: Must possess Degree in Engineering.
    3. AGE LIMIT: Crucial date for age calculation is 01-08-2026. Age between 18 and 30 years.
    4. APPLICATION FEE: Fee payable is Rs 100/-. SC/ST candidates exempted.
    """
    assert SECTION_PATTERNS["vacancies"].search(sample_text) is not None
    assert SECTION_PATTERNS["eligibility"].search(sample_text) is not None
    assert SECTION_PATTERNS["age_limit"].search(sample_text) is not None
    assert SECTION_PATTERNS["application_fee"].search(sample_text) is not None

def test_pdf_evidence_snippet_finder():
    mock_doc = {
        "pages": [
            {"page_number": 1, "text": "Notice overview and table of contents"},
            {"page_number": 2, "text": "Candidates must have completed Bachelor of Technology with minimum 60% aggregate."},
            {"page_number": 3, "text": "Exam scheme and syllabus breakdown"},
        ]
    }
    evidence = pdf_extractor.find_evidence_snippet(mock_doc, "Bachelor of Technology")
    assert evidence is not None
    assert evidence["page_number"] == 2
    assert "Bachelor of Technology" in evidence["evidence_text"]

