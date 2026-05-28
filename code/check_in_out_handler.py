import json
import logging
import time
import boto3
from boto3.dynamodb.conditions import Key, Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("SEENSubstationActivity")

TTL_SECONDS = 24 * 60 * 60  # auto-expire records after 24 hours


def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event))

    # parameters = event.get("Details", {}).get("Parameters", {})
    # action_type = parameters.get("actionType", "").strip()  # "CheckIn" or "CheckOut"

    contact_data = event.get("Details", {}).get("ContactData", {})
    contact_attrs = contact_data.get("Attributes", {})

    substation_id = contact_attrs.get("substationId", "").strip()
    seen_id = contact_attrs.get("seenId", "").strip()
    callback_number = contact_attrs.get("callbackNumber", "").strip()
    action_type = contact_attrs.get("actionType", "").strip()  # "CheckIn" or "CheckOut"
    logger.info("substationId=%s seenId=%s callbackNumber=%s actionType=%s", substation_id, seen_id, callback_number, action_type)

    # ANI is provided by Connect automatically via CustomerEndpoint
    ani = contact_data.get("CustomerEndpoint", {}).get("Address", "")

    if not all([seen_id, action_type]):
        logger.warning("Missing required parameters: seenId=%s actionType=%s", seen_id, action_type)
        return {"success": "false", "reason": "missing_parameters"}

    now_ms = int(time.time() * 1000)

    if action_type == "CheckIn":
        if not substation_id:
            logger.warning("substationId required for CheckIn but not provided")
            return {"success": "false", "reason": "missing_substationId"}
        if not callback_number:
            logger.warning("callbackNumber required for CheckIn but not provided")
            return {"success": "false", "reason": "missing_callbackNumber"}
        return _handle_check_in(substation_id, seen_id, ani, callback_number, now_ms)
    elif action_type == "CheckOut":
        return _handle_check_out(seen_id, ani, now_ms)
    else:
        logger.warning("Unknown action_type: %s", action_type)
        return {"success": "false", "reason": "unknown_action_type"}


def _handle_check_in(substation_id, seen_id, ani, callback_number, now_ms):
    item = {
        "seenId": seen_id,
        "checkInTime": now_ms,
        "substationId": substation_id,
        "sessionState": "ACTIVE",
        "ttl": int(now_ms / 1000) + TTL_SECONDS,
    }

    item["callbackNumber"] = callback_number
    if ani:
        item["ani"] = ani

    logger.info("Writing item to DynamoDB: %s", json.dumps(item, default=str))

    try:
        response = table.put_item(Item=item)
        http_status = response.get("ResponseMetadata", {}).get("HTTPStatusCode")
        logger.info("Check-in recorded: seenId=%s substationId=%s checkInTime=%s httpStatus=%s", seen_id, substation_id, now_ms, http_status)
    except Exception as e:
        logger.error("Failed to write check-in: %s", str(e))
        return {"success": "false", "reason": "dynamodb_error"}

    result = {"success": "true", "action_type": "CheckIn", "checkInTime": str(now_ms)}
    logger.info("Check-in handler output: %s", json.dumps(result))
    return result


def _handle_check_out(seen_id, ani, now_ms):
    # Query by seenId (hash key) for the active session — substationId comes from the stored record
    response = table.query(
        KeyConditionExpression=Key("seenId").eq(seen_id),
        FilterExpression=Attr("sessionState").eq("ACTIVE"),
        ScanIndexForward=False,
        Limit=1,
    )

    items = response.get("Items", [])
    if not items:
        logger.warning("No active session found for seenId=%s", seen_id)
        return {"success": "false", "reason": "no_active_session"}

    session = items[0]
    check_in_time = session["checkInTime"]
    substation_id = session.get("substationId", "")

    update_expr = "SET sessionState = :done, checkOutTime = :now"
    expr_values = {":done": "COMPLETED", ":now": now_ms}
    if ani:
        update_expr += ", ani = :ani"
        expr_values[":ani"] = ani

    try:
        table.update_item(
            Key={"seenId": seen_id, "checkInTime": check_in_time},
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expr_values,
        )
        logger.info("Check-out recorded: seenId=%s substationId=%s checkOutTime=%s", seen_id, substation_id, now_ms)
    except Exception as e:
        logger.error("Failed to write check-out: %s", str(e))
        return {"success": "false", "reason": "dynamodb_error"}

    result = {"success": "true", "action_type": "CheckOut", "checkOutTime": str(now_ms), "substationId": substation_id}
    logger.info("Check-out handler output: %s", json.dumps(result))
    return result
