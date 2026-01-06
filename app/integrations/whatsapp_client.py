import logging
import re
from typing import List

import requests

from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)


def send_whatsapp_message(to_number: str, message: str):
    target = (to_number or "").strip()
    if not settings.whatsapp_api_url or not target:
        logger.error("WhatsApp config missing or target empty, skipping send")
        return

    def _normalize_target(value: str) -> str:
        # keep group IDs like "....@g.us" as-is
        if "@" in value:
            return value.strip()
        digits = re.sub(r"\D", "", value)
        if not digits:
            logger.error("WhatsApp target invalid (no digits): %s", value)
            return ""
        if not digits.startswith("91"):
            digits = f"91{digits}"
        return digits

    normalized_target = _normalize_target(target)

    payload = {
        "accountId": settings.whatsapp_account_id,
        "target": normalized_target,
        "message": message,
    }

    try:
        response = requests.post(
            settings.whatsapp_api_url,
            json=payload,
            timeout=10,
        )
        status = response.status_code
        body = None
        try:
            body = response.text
        except Exception:
            body = ""

        if response.ok:
            msg = (
                f"WhatsApp send success -> target={normalized_target} "
                f"status={status}"
            )
            logger.info(msg)
            print(msg)
        else:
            msg = (
                f"WhatsApp send failed -> target={normalized_target} "
                f"status={status} body={body}"
            )
            logger.error(msg)
            print(msg)
            response.raise_for_status()
    except Exception as exc:
        msg = f"Failed to send WhatsApp message to {normalized_target}: {exc}"
        logger.exception(msg)
        print(msg)


def send_bulk(numbers: List[str], message: str):
    for number in numbers:
        send_whatsapp_message(number, message)
