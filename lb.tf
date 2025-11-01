resource "aws_lb" "main_lb" {
  name               = "main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_groups_lb.id]
  subnets            = [aws_subnet.subnet_public_a.id,aws_subnet.subnet_public_c.id]

}


resource "aws_lb_target_group" "main_tg" {
  name     = "main"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "web_a_attachment" {
  target_group_arn = aws_lb_target_group.main_tg.arn
  target_id        = aws_instance.web_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_c_attachment" {
  target_group_arn = aws_lb_target_group.main_tg.arn
  target_id        = aws_instance.web_c.id
  port             = 80
}

resource "aws_lb_listener" "main_listener" {
  load_balancer_arn = aws_lb.main_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_tg.arn
  }
}
