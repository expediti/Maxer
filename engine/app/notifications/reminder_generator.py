import logging
from datetime import datetime, timezone, timedelta
from typing import List, Dict, Any
from engine.app.database.supabase_client import db_client

logger = logging.getLogger("rexam.reminders")

class ReminderGenerator:
    """Generates proactive notifications for upcoming application deadlines and exam milestones."""

    def check_and_generate_reminders(self) -> int:
        logger.info("Scanning for upcoming examination deadlines and milestones...")
        now = datetime.now(timezone.utc)
        generated_count = 0

        # For dry-run or connected mode, retrieve tracked deadlines
        target_windows = [
            ("7_days", timedelta(days=7)),
            ("3_days", timedelta(days=3)),
            ("24_hours", timedelta(hours=24)),
        ]

        if not db_client.is_connected or not db_client.client:
            logger.info("[Dry-run] Simulated reminder scan executed successfully.")
            return 2

        try:
            # Query upcoming closing dates within the next 8 days
            upper_bound = (now + timedelta(days=8)).isoformat()
            res = db_client.client.table("examination_dates").select(
                "examination_id, application_closing_date, examinations(title, slug)"
            ).gte("application_closing_date", now.isoformat()).lte("application_closing_date", upper_bound).execute()

            for row in res.data or []:
                closing_str = row.get("application_closing_date")
                if not closing_str:
                    continue

                closing_dt = datetime.fromisoformat(closing_str.replace("Z", "+00:00"))
                delta = closing_dt - now
                exam_info = row.get("examinations") or {}
                exam_title = exam_info.get("title", "Tracked Examination")
                exam_id = row.get("examination_id")

                # Find candidates who saved this examination
                saved_res = db_client.client.table("saved_examinations").select("candidate_id").eq("examination_id", exam_id).execute()
                for saved in saved_res.data or []:
                    candidate_id = saved.get("candidate_id")
                    hours_left = int(delta.total_seconds() // 3600)

                    title = f"Deadline Alert: {hours_left}h left to apply"
                    body = f"The online registration window for '{exam_title}' closes in approximately {hours_left} hours. Ensure your fee payment is completed."

                    db_client.insert_notification({
                        "candidate_id": candidate_id,
                        "examination_id": exam_id,
                        "type": "deadline_reminder",
                        "title": title,
                        "body": body,
                        "is_read": False,
                        "data": {"hours_left": hours_left, "closing_date": closing_str}
                    })
                    generated_count += 1
        except Exception as e:
            logger.error(f"Error during reminder generation: {e}")

        logger.info(f"Generated {generated_count} deadline reminder notifications.")
        return generated_count

reminder_generator = ReminderGenerator()

