locals {
  seen_ids = {
    "1001"  = { name = "Sateesh Rudrangi", status = "yes" },
    "1002"  = { name = "Deepak Duvvuru",   status = "yes" },
    "1003"  = { name = "Jerry Oliver",     status = "yes" },
    "20041" = { name = "Tim Tye",          status = "yes"  },
    "20052" = { name = "Eve Martinez",     status = "no" },
  }

  substations = {
    "1001"   = { name = "North Grid Substation",  status = "yes" },
    "1002"   = { name = "South Grid Substation",  status = "yes" },
    "2034"   = { name = "East Distribution Hub",  status = "yes" },
    "2035"   = { name = "West Distribution Hub",  status = "no"  },
    "300456" = { name = "Central Relay Station",  status = "yes" },
  }
}

resource "aws_dynamodb_table_item" "seen_id_seed" {
  for_each   = local.seen_ids
  table_name = aws_dynamodb_table.seen_ids_table.name
  hash_key   = aws_dynamodb_table.seen_ids_table.hash_key

  item = jsonencode({
    seenId        = { S = each.key }
    status        = { S = each.value.status }
    name          = { S = each.value.name }
    createdOn     = { S = "2026-05-28T00:00:00Z" }
    lastUpdatedOn = { S = "2026-05-28T00:00:00Z" }
  })
}

resource "aws_dynamodb_table_item" "substation_seed" {
  for_each   = local.substations
  table_name = aws_dynamodb_table.substations_table.name
  hash_key   = aws_dynamodb_table.substations_table.hash_key

  item = jsonencode({
    substationId  = { S = each.key }
    status        = { S = each.value.status }
    name          = { S = each.value.name }
    createdOn     = { S = "2026-05-28T00:00:00Z" }
    lastUpdatedOn = { S = "2026-05-28T00:00:00Z" }
  })
}
