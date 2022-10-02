data "aws_iam_policy_document" "control-plane-pol-document" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeVpcs",
      "elasticloadbalancing:*",
      "iam:CreateServiceLinkedRole",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "worker-pol-document" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "asg-assume-role-pol-document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "control-plane-policy" {
  name = "${var.name}-control-plane-policy"
  path = "/"

  policy = data.aws_iam_policy_document.control-plane-pol-document.json
}

resource "aws_iam_policy" "worker-policy" {
  name = "${var.name}-worker-policy"
  path = "/"

  policy = data.aws_iam_policy_document.worker-pol-document.json
}

resource "aws_iam_role" "control-plane-role" {
  name = "${var.name}-control-plane-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.asg-assume-role-pol-document.json

  managed_policy_arns = [
    aws_iam_policy.control-plane-policy.arn
  ]
}

resource "aws_iam_role" "worker-role" {
  name = "${var.name}-worker-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.asg-assume-role-pol-document.json

  managed_policy_arns = [
    aws_iam_policy.worker-policy.arn
  ]
}

resource "aws_iam_instance_profile" "control-plane-profile" {
  name = "${var.name}-control-plane-profile"
  role = aws_iam_role.control-plane-role.name
}

resource "aws_iam_instance_profile" "worker-profile" {
  name = "${var.name}-worker-profile"
  role = aws_iam_role.worker-role.name
}
