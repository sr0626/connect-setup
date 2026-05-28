import json
import logging
from decimal import Decimal
import boto3
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
activity_table = dynamodb.Table("SEENSubstationActivity")
substations_table = dynamodb.Table("Substations")


def decimal_to_str(obj):
    if isinstance(obj, Decimal):
        return str(obj)
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")


def lambda_handler(event, context):
    logger.info("Fetching all active check-ins")

    # Query SEENSessionStateIndex for all ACTIVE sessions, handling pagination
    active_sessions = []
    kwargs = {
        "IndexName": "SEENSessionStateIndex",
        "KeyConditionExpression": Key("sessionState").eq("ACTIVE"),
    }

    while True:
        response = activity_table.query(**kwargs)
        active_sessions.extend(response.get("Items", []))
        last_key = response.get("LastEvaluatedKey")
        if not last_key:
            break
        kwargs["ExclusiveStartKey"] = last_key

    logger.info("Found %d active check-in(s)", len(active_sessions))

    # Enrich each session with substation name
    substation_cache = {}
    results = []

    for session in active_sessions:
        substation_id = session.get("substationId", "")

        if substation_id not in substation_cache:
            sub_response = substations_table.get_item(Key={"substationId": substation_id})
            substation_cache[substation_id] = sub_response.get("Item", {}).get("name", "")

        results.append({
            "seenId": session.get("seenId", ""),
            "substationId": substation_id,
            "substationName": substation_cache[substation_id],
            "checkInTime": session.get("checkInTime", ""),
            "ani": session.get("ani", ""),
            "callbackNumber": session.get("callbackNumber", ""),
        })

    results.sort(key=lambda x: x["checkInTime"], reverse=True)

    logger.info("Active check-ins: %s", json.dumps(results, default=decimal_to_str))

    return {
        "count": len(results),
        "activeCheckIns": results,
    }
