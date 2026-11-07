import pytest
from fastapi.testclient import TestClient
import sys
import os

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_list_opportunities():
    response = client.get("/api/v1/opportunities")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert len(data["items"]) >= 2

def test_get_single_opportunity():
    response = client.get("/api/v1/opportunities/opp-upsc-cse-2026")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "opp-upsc-cse-2026"
    assert "Civil Services" in data["title"]
    assert data["organisation"] == "Union Public Service Commission (UPSC)"

def test_search_opportunities():
    response = client.get("/api/v1/opportunities/search?q=ISRO")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    assert any("ISRO" in item["organisation"] for item in data)

def test_recommended_opportunities():
    response = client.get("/api/v1/opportunities/recommended")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_closing_soon_opportunities():
    response = client.get("/api/v1/opportunities/closing-soon")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_candidate_profile():
    response = client.get("/api/v1/candidates/me")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "candidate-rexam-001"
    assert "Arjun Sharma" in data["full_name"]

def test_update_candidate_profile():
    payload = {"full_name": "Arjun Sharma", "state": "Delhi", "highest_qualification": "B.Tech / B.E."}
    response = client.put("/api/v1/candidates/me", json=payload)
    assert response.status_code == 200
    assert response.json()["highest_qualification"] == "B.Tech / B.E."

def test_eligibility_report():
    response = client.get("/api/v1/candidates/me/eligibility?opportunity_id=opp-upsc-cse-2026")
    assert response.status_code == 200
    data = response.json()
    assert data["overall_status"] == "Eligible"
    assert len(data["criteria_results"]) >= 2

def test_save_and_unsave_opportunity():
    save_resp = client.post("/api/v1/opportunities/opp-upsc-cse-2026/save")
    assert save_resp.status_code == 201
    
    unsave_resp = client.delete("/api/v1/opportunities/opp-upsc-cse-2026/save")
    assert unsave_resp.status_code == 200

def test_applications_tracker():
    # List
    list_resp = client.get("/api/v1/applications")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) >= 1
    
    # Create
    new_app = {
        "opportunity_id": "opp-isro-scientist-2026",
        "status": "Preparing Documents",
        "personal_notes": "Getting CGPA conversion certificate"
    }
    create_resp = client.post("/api/v1/applications", json=new_app)
    assert create_resp.status_code == 201
    app_id = create_resp.json()["id"]

    # Patch
    patch_resp = client.patch(f"/api/v1/applications/{app_id}", json={"status": "Applied"})
    assert patch_resp.status_code == 200
    assert patch_resp.json()["status"] == "Applied"

def test_notifications():
    response = client.get("/api/v1/notifications")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "unread_count" in data

def test_admin_crawler_health():
    response = client.get("/api/v1/admin/crawlers/health")
    assert response.status_code == 200
    assert len(response.json()) >= 1
