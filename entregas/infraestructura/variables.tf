variable "region" {
  description = "Región de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}

variable "prefijo_bucket" {
  description = "Prefijo del nombre del bucket. Se le agrega el ID de la cuenta para que sea único"
  type        = string
  default     = "examen-entregas"
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos en Glue Data Catalog"
  type        = string
  default     = "entregas_db"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa en Glue Data Catalog"
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena"
  type        = string
  default     = "entregas-wg"
}

variable "fecha_inicio" {
  description = "Primera fecha proyectada (yyyy-MM-dd), incluida"
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin" {
  description = "Última fecha proyectada (yyyy-MM-dd), incluida"
  type        = string
  default     = "2026-10-03"
}
