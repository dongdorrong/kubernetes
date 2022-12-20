resource "aws_ebs_volume" "grafana_prometheus_volumes_1" {
  availability_zone = "ap-northeast-2"
  size              = 100
}

resource "aws_ebs_volume" "grafana_prometheus_volumes_2" {
  availability_zone = "ap-northeast-2"
  size              = 100
}

resource "aws_ebs_volume" "grafana_prometheus_volumes_3" {
  availability_zone = "ap-northeast-2"
  size              = 100
}