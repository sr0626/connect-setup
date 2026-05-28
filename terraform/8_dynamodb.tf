resource "aws_dynamodb_table" "seen_dynamodb_table" {
  name         = "SEENSubstationActivity"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "seenId"
  range_key = "checkInTime"

  attribute {
    name = "seenId"
    type = "S"
  }

  attribute {
    name = "checkInTime"
    type = "N" # epoch ms — enables reliable time-range queries and sorting
  }

  attribute {
    name = "substationId"
    type = "S"
  }

  attribute {
    name = "checkOutTime"
    type = "N" # epoch ms; absent on active (checked-in) sessions
  }

  attribute {
    name = "callbackNumber"
    type = "S"
  }

  attribute {
    name = "ani"
    type = "S"
  }

  attribute {
    name = "sessionState"
    type = "S" # ACTIVE | COMPLETED
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true # ANI and callback numbers are PII
  }

  # All check-ins at a substation, sorted by check-in time
  global_secondary_index {
    name            = "SEENSubstationIndex"
    hash_key        = "substationId"
    range_key       = "checkInTime"
    projection_type = "ALL"
  }

  # Completed sessions per substation, sorted by check-out time
  # Sparse index — only items with checkOutTime appear here
  global_secondary_index {
    name            = "SEENCheckoutIndex"
    hash_key        = "substationId"
    range_key       = "checkOutTime"
    projection_type = "ALL"
  }

  # Active vs completed sessions, sorted by check-in time
  # Query ACTIVE sessions across all substations, or filter by substationId
  global_secondary_index {
    name            = "SEENSessionStateIndex"
    hash_key        = "sessionState"
    range_key       = "checkInTime"
    projection_type = "ALL"
  }

  # Lookup by ANI (caller's phone number)
  global_secondary_index {
    name            = "SEENAniIndex"
    hash_key        = "ani"
    range_key       = "checkInTime"
    projection_type = "ALL"
  }

  # Lookup by callback number
  global_secondary_index {
    name            = "SEENCallbackIndex"
    hash_key        = "callbackNumber"
    range_key       = "checkInTime"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "seen_ids_table" {
  name         = "SEENPersonnel"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "seenId"

  attribute {
    name = "seenId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "lastUpdatedOn"
    type = "S"
  }

  # Fields stored as item attributes (no index): name, createdOn

  # Query SEEN IDs by status (active/inactive), sorted by last updated
  global_secondary_index {
    name            = "SeenIdStatusIndex"
    hash_key        = "status"
    range_key       = "lastUpdatedOn"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "substations_table" {
  name         = "Substations"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "substationId"

  attribute {
    name = "substationId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "lastUpdatedOn"
    type = "S"
  }

  # Fields stored as item attributes (no index): description, createdOn

  # Query substations by status (e.g. active/inactive), sorted by last updated
  global_secondary_index {
    name            = "SubstationStatusIndex"
    hash_key        = "status"
    range_key       = "lastUpdatedOn"
    projection_type = "ALL"
  }
}