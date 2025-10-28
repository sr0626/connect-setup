resource "aws_connect_routing_profile" "test" {
  description               = "My Routing Profile"
  name                      = "My Routing Profile"
  instance_id               = aws_connect_instance.test.id
  default_outbound_queue_id = data.aws_connect_queue.basic_queue.queue_id

  media_concurrencies {
    channel     = "VOICE"
    concurrency = 1
  }

  queue_configs {
    channel  = "VOICE"
    queue_id = aws_connect_queue.test.queue_id
    priority = 1
    delay    = 2
  }

  # queue_configs {
  #   channel = "CHAT"
  #   queue_id = data.aws_connect_queue.basic_queue.queue_id
  #   priority = 2
  #   delay    = 2
  # }
}
