resource "aws_lb_target_group" "jupyter_api" {
  name        = "jupyter-api"
  port        = 8686
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    enabled = true
    path    = "/api/jupyter/lab"
    matcher = "200,302"
  }

  depends_on = [aws_alb.jupyter_api]
}

resource "aws_alb" "jupyter_api" {
  name               = "jupyter-api-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_d.id,
    aws_subnet.public_e.id,
  ]

  security_groups = [
    aws_security_group.http.id,
    aws_security_group.https.id,
    aws_security_group.egress_all.id,
  ]

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_alb_listener" "jupyter_api_http" {
  load_balancer_arn = aws_alb.jupyter_api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "jupyter_api_https" {
  load_balancer_arn = aws_alb.jupyter_api.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:621646083911:certificate/b88313b3-4978-4a30-8b6a-485f4f43df03"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jupyter_api.arn
  }
}

output "alb_url" {
  value = "http://${aws_alb.jupyter_api.dns_name}"
}

output "alb_arn" {
  value = aws_alb.jupyter_api.arn
}