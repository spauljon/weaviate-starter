resource "aws_lb_target_group" "weaviate_tg" {
  name        = "weaviate-tg"
  port        = var.weaviate_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    protocol = "TCP"
    port     = var.weaviate_port
  }
}

resource "aws_lb_target_group_attachment" "weaviate_tga" {
  target_group_arn = aws_lb_target_group.weaviate_tg.arn
  target_id        = aws_instance.weaviate.id
  port             = var.weaviate_port
}

resource "aws_lb" "weaviate_nlb" {
  name               = "weaviate-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = local.nlb_subnets

  enable_deletion_protection = false
}

resource "aws_lb_listener" "weaviate_port" {
  load_balancer_arn = aws_lb.weaviate_nlb.arn
  port              = var.weaviate_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weaviate_tg.arn
  }
}
