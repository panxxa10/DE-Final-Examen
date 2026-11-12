output "region" {
  description = "Región donde se desplegó la infraestructura"
  value       = var.region
}

output "bucket" {
  description = "Bucket S3 del ejercicio"
  value       = aws_s3_bucket.datos.bucket
}

output "base_de_datos" {
  description = "Base de datos de Glue Data Catalog"
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla" {
  description = "Tabla externa con partition projection"
  value       = aws_glue_catalog_table.entregas.name
}

output "workgroup" {
  description = "Workgroup de Athena"
  value       = aws_athena_workgroup.entregas.name
}
