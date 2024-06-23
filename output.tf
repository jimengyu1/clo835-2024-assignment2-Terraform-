output "public_ip" {
  description = "Public IP of EC2"
  value       = aws_instance.assignment2-ec2.public_ip
}