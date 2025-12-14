locals {
  subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)
}
