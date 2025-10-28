# #--- Admin User (CONNECT_MANAGED directory) ---
resource "aws_connect_user" "admin" {
  #depends_on  = [data.aws_connect_security_profile.admin, data.aws_connect_routing_profile.basic]

  instance_id = aws_connect_instance.test.id
  # Login credentials (CONNECT_MANAGED only)
  name                 = "my_admin"
  password             = "Password1234"
  routing_profile_id   = aws_connect_routing_profile.test.routing_profile_id
  security_profile_ids = [data.aws_connect_security_profile.admin.arn]

  identity_info {
    first_name = "AdminF"
    last_name  = "AdminL"
    email      = "Admin@Admin.com"
  }

  phone_config {
    phone_type                    = "SOFT_PHONE"
    after_contact_work_time_limit = 0
    auto_accept                   = true
    # desk_phone_number             = null
  }
}

resource "aws_connect_user" "agent" {
  instance_id          = aws_connect_instance.test.id
  name                 = "my_agent"
  password             = "Password1234"
  routing_profile_id   = aws_connect_routing_profile.test.routing_profile_id #data.aws_connect_routing_profile.basic.id
  security_profile_ids = [data.aws_connect_security_profile.agent.arn]

  identity_info {
    first_name = "example"
    last_name  = "agent"
  }

  phone_config {
    after_contact_work_time_limit = 0
    phone_type                    = "SOFT_PHONE"
  }
}

# Discover IDs via CLI and create the user only if missing
# data "external" "admin_user" {
#   program = [
#     "/bin/bash", "-lc", <<-EOP
#     set -euo pipefail
#     IID="${aws_connect_instance.test.id}"
#     USERNAME="admin"
#     EMAIL="admin@admin.com"
#     FNAME="adminf"
#     LNAME="adminl"
#     PASS="Password1234"

#     ADMIN_SP_ID=$(aws connect list-security-profiles --instance-id "$IID" --query "SecurityProfileSummaryList[?Name=='Admin'].Id | [0]" --output text)
#     BASIC_RP_ID=$(aws connect list-routing-profiles   --instance-id "$IID" --query "RoutingProfileSummaryList[?Name=='${data.aws_connect_routing_profile.basic.name}'].Id | [0]" --output text)

#     EXIST_ID=$(aws connect list-users --instance-id "$IID" --query "UserSummaryList[?Username=='$USERNAME'].Id | [0]" --output text || true)
#     if [ "$EXIST_ID" = "None" ] || [ -z "$EXIST_ID" ]; then
#       RESP=$(aws connect create-user \
#         --instance-id "$IID" \
#         --username "$USERNAME" \
#         --password "$PASS" \
#         --identity-info "FirstName=$FNAME,LastName=$LNAME,Email=$EMAIL" \
#         --phone-config "PhoneType=SOFT_PHONE,AutoAccept=false,AfterContactWorkTimeLimit=0" \
#         --routing-profile-id "$BASIC_RP_ID" \
#         --security-profile-ids "$ADMIN_SP_ID")
#       echo "$RESP" | jq -r '{user_id: .UserId}'
#     else
#       echo "{\"user_id\":\"$EXIST_ID\"}"
#     fi
#   EOP
#   ]
# }
