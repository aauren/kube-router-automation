resource "aws_iam_role_policy_attachment" "ssm-control-plane-policy-attachment" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.control-plane-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm-worker-policy-attachment" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.worker-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "random_string" "ansible_ssm_bucket_suffix" {
  count   = var.enable_ssm ? 1 : 0
  length  = 6
  special = false
  upper   = false

  keepers = {
    bucket_name = var.ansible_ssm_bucket_name
  }
}

# S3 bucket required for the Ansible aws_ssm connection plugin to work: 
# https://docs.ansible.com/ansible/latest/collections/community/aws/aws_ssm_connection.html#requirements
resource "aws_s3_bucket" "ansible_ssm_bucket" {
  count  = var.enable_ssm ? 1 : 0
  bucket = "${var.ansible_ssm_bucket_name}-${random_string.ansible_ssm_bucket_suffix[0].result}"

  force_destroy = true
}
