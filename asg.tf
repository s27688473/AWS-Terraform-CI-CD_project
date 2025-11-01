resource "aws_autoscaling_policy" "target_cpu" {
  name                   = "cpu"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"
  # 配置目標追蹤
  target_tracking_configuration {
    # 目標 CPU 使用率 (百分比)
    target_value = 80.0
    
    # 使用 AWS 預定義的指標 (例如平均 CPU 利用率)
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

resource "aws_autoscaling_group" "main" {
  name             = "main"
  max_size         = 10                  # 最大實例數
  min_size         = 0                  # 最小實例數
  desired_capacity = 0                   # 初始期望實例數
  vpc_zone_identifier = [
    aws_subnet.subnet_private_a.id,  # AZ-a
    aws_subnet.subnet_private_c.id   # AZ-c
  ]
  
  # 啟用健康檢查 (Health Check)
  health_check_type          = "ELB"
  health_check_grace_period  = 300 
  
  # 連結到您的目標群組 (Target Group) - 假設您有一個名為 main_tg 的目標群組
  target_group_arns = [aws_lb_target_group.main_tg.arn]

# 引用單一 Launch Template
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  
  # 標籤 (包含動態 Name 標籤)
  tag {
    key                 = "Name"
    value               = "App-Web-Instance"
    propagate_at_launch = true
  }
}