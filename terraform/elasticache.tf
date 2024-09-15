resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled = true
  replication_group_id       = "disposable-chat-redis-server"
  description                = "Disposable Chat - Redis"
  node_type                  = "cache.t2.small"
  port                       = 6379

  num_node_groups            = 2
  replicas_per_node_group    = 1

  transit_encryption_enabled = true
  transit_encryption_mode    = "preferred"

  subnet_group_name          = aws_elasticache_subnet_group.disposable_chat.name
  security_group_ids         = [aws_security_group.disposable_chat.id]
}
