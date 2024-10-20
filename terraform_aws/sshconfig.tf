resource "local_file" "ssh_config" {
  depends_on = [
    aws_instance.kube-controller,
    aws_instance.kube-worker,
    aws_instance.bgp-receiver
  ]
  content = templatefile(
    "${path.module}/resources/ssh_config.tmpl",
    {
      controller   = aws_instance.kube-controller.public_ip
      worker       = aws_instance.kube-worker.public_ip
      bgp          = aws_instance.bgp-receiver.public_ip
      default_user = var.ami_default_user
    }
  )
  filename = pathexpand("~/.ssh/config.d/config.aws")
}
