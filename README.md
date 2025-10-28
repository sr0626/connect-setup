# ☁️ Amazon Connect Infrastructure Setup

This repository contains Infrastructure-as-Code (IaC) for deploying and managing an **Amazon Connect** instance and its related AWS resources using **Terraform**.

---

## 📁 Project Structure

connect-setup/
├── terraform/ # All Terraform IaC code
│ ├── 1_instance.tf # Instance configuration
│ ├── 1a_phone_number.tf # Phone number provisioning
│ ├── 2_users.tf # Users setup
│ ├── 3_hours_of_operation.tf # Hours of Operation setup
│ ├── 4_queues.tf # Queues setup
│ ├── 5_routing_profiles.tf # Routing profiles setup
│ ├── 6_contact_flows.tf # Contact flows setup
│ ├── storage.tf # Connect storage setup
│ ├── main.tf # Main configuration for Connect resources
│ ├── variables.tf # Input variables
│ ├── output.tf # Terraform outputs
│ ├── data.tf # Terraform data load
│ ├── kms.tf # Terraform kms
│ ├── provider.tf # Terraform provider setup
├── json/ # Contact flows (exported as json), prompts, etc.
│ ├── contact_flows/
│ ├── prompts/
│ 
└── README.md



---

## 🚀 Prerequisites

- **AWS Account** with required IAM permissions
- **Terraform** ≥ 1.5.0
- **AWS CLI** configured locally (`aws configure`)
- Optional: **VS Code** with Terraform extension

---

## ⚙️ Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://gitlab.com/sr0626/connect-setup.git
   cd connect-setup/terraform

2. **Comment some code**
    1. Comment all the code in 1a_phone_number.tf file
    2. Comment all the code in 6_contact_flows.tf file

3. **Run terraform commands from the terminal**
    1. terraform init
    2. terraform validate
    3. terraform plan
    4. terraform apply
    5. Make a copy of the queue arn (printed in the terminal as my_queue_arn) 

4. **Update code**
    1. Uncomment all the code in 1a_phone_number.tf file
    2. Unomment all the code in 6_contact_flows.tf file
    3. Open MyInboundFlow.json (under json/contact_flows folder)
    4. Replace <<MY_QUEUE_ID>> with the arn copied above  
    5. Rerun terraform apply command

2. **Validation**
  1. Call the phone number provisioned  (output prited as did_number)
  2. Confirm the call is answered
  3. Select the options provided
  4. Wait for the call to be queued for an agent
  5. Login to Agent Workspace or CCP (as an agent or admin)
  6. Change the status to Available
  7. Call is auto-accepted
  8. Hangup the call
  8. Close contact
  9. Check your s3 bucket for call recordings
  10. Check CW logs group for the call trace
