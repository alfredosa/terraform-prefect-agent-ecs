variable "s3_bucket" {
  description = "S3 bucket name for perfect TF"
  default = "perfect-staging-data-lake"
  type = string
}

variable "ecs_cluster_name" {
  default = "perfect"
}

variable "key_name" {
  default = "perfect.key"
}
variable "secret_key" {
    description = "super access key"
    type = string

}
variable "access_key" {
    description = "super secret key"
    type = string
}

# core
variable "region" {
    description = "The AWS region to create resources in."
    default = "eu-west-2"
}

### ECR Repository
variable "perfect-staging-ecr" {
  description = "ECR Repository name"
  default = "perfect-staging-ecr"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-2b", "eu-west-2c"]
}
variable "agent_cpu" {
  description = "CPU units to allocate to the agent"
  default     = 1024
  type        = number
}

variable "agent_desired_count" {
  description = "Number of agents to run"
  default     = 1
  type        = number
}

variable "agent_extra_pip_packages" {
  description = "Packages to install on the agent assuming image is based on prefecthq/prefect"
  default     = "prefect-aws s3fs"
  type        = string
}

variable "agent_image" {
  description = "Container image for the agent. This could be the name of an image in a public repo or an ECR ARN"
  default     = "prefecthq/prefect:2-python3.10"
  type        = string
}

variable "agent_log_retention_in_days" {
  description = "Number of days to retain agent logs for"
  default     = 30
  type        = number
}

variable "agent_memory" {
  description = "Memory units to allocate to the agent"
  default     = 2048
  type        = number
}

variable "agent_queue_name" {
  description = "Prefect queue that the agent should listen to"
  default     = "default"
  type        = string
}


variable "agent_task_role_arn" {
  description = "Optional task role ARN to pass to the agent. If not defined, a task role will be created"
  default     = null
  type        = string
}

variable "name" {
  description = "Unique name for this agent deployment"
  default = "perfect-ecs"
  type        = string
}

variable "prefect_account_id" {
  description = "Prefect cloud account ID"
  default = "accountID-REPLACEME"
  type        = string
}

variable "prefect_workspace_id" {
  description = "Prefect cloud workspace ID"
  default = "workspace-id-REPLACEME"
  type        = string
}

variable "prefect_api_key_pnu" {
  description = "Prefect cloud API key"
  type        = string
  default = "********-REPLACEME"
  sensitive   = true
}
# networking
variable "public_subnet_1_cidr" {
  description = "CIDR Block for Public Subnet 1"
  default     = "10.0.1.0/24"
}
variable "public_subnet_2_cidr" {
  description = "CIDR Block for Public Subnet 2"
  default     = "10.0.2.0/24"
}
variable "private_subnet_1_cidr" {
  description = "CIDR Block for Private Subnet 1"
  default     = "10.0.3.0/24"
}
variable "private_subnet_2_cidr" {
  description = "CIDR Block for Private Subnet 2"
  default     = "10.0.4.0/24"
}
