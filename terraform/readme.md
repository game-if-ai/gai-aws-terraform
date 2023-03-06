This repo demos how to setup a ecs cluster of type fargate and run a task from outside aws env (github actions, terminal...).

The [iam-user](./1-iam-user-github-actions/terragrunt.hcl) module creates a new user end exports credentials
(access key, secret key) to SSM so github actions can be configured to push docker images and run ecs tasks.

The [ecs-registry](./2-docker-registry/terragrunt.hcl) module creates a private docker registry at aws.

The [ecs-cluster](./3-ecs-cluster/terragrunt.hcl) module creates an ECS cluster of type fargate with logging configured to use cloudwatch.

Finally [ecs-task](./4-ecs-backend-task/terragrunt.hcl) module creates a task definition that will be used to run ecs tasks. It points to the docker registry image to be used (mentorpal-fargate-demo), and configures permissions. 

After all this is provisioned here's now to run a task (assuming github actions have iam user credentials):

```bash
## bundle the code into a docker image first:
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.us-east-1.amazonaws.com
docker build --platform linux/amd64 -t mentorpal-fargate-demo:latest .
docker tag mentorpal-fargate-demo:latest <account_id>.dkr.ecr.us-east-1.amazonaws.com/mentorpal-fargate-demo:latest
docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/mentorpal-fargate-demo:latest
#
## then run a Fargate task using the previously built image:
aws ecs run-task --cluster ecs-fargate --launch-type=FARGATE --count 1 --output text --region us-east-1 --color off \
    --network-configuration  'awsvpcConfiguration={subnets=[subnet-0eb3d5f8662f7bfe6,subnet-0c886204fed17aed1],securityGroups=[sg-08469b5e43ec16569]}' \
    --task-definition 'arn:aws:ecs:us-east-1:<account_id>:task-definition/mentorpal-fargate-demo:1'

## this returns json output so pull .tasks[0].taskArn and use describe to poll for results:
aws ecs describe-tasks   --cluster ecs-fargate --tasks  "arn:aws:ecs:us-east-1:<account_id>:task/ecs-fargate/2b0875aebd2c4d6398403ae939e7572b"
# 

```