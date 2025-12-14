variable "domain_name" {
  description = "Primary domain to match when fetching ACM certificate"
  type        = string
}

variable "statuses" {
  description = "Certificate statuses to allow"
  type        = list(string)
  default     = ["ISSUED"]
}

variable "most_recent" {
  description = "Whether to return the most recent matching certificate"
  type        = bool
  default     = true
}
