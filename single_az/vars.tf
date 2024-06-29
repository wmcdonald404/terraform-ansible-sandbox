variable "suffix" {
  type        = string
  description = "Suffix string to append to resources"
  default     = "multi"
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "all_azs" {
  type        = list(string)
  description = "All AWS Availability Zones"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "single_az" {
  type        = string
  description = "Primary AWS Availability Zone"
  default     = "eu-west-1a"
}

variable "multi_azs" {
  type        = list(string)
  description = "Multiple AWS Availability Zones"
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "debian_ami" {
  type        = string
  description = "Debian 12 (HVM), SSD Volume Type"
  default     = "ami-0eb11ab33f229b26c"
}

# See the Map entry here: https://upcloud.com/resources/tutorials/terraform-variables#Map
# for a nice map option to set small/medium/large options.
variable "base_instance_type" {
  type        = string
  description = "EC2 instance"
  default     = "t2.micro"
}
