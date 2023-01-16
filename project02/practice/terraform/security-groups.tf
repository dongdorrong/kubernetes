resource "aws_security_group" "node_group_one" {
  name_prefix = "node_group_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }

}

resource "aws_security_group" "node_group_two" {
  name_prefix = "node_group_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }

  ingress {
    from_port = 30000
    to_port   = 32767 
    protocol  = "tcp"

    security_groups = [ 
      data.aws_security_group.eks_alb_sg.id,
      data.aws_security_group.argocd_alb_sg.id
    ]
  }

}

data "aws_security_group" "eks_alb_sg" {
  filter {
    name   = "tag:ingress.k8s.aws/resource"
    values = [ "ManagedLBSecurityGroup" ]
  }
}

data "aws_security_group" "argocd_alb_sg" {
  filter {
    name   = "tag:Name"
    values = [ "k8s-elb-a234f2329747143a280912f4ea757e6a" ]
  }
}
