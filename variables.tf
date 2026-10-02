variable "name" {
  type        = string
  default     = "cint-code-test"
  description = "Root name for resources in this project"
}

variable "vpc_cidr" {
  default     = "10.1.0.0/16"
  type        = string
  description = "VPC cidr block"
}

variable "newbits" {
  default     = 8
  type        = number
  description = "How many bits to extend the VPC cidr block by for each subnet"
}

variable "public_subnet_count" {
  default     = 3
  type        = number
  description = "How many public subnets to create"
}

variable "private_subnet_count" {
  default     = 3
  type        = number
  description = "How many private subnets to create"
}

variable "asg_min_ec2_count" {
  default     = 2
  type        = number
  description = "Minimal number of ec2s to create"
}

variable "asg_max_ec2_count" {
  default     = 2
  type        = number
  description = "Maximal number of ec2s to create"
}

variable "domain_name" {
  type        = string
  default     = "example.com"
  description = "Domain name for DNS resolving"
}
