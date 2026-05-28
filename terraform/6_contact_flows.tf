resource "aws_connect_contact_flow" "test" {
  instance_id  = aws_connect_instance.test.id
  name         = "SEENInboundFlow"
  description  = "SEEN Inbound Contact Flow"
  type         = "CONTACT_FLOW"
  content      = file("${path.module}/../json/contact_flows/SEENInboundFlow.json")
  content_hash = filebase64sha256("${path.module}/../json/contact_flows/SEENInboundFlow.json")

  lifecycle {
    ignore_changes  = [content, content_hash]
    prevent_destroy = true
  }
}

resource "aws_connect_contact_flow" "test2" {
  instance_id  = aws_connect_instance.test.id
  name         = "SEEN Inbound Flow Big"
  description  = "SEEN Inbound Contact Flow Big"
  type         = "CONTACT_FLOW"
  content      = file("${path.module}/../json/contact_flows/SEENInboundFlow-Big.json")
  content_hash = filebase64sha256("${path.module}/../json/contact_flows/SEENInboundFlow-Big.json")
}

resource "aws_connect_contact_flow_module" "route_call" {
  instance_id  = aws_connect_instance.test.id
  name         = "SEENRouteCall"
  description  = "SEEN Route Call Contact Flow Module"
  content      = file("${path.module}/../json/contact_flows/SEENRouteCall.json")
  content_hash = filebase64sha256("${path.module}/../json/contact_flows/SEENRouteCall.json")
}
