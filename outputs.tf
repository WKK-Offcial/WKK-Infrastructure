output "instance_ip_addr" {
  value = aws_instance.boi_bot.public_ip
}

output "aws_private_key" {
  value = tls_private_key.ec2_ssh_key.private_key_pem
}
