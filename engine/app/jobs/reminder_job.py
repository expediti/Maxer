import logging
from engine.app.notifications.reminder_generator import reminder_generator

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("rexam.jobs.reminder")

def run_reminder_job():
    logger.info("Starting scheduled deadline reminder check...")
    count = reminder_generator.check_and_generate_reminders()
    logger.info(f"Scheduled reminder check completed. {count} candidate reminders processed.")

if __name__ == "__main__":
    run_reminder_job()

