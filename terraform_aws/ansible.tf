resource "local_file" "ansible_inventory" {
  content = templatefile(
    "${path.module}/resources/inventory.tmpl",
    {
      bgp          = aws_instance.bgp-receiver.public_ip
      controller   = aws_instance.kube-controller.public_ip
      default_user = var.ami_default_user
      enable_ssm   = var.enable_ssm
      region       = var.region
      workers      = aws_instance.kube-worker[*].public_ip
    }
  )
  filename = "../ansible/inventory/aws_ec2.yaml"
}

# aws_ssm_retry is our local shim over amazon.aws.aws_ssm (see ansible/playbooks/connection_plugins), which
# is needed for ansible_aws_ssm_retries to take effect at all. The default budget is ~4s, which doesn't
# survive the agent restarting itself, so we give it ~3 minutes. ssm_timeout is wall-clock per command, so
# the default 60s is too short for package installs.
resource "local_file" "ansible_group_vars" {
  count    = var.enable_ssm ? 1 : 0
  content  = <<-EOF
ansible_aws_ssm_bucket_name: ${aws_s3_bucket.ansible_ssm_bucket[0].bucket}
ansible_aws_ssm_document: ${aws_ssm_document.ssm_default_user[0].name}
ansible_aws_ssm_region: ${var.region}
ansible_aws_ssm_retries: 10
ansible_aws_ssm_timeout: 300
ansible_become_method: sudo
ansible_become_user: root
ansible_connection: aws_ssm_retry
ansible_python_interpreter: /usr/bin/python3
ansible_user: ssm-user
EOF
  filename = "../ansible/inventory/group_vars/aws_ec2"
}
