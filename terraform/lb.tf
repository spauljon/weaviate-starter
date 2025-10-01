# Target group (TCP) for Weaviate
resource "aws_lb_target_group" "weaviate_tg" {
  name        = "weaviate-tg"
  port        = var.weaviate_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = var.weaviate_port
  }
}

# Register the current instance in the TG
resource "aws_lb_target_group_attachment" "weaviate_tga" {
  target_group_arn = aws_lb_target_group.weaviate_tg.arn
  target_id        = var.weaviate_instance_id
  port             = var.weaviate_port
}

# Internal Network Load Balancer
resource "aws_lb" "weaviate_nlb" {
  name               = "weaviate-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = local.nlb_subnets

  enable_deletion_protection = false
}

# Listener on 8080 (or var.weaviate_port)
resource "aws_lb_listener" "weaviate_8080" {
  load_balancer_arn = aws_lb.weaviate_nlb.arn
  port              = var.weaviate_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weaviate_tg.arn
  }
}
