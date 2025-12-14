variable "applications" {
  description = "Helm release definitions keyed by logical name"
  type = map(object({
    enabled          = bool
    release_name     = string
    namespace        = string
    create_namespace = optional(bool, false)
    source           = string # local or remote
    chart_path       = optional(string)
    repository       = optional(string)
    chart            = optional(string)
    chart_version    = optional(string)
    values_files     = optional(list(string), [])
    set_values       = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for app in values(var.applications) : contains(["local", "remote"], app.source)
    ])
    error_message = "Each application must specify source as either \"local\" or \"remote\"."
  }
}
