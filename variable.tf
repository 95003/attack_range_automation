variable "key_name" {
  description = "Name of the existing AWS key pair to use for EC2 instance"
  type        = string
}

variable "volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 50
}
