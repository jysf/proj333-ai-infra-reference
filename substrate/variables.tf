variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster and associated resources."
  type        = string
  default     = "ai-infra-reference"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.35"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "cpu_instance_types" {
  description = "Instance types for the CPU managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "cpu_desired" {
  description = "Desired number of nodes in the CPU node group."
  type        = number
  default     = 2
}

variable "cpu_min" {
  description = "Minimum number of nodes in the CPU node group."
  type        = number
  default     = 1
}

variable "cpu_max" {
  description = "Maximum number of nodes in the CPU node group."
  type        = number
  default     = 3
}

variable "gpu" {
  description = "When true, provisions an additional GPU node group (g4dn) with nvidia.com/gpu:NoSchedule taint."
  type        = bool
  default     = false
}

variable "gpu_instance_types" {
  description = "Instance types for the GPU managed node group (used only when var.gpu = true)."
  type        = list(string)
  default     = ["g4dn.xlarge"]
}
