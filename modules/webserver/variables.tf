variable "region" {
  type        = string
  description = "us-east-2"
}

variable "instance_type" {
  type        = string
  description = "t2.micro"
}

variable "ami" {
  type        = string
  description = "ami-03a0c45ebc70f98ea"
}

variable "server_name" {
  type        = string
  description = "web_server"
}

variable "zone" {
  type        = string
  description = "us-east-2a"
}
