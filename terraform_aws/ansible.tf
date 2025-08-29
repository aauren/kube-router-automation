resource "local_file" "ansible_inventory" {
  content = templatefile(
    "${path.module}/resources/inventory.tmpl",
    {
      region                  = var.region
      ansible_ssm_bucket_name = var.enable_ssm ? aws_s3_bucket.ansible_ssm_bucket[0].bucket : ""
      enable_ssm              = var.enable_ssm
      controller              = aws_instance.kube-controller.public_ip
      worker                  = aws_instance.kube-worker.public_ip
      bgp                     = aws_instance.bgp-receiver.public_ip
      default_user            = var.ami_default_user
    }
  )
  filename = "../ansible/inventory/aws_ec2.yaml"
}

resource "local_file" "ansible_group_vars" {
  count    = var.enable_ssm ? 1 : 0
  content  = <<-EOF
ansible_connection: "community.aws.aws_ssm"
ansible_user: ssm-user
ansible_become: true
ansible_become_method: sudo
ansible_become_user: root
ansible_aws_ssm_bucket_name: ${aws_s3_bucket.ansible_ssm_bucket[0].bucket}
ansible_python_interpreter: /usr/bin/python3
EOF
  filename = "../ansible/inventory/group_vars/aws_ec2"
}
