################### ECS Instance Role ############################################################
data "aws_iam_policy" "ecs_instance_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
data "aws_iam_policy_document" "ecs_instance_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecs_instance_role-${var.env}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_role_policy.json
}
resource "aws_iam_role_policy_attachment" "ecsInstancePolicy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = data.aws_iam_policy.ecs_instance_role_policy.arn
}
resource "aws_iam_instance_profile" "ecs_instance_role_profile" {
  name = aws_iam_role.ecs_instance_role.name
  role = aws_iam_role.ecs_instance_role.name
}

################### ECS Service Role ############################################################

data "aws_iam_policy" "ecs_service_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecs_service_role" {
  name               = "ecs_service_role-${var.env}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_service_policy" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = data.aws_iam_policy.ecs_service_role_policy.arn
}

##############################################################################################

resource "aws_iam_role" "ecs_task_execution_role" {
  name = lower("${var.app_name}-ecs-task-execution-role")
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}