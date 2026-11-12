import pytest
from pathlib import Path

WORKFLOWS_DIR = Path(".github/workflows")

def test_daily_discovery_workflow_schedule_and_structure():
    discovery_file = WORKFLOWS_DIR / "discovery.yml"
    assert discovery_file.exists(), "discovery.yml must exist"
    content = discovery_file.read_text()

    # 01:00 UTC = 06:30 IST schedule requirement
    assert "0 1 * * *" in content, "Workflow must schedule daily at 01:00 UTC (06:30 IST)"
    # workflow_dispatch
    assert "workflow_dispatch:" in content
    # concurrency policy
    assert "concurrency:" in content
    assert "cancel-in-progress: false" in content
    # engine call
    assert "python -m engine.app.jobs.discovery_job" in content

def test_initial_full_discovery_workflow_structure():
    init_file = WORKFLOWS_DIR / "initial-full-discovery.yml"
    assert init_file.exists(), "initial-full-discovery.yml must exist"
    content = init_file.read_text()

    assert "Rexam Initial Full Discovery" in content
    assert "workflow_dispatch:" in content
    assert "python -m engine.app.jobs.initial_full_discovery_job" in content
    assert "concurrency:" in content

