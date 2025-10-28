# --- Look up built-in "Admin" Security Profile ---
data "aws_connect_security_profile" "admin" {
  depends_on  = [time_sleep.after_instance]
  instance_id = aws_connect_instance.test.id
  name        = "Admin"
}

data "aws_connect_security_profile" "agent" {
  depends_on  = [time_sleep.after_instance]
  instance_id = aws_connect_instance.test.id
  name        = "Agent"
}

# --- Look up built-in "Basic Routing Profile" ---
data "aws_connect_routing_profile" "basic" {
  depends_on  = [time_sleep.after_instance]
  instance_id = aws_connect_instance.test.id
  name        = "Basic Routing Profile"
}

# --- Look up built-in "BasicQueue" ---
data "aws_connect_queue" "basic_queue" {
  depends_on  = [time_sleep.after_instance]
  instance_id = aws_connect_instance.test.id
  name        = "BasicQueue"
}

# Get the built-in "Default outbound" contact flow
data "aws_connect_contact_flow" "default_outbound" {
  instance_id = aws_connect_instance.test.id
  name        = "Default outbound"
}

# data "aws_connect_queue" "outbound" {
#   instance_id = aws_connect_instance.test.id
#   name        = "BasicQueue" # <-- change to your outbound queue name
# }


data "aws_kms_alias" "test" {
  name        = "alias/test-key"
}

