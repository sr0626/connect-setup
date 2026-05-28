import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Substations")


def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event))

    contact_attrs = event.get("Details", {}).get("ContactData", {}).get("Attributes", {})
    substation_id = contact_attrs.get("substationId", "").strip()

    if not substation_id:
        logger.warning("substationId missing from ContactData.Attributes")
        return {"isValid": "false", "isActive": "false", "reason": "missing substationId"}

    response = table.get_item(Key={"substationId": substation_id})
    item = response.get("Item")

    if not item:
        logger.warning("Substation not found: %s", substation_id)
        return {"isValid": "false", "isActive": "false", "reason": "not_found"}

    is_active = item.get("status", "no").lower() == "yes"
    logger.info("Substation %s found, active=%s", substation_id, is_active)

    return {
        "isValid": "true",
        "isActive": "yes" if is_active else "no",
        "substationName": item.get("name", ""),
    }
