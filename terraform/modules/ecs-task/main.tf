data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "backend-task" {
  family                   = "gameifai"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"  
  
  container_definitions = <<TASK_DEFINITION
[
  {
    "name": "${var.container_name}",
    "image": "${var.task_name}:latest",
    "cpu": 1024,
    "memory": 2048,
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
          "awslogs-region" : "${var.region}",
          "awslogs-group" : "/aws/ecs/fargate",
          "awslogs-stream-prefix" : "db-migration"
      }
    },
    "portMappings": [ 
            { 
               "containerPort": 8686,
               "hostPort": 8686,
               "protocol": "tcp"
            }
         ],
    "mountPoints": [
            {
              "containerPath": "/app/dev/notebooks",
              "sourceVolume": "jupyter-notebooks-volume"
            }
        ],    
    "environment": [
      {
        "name": "SOME_ENV_VAR",
        "value": "or use `secrets` to pull from ssm"
      }
    ]
  }
]
TASK_DEFINITION
  # required for FARGATE
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  tags = var.tags
  volume {
    name = "jupyter-notebooks-volume"
    efs_volume_configuration {
      file_system_id = module.efs.id 
      root_directory = "./"
    }
  }
}

module "efs" {
  source = "terraform-aws-modules/efs/aws"
  name = "jupyter-notebooks-efs"
  security_group_vpc_id = "vpc-0b906b724eed4d2e5"
  access_points = {
    posix_example = {
      name = "posix-example"
      posix_user = {
        gid            = 1001
        uid            = 1001
        secondary_gids = [1002]
      }

      tags = {
        Additionl = "yes"
      }
    }
    root_example = {
      root_directory = {
        path = "/"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = ["10.0.1.128/25", "10.0.1.0/25", "10.0.2.128/25", "10.0.2.0/25"]
    }
  }
  mount_targets = {
    "us-east-1d" = {
      subnet_id = "subnet-00530f8a3081b0c80"
    }
    "us-east-1e" = {
      subnet_id = "subnet-04987c547d672f7b8"
    }
    
  }
}


# if group is missing, ecs will fail to start the task
resource "aws_cloudwatch_log_group" "fargate" {
  name              = "/aws/ecs/fargate"
  retention_in_days = 180
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "secrets_policy" {
  description = "Allow ECS task execution role to access SSM"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:parameter/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-secrets-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-backend-task-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_role_policy" {
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_cloudwatch_logs.html
  description = "Allow ECS tasks to send logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_policy.arn
}
