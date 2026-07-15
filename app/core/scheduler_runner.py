import signal
import threading
import time

from app.core.logging_config import configure_logging
from app.core.scheduler import start_scheduler


def main() -> None:
    configure_logging()
    stop_event = threading.Event()

    def _handle_signal(signum, _frame) -> None:
        stop_event.set()

    signal.signal(signal.SIGTERM, _handle_signal)
    signal.signal(signal.SIGINT, _handle_signal)

    scheduler = start_scheduler()
    try:
        while not stop_event.wait(5):
            if scheduler is not None and not scheduler.running:
                raise RuntimeError("Scheduler stopped unexpectedly")
    finally:
        if scheduler is not None and scheduler.running:
            scheduler.shutdown(wait=False)


if __name__ == "__main__":
    main()
