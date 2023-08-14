variable "region" {
  description = "The AWS region to deploy to."
  type        = string
  default     = "us-west-2"
}

provider "aws" {
  region = var.region
}

variable "vpc_id" {
  description = "ID of the VPC where the Redis ElastiCache will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the Redis ElastiCache will be deployed."
  type        = list(string)
}

variable "environment" {
  description = "The environment name."
  type        = string
}

variable "app_name" {
  description = "The application name."
  type        = string
}

variable "resource_name" {
  description = "The name of the resource."
  type        = string
}

locals {
  env_id = substr(var.environment, 0, min(15, length(var.environment)))
  app_id = substr(var.app_name, 0, min(15, length(var.app_name)))
  res_id = substr(split(".", var.resource_name)[3], 0, min(15, length(var.resource_name)))
  cluster_id = replace(lower("${locals.env_id}-${locals.app_id}-${locals.res_id}"), "_", "-")
}

resource "aws_security_group" "redis_security_group" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = local.cluster_id
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_security_group.id]
}

output "host" {
  value = aws_elasticache_cluster.redis_cluster.cache_nodes.0.address
}

output "port" {
  value = aws_elasticache_cluster.redis_cluster.cache_nodes.0.port
}
