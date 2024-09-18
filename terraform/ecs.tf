data "aws_ecr_image" "server" {
  repository_name = "disposable-chat-server"
  most_recent       = true
}

resource "aws_ecs_cluster" "cluster" {
  name = "disposable-chat-server"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "disposable-chat-server"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_role.arn
  container_definitions    = jsonencode([
    {
      name      = "disposable-chat-server"
      image     = data.aws_ecr_image.server.image_uri
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ],
      environment: [
        {
          "name": "SERVER_PORT",
          "value": "80"
        },
        {
          "name": "ACCEPTED_ORIGIN",
          "value": "https://chat.lucasmauro.com"
        },
        {
          "name": "REDIS_ENDPOINT",
          "value": "${aws_elasticache_replication_group.redis.configuration_endpoint_address}:6379"
        },
        {
          "name": "DEVELOPMENT",
          "value": "true"
        }
      ],
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "/ecs/disposable-chat-server",
              "awslogs-region": "us-east-1"
              "awslogs-stream-prefix": "disposable-chat"
          }
      },
    }
  ])
}

# TODO: Remove DEVELOPMENT
# TODO: Remove logConfiguration

resource "aws_ecs_service" "service" {
  name                 = "disposable-chat-server"
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = aws_ecs_task_definition.task.arn
  desired_count        = 1
  force_new_deployment = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 1
  }
  
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.disposable_chat.id]
    subnets          = [aws_subnet.us_east_1a.id, aws_subnet.us_east_1b.id, aws_subnet.us_east_1c.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}
