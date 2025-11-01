output "instance_public_ip_a" {
  value = aws_instance.web_a.public_ip
}

output "instance_public_ip_c" {
  value = aws_instance.web_c.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.main_db.endpoint
}

output "iam_user_name" {
  value = aws_iam_user.deploy_user.name
}