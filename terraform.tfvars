## Application configurations
account      = 231662101549
region       = "ap-southeast-1"
app_name     = "aws-assignment"
env          = "dev"
app_services = ["eureka-server", "service-provider", "service-consumer", "config-server"]

#VPC configurations
cidr               = "10.10.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
public_subnets     = ["10.10.50.0/24", "10.10.51.0/24"]
private_subnets    = ["10.10.0.0/24", "10.10.1.0/24"]

#Internal ALB configurations
internal_alb_config = {
  name      = "Internal-Alb"
  listeners = {
    "HTTP" = {
      listener_port     = 8888
      listener_protocol = "HTTP"

    },
    "HTTP" = {
      listener_port     = 2222
      listener_protocol = "HTTP"

    },
    "HTTP" = {
      listener_port     = 8761
      listener_protocol = "HTTP"

    }      
  }

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 8888
      protocol    = "tcp"
      cidr_blocks = ["10.10.0.0/16"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["10.10.0.0/16"]
    }
  ]
}

#Friendly url name for internal load balancer DNS
internal_url_name = "service.internal"

#Public ALB configurations
public_alb_config = {
  name      = "Public-Alb"
  listeners = {
    "HTTP" = {
      listener_port     = 8761
      listener_protocol = "HTTP"

    },
    "HTTP" = {
      listener_port     = 8080
      listener_protocol = "HTTP"

    }    
  }

  ingress_rules = [
    {
      from_port   = 8080
      to_port     = 8761
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

#Microservices
microservice_config = {
  "ConfigServer" = {
    name             = "config-server"
    is_public        = false
    container_port   = 8888
    host_port        = 8888
    cpu              = 256
    memory           = 512
    desired_count    = 2
    alb_target_group = {
      port              = 8888
      protocol          = "HTTP"
      path_pattern      = ["/*"]
      health_check_path = "/health"
      priority          = 1
    }
    auto_scaling = {
      max_capacity = 2
      min_capacity = 2
      cpu          = {
        target_value = 75
      }
      memory = {
        target_value = 75
      }
    }
  },
  "EurekaServer" = {
    name             = "eureka-server"
    is_public        = false
    container_port   = 8761
    host_port        = 8761
    cpu              = 256
    memory           = 512
    desired_count    = 2
    alb_target_group = {
      port              = 8761
      protocol          = "HTTP"
      path_pattern      = ["/*"]
      health_check_path = "/health"
      priority          = 1
    }
    auto_scaling = {
      max_capacity = 2
      min_capacity = 2
      cpu          = {
        target_value = 75
      }
      memory = {
        target_value = 75
      }
    }
  },
  "ServiceCustomer" = {
    name             = "service-consumer"
    is_public        = true
    container_port   = 8080
    host_port        = 8080
    cpu              = 256
    memory           = 512
    desired_count    = 2
    alb_target_group = {
      port              = 8080
      protocol          = "HTTP"
      path_pattern      = ["/*"]
      health_check_path = "/health"
      priority          = 1
    }
    auto_scaling = {
      max_capacity = 2
      min_capacity = 2
      cpu          = {
        target_value = 75
      }
      memory = {
        target_value = 75
      }
    }
  },
  "ServiceProvider" = {
    name             = "service-provider"
    is_public        = false
    container_port   = 2222
    host_port        = 2222
    cpu              = 256
    memory           = 512
    desired_count    = 2
    alb_target_group = {
      port              = 2222
      protocol          = "HTTP"
      path_pattern      = ["/hello*"]
      health_check_path = "/health"
      priority          = 1
    }
    auto_scaling = {
      max_capacity = 2
      min_capacity = 2
      cpu          = {
        target_value = 75
      }
      memory = {
        target_value = 75
      }
    }
  }
}
