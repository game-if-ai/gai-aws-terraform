resource "aws_lb_target_group" "jupyter_api" {
  name        = "jupyter-api"
  port        = 8686
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    enabled = true
    path    = "/api/jupyter/lab"
  }

  depends_on = [aws_alb.jupyter_api]
}

resource "aws_alb" "jupyter_api" {
  name               = "jupyter-api-lb"
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
  certificate_arn   = aws_acm_certificate.jupyter_api.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jupyter_api.arn
  }
}

resource "aws_acm_certificate" "jupyter_api" {
  domain_name       = "jupyter-api.gameifai.org"
  validation_method = "DNS"
}

output "alb_url" {
  value = "http://${aws_alb.jupyter_api.dns_name}"
}