resource "aws_launch_template" "main" {
  name_prefix     = "web-asg-"
  image_id        = var.ami_id
  instance_type   = var.instance_type
  key_name        = "main"
  iam_instance_profile {
    name = "main" 
}
  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    app_name      = "web-a" 
    db_host       = aws_db_instance.main_db.address
    db_user       = local.rds_credentials.username
    db_password   = local.rds_credentials.password
    db_database   = aws_db_instance.main_db.db_name
  }))
  # 修正 3: 使用 tag_specifications 將標籤傳播給 EC2 實例
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-asg"
    }
  }
  # (可選) 這是 Launch Template 資源本身的標籤，通常用於管理 IaC
  tags = {
    TemplatePurpose = "main"
  }
}
