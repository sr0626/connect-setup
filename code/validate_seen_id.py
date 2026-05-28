import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("SEENPersonnel")


def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event))

    contact_attrs = event.get("Details", {}).get("ContactData", {}).get("Attributes", {})
    seen_id = contact_attrs.get("seenId", "").strip()

    if not seen_id:
        logger.warning("seenId missing from ContactData.Attributes")
        return {"isValid": "false", "isActive": "false", "reason": "missing_seenId"}

    response = table.get_item(Key={"seenId": seen_id})
    item = response.get("Item")

    if not item:
        logger.warning("SEEN ID not found: %s", seen_id)
        return {"isValid": "false", "isActive": "false", "reason": "not_found"}

    is_active = item.get("status", "no").lower() == "yes"
    logger.info("SEEN ID %s found, active=%s", seen_id, is_active)

    return {
        "isValid": "true",
        "isActive": "yes" if is_active else "no",
        "name": item.get("name", ""),
    }
