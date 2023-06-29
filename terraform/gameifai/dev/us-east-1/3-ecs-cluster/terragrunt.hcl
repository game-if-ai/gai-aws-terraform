terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws//.?version=4.1.3"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  cluster_name = "ecs-gameifai-fargate-dev"
  default_capacity_provider_use_fargate = true

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/fargate"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}
