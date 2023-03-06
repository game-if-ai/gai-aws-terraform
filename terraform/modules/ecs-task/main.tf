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
         ]    
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
