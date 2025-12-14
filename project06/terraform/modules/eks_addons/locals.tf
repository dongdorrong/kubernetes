locals {
  oidc_issuer_path  = replace(var.cluster_identity_oidc_issuer, "https://", "")
  hardeneks_enabled = var.enable_hardeneks_access
}
