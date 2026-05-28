# SEEN IVR POC — Amazon Connect Substation Check-In/Out System

A proof-of-concept IVR system built on **Amazon Connect** that allows utility field workers to check in and out of electrical substations via phone call. Field workers dial in, authenticate with their SEEN ID and substation ID, and the system records their activity in DynamoDB.

---

## How It Works

1. Field worker calls the provisioned DID number
2. IVR prompts for their **SEEN ID** (employee identifier)
3. IVR prompts for the **Substation ID** they are visiting
4. System validates both IDs against reference tables
5. Worker selects **Check In** or **Check Out**
6. Activity is recorded in DynamoDB with timestamp, ANI, and callback number
7. Active sessions can be queried by substation or worker

---

## Architecture

```
Phone Call
    │
    ▼
Amazon Connect (IVR)
    │
    ├── SEENValidateSeenId Lambda      ──► SEENPersonnel DynamoDB table
    ├── SEENValidateSubstation Lambda  ──► Substations DynamoDB table
    ├── SEENCheckInOutHandler Lambda   ──► SEENSubstationActivity DynamoDB table
    └── SEENGetStatus Lambda           ──► SEENSubstationActivity DynamoDB table
```

---

## Project Structure

```
seen-ivr-poc/
├── terraform/
│   ├── 1_instance.tf           # Amazon Connect instance
│   ├── 1a_phone_number.tf      # DID phone number provisioning
│   ├── 2_users.tf              # Connect users
│   ├── 3_hours_of_operation.tf # Hours of operation
│   ├── 4_queues.tf             # Connect queues
│   ├── 5_routing_profiles.tf   # Routing profiles
│   ├── 6_contact_flows.tf      # IVR contact flows
│   ├── 7_lambda.tf             # Lambda functions + IAM + Connect wiring
│   ├── 8_dynamodb.tf           # DynamoDB tables
│   ├── 9_dynamodb_seed.tf      # Seed data (SEEN IDs + substations)
│   ├── storage.tf              # Connect storage (S3 for recordings)
│   ├── kms.tf                  # KMS encryption key
│   ├── main.tf                 # Shared Connect resource config
│   ├── variables.tf            # Input variables
│   ├── output.tf               # Terraform outputs
│   ├── data.tf                 # Data sources
│   └── provider.tf             # AWS provider config
├── code/
│   ├── check_in_out_handler.py # Records check-in/out activity
│   ├── validate_substation.py  # Validates substation ID
│   ├── validate_seen_id.py     # Validates SEEN ID
│   ├── get_seen_status.py      # Retrieves current worker status
│   └── list_active_checkins.py # Lists active check-ins (CLI utility)
├── json/
│   └── contact_flows/          # Exported Amazon Connect flow JSON
│       ├── SEENInboundFlow.json
│       ├── SEENInboundFlow-Big.json
│       └── SEENRouteCall.json
└── README.md
```

---

## DynamoDB Tables

| Table | Purpose |
|---|---|
| `SEENSubstationActivity` | Check-in/out records (PII encrypted, TTL 24h, PITR enabled) |
| `SEENPersonnel` | SEEN ID reference table — who is authorized |
| `Substations` | Substation reference table — valid locations |

---

## Lambda Functions

| Function | Description |
|---|---|
| `SEENCheckInOutHandler` | Writes check-in or check-out record to activity table |
| `SEENValidateSubstation` | Looks up substation ID and returns name/status |
| `SEENValidateSeenId` | Looks up SEEN ID and returns name/status |
| `SEENGetStatus` | Returns current check-in status for a worker |
| `SEENListActiveCheckIns` | Lists all active check-ins (invoked via CLI, not Connect) |

---

## Prerequisites

- **AWS Account** with IAM permissions to create Connect, Lambda, DynamoDB, KMS, S3, and IAM resources
- **Terraform** ≥ 1.5.0
- **AWS CLI** configured (`aws configure`)
- Python 3.13 runtime (Lambda — managed by AWS, no local install needed)

---

## Deployment

### 1. Clone the repository

```bash
git clone https://github.com/sr0626/seen-ivr-poc.git
cd seen-ivr-poc/terraform
```

### 2. First apply — Connect instance only

Comment out the following files so Terraform creates the Connect instance and queues first (queue ARN is needed in contact flows):

```bash
# Comment all code in:
#   1a_phone_number.tf
#   6_contact_flows.tf
```

Then run:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Copy the queue ARN printed as `my_queue_arn` in the output.

### 3. Update contact flow JSON

Open `json/contact_flows/SEENInboundFlow.json` and replace all occurrences of `<<MY_QUEUE_ID>>` with the ARN copied above.

### 4. Full apply

Uncomment `1a_phone_number.tf` and `6_contact_flows.tf`, then:

```bash
terraform apply
```

Note the `did_number` output — this is the phone number callers dial.

---

## Seed Data

`9_dynamodb_seed.tf` seeds the reference tables with sample SEEN IDs and substations:

**SEEN IDs (Personnel)**

| SEEN ID | Name | Active |
|---|---|---|
| 1001 | Sateesh Rudrangi | yes |
| 1002 | Deepak Duvvuru | yes |
| 1003 | Jerry Oliver | yes |
| 20041 | Tim Tye | yes |
| 20052 | Eve Martinez | no |

**Substations**

| Substation ID | Name | Active |
|---|---|---|
| 1001 | North Grid Substation | yes |
| 1002 | South Grid Substation | yes |
| 2034 | East Distribution Hub | yes |
| 2035 | West Distribution Hub | no |
| 300456 | Central Relay Station | yes |

---

## Testing

1. Call the `did_number` from the Terraform output
2. Enter a valid SEEN ID when prompted (e.g. `1001`)
3. Enter a valid Substation ID when prompted (e.g. `1002`)
4. Select Check In or Check Out
5. Verify the record in DynamoDB table `SEENSubstationActivity`

To list active check-ins, invoke `SEENListActiveCheckIns` directly from the AWS Console or CLI.

---

## Security Notes

- ANI (caller phone number) and callback numbers are treated as PII — DynamoDB table uses server-side encryption
- KMS key is used for Lambda environment encryption
- Records auto-expire after 24 hours via DynamoDB TTL
- Point-in-time recovery is enabled on the activity table
