variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy the Eks cluster"
}

variable "environment" {
    description = "Environment name (dev, staging, prod)"
    type    = string
    default = "dev"
}

variable "cluster_name" {
    description = "name of the EKS cluster"
    type    = string
    default = "jerney-eks"
}


variable "cluster_version" {
    description = "Kubernetes version for EKS"
    type    = string
    default = "1.32"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type    = string
    default = "10.0.0.0/16"
}

