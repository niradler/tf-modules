output "public_ip" {
  value = aws_instance.public.public_ip
}

output "private_ip" {
  value = aws_instance.private.public_ip
}

output "eip_public_ip" {
  value = aws_eip.public.public_ip
}
