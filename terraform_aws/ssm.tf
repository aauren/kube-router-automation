locals {
  ssm_transport_ssh    = var.enable_ssm && var.ansible_ssm_transport == "ssh"
  ssm_transport_plugin = var.enable_ssm && var.ansible_ssm_transport == "plugin"
  # Trimmed so cloud-init gets a single-line key entry
  ansible_ssm_ssh_public_key = local.ssm_transport_ssh ? trimspace(tls_private_key.ansible_ssm_ssh[0].public_key_openssh) : ""
}

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

# In ssh transport mode Ansible rides an SSH session tunneled through the SSM agent, so the instances need a key
# for ssm-user. We generate one here rather than depending on aws_key_name so that SSM mode stays zero-config.
resource "tls_private_key" "ansible_ssm_ssh" {
  count     = local.ssm_transport_ssh ? 1 : 0
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ansible_ssm_ssh_key" {
  count           = local.ssm_transport_ssh ? 1 : 0
  content         = tls_private_key.ansible_ssm_ssh[0].private_key_openssh
  filename        = "${path.module}/../ansible/inventory/aws_ssm_ssh_key"
  file_permission = "0600"
}

resource "random_string" "ansible_ssm_bucket_suffix" {
  count   = local.ssm_transport_plugin ? 1 : 0
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
  count  = local.ssm_transport_plugin ? 1 : 0
  bucket = "${var.ansible_ssm_bucket_name}-${random_string.ansible_ssm_bucket_suffix[0].result}"

  force_destroy = true
}

# SSM document to set the default user for Ansible sessions
resource "aws_ssm_document" "ssm_default_user" {
  count           = local.ssm_transport_plugin ? 1 : 0
  name            = "ConnectAsDefaultUser"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to configure the default Ansible user for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      runAsEnabled     = true
      runAsDefaultUser = "ssm-user"
    }
  })

  tags = merge(
    { "Name" = "ssm-default-user" },
    var.tags
  )
}
