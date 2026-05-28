import json
import logging
import boto3
from boto3.dynamodb.conditions import Key, Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
activity_table = dynamodb.Table("SEENSubstationActivity")
substations_table = dynamodb.Table("Substations")


def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event))

    contact_attrs = event.get("Details", {}).get("ContactData", {}).get("Attributes", {})
    seen_id = contact_attrs.get("seenId", "").strip()

    if not seen_id:
        logger.warning("seenId missing from parameters")
        return {"isCheckedIn": "false", "reason": "missing_seenId"}

    response = activity_table.query(
        KeyConditionExpression=Key("seenId").eq(seen_id),
        FilterExpression=Attr("sessionState").eq("ACTIVE"),
        ScanIndexForward=False,
        Limit=1,
    )

    items = response.get("Items", [])
    if not items:
        logger.info("seenId=%s is not currently checked in", seen_id)
        return {"isCheckedIn": "false"}

    session = items[0]
    substation_id = session.get("substationId", "")

    substation_response = substations_table.get_item(Key={"substationId": substation_id})
    substation = substation_response.get("Item", {})
    substation_name = substation.get("name", "")

    logger.info("seenId=%s checked in at substationId=%s (%s)", seen_id, substation_id, substation_name)

    return {
        "isCheckedIn": "true",
        "substationId": substation_id,
        "substationName": substation_name,
        "checkInTime": str(session.get("checkInTime", "")),
    }
