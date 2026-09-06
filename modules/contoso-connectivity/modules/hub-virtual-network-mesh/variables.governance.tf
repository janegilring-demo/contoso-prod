variable "required_public_ip_tags" {
  type        = map(string)
  default     = {}
  description = "Policy-required IP tags passed to generated firewall public IPs."
  nullable    = false
}