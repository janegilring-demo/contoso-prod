variable "required_public_ip_tags" {
  type        = map(string)
  default     = {}
  description = "Policy-required IP tags for generated firewall, Bastion and gateway public IPs. Required values take precedence over per-IP tags."
  nullable    = false
}

variable "subnet_network_security_group_ids" {
  type        = map(map(string))
  default     = {}
  description = "Existing NSG IDs keyed by hub and generated subnet key (bastion or dns_resolver). NSG ownership stays external to this module."
  nullable    = false
}