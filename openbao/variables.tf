variable "cluster" {
  description = "Cluster name, used in platform role names (`platform-<cluster>-<component>`)."
  type        = string
  default     = "alpha-01"
}

variable "kubernetes_host" {
  description = "Kubernetes API address as seen from the OpenBao pod (in-cluster). OpenBao reviews tokens with its own ServiceAccount, so no reviewer JWT is configured."
  type        = string
  default     = "https://kubernetes.default.svc"
}

variable "platform_components" {
  description = <<-EOT
    Platform components that read secrets from OpenBao: component name => ServiceAccount (name and
    namespace) allowed to authenticate. Names must match what platform-components renders.
  EOT
  type = map(object({
    service_account = string
    namespace       = string
  }))
  default = {
    "cert-manager" = {
      service_account = "secret-sync"
      namespace       = "cert-manager-system"
    }
    "external-dns" = {
      service_account = "external-dns"
      namespace       = "external-dns-system"
    }
  }
}

variable "label_prefix" {
  description = "Prefix of the platform's namespace labels (`<prefix>team`, `<prefix>env`)."
  type        = string
  default     = "homelab-selfuryon.github.io/"
}
