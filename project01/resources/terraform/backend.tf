terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "dongdorrong-study"

    workspaces {
      name = "dongdorrong-project-01"
    }
  }
}
