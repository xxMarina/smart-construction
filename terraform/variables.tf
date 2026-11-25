variable "project_id" {
  description = "ID do projeto na GCP"
  type        = string
  default     = "projeto-mensal-4"
}

variable "region" {
  description = "Região da GCP"
  type        = string
  default     = "southamerica-east1"
}

variable "zone" {
  description = "Zona padrão das instâncias"
  type        = string
  default     = "southamerica-east1-a"
}

variable "app_machine_type" {
  description = "Como o build ocorre no GitHub Actions, e2-small aguenta com folga"
  type        = string
  default     = "e2-small"
}

variable "db_machine_type" {
  description = "VM exclusiva para PostgreSQL 17"
  type        = string
  default     = "e2-small"
}

variable "storage_machine_type" {
  description = "VM dedicada para SeaweedFS (editorial e privado)"
  type        = string
  default     = "e2-small"
}