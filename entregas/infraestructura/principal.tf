terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Se usa el ID de la cuenta para que el nombre del bucket sea único globalmente
data "aws_caller_identity" "actual" {}

locals {
  nombre_bucket = "${var.prefijo_bucket}-${data.aws_caller_identity.actual.account_id}"
}

# ---------------------------------------------------------------------------
# 1. Bucket S3 privado (los prefijos entregas/ y resultados-athena/ son parte
#    de las claves de los objetos, no requieren crearse de antemano)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "datos" {
  bucket        = local.nombre_bucket
  force_destroy = true # permite que terraform destroy vacíe el bucket
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket                  = aws_s3_bucket.datos.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# 2. Base de datos de Glue Data Catalog
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "entregas" {
  name = var.nombre_base_datos
}

# ---------------------------------------------------------------------------
# 3. Tabla externa con partition projection por fecha
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"               = "TRUE"
    "classification"         = "csv"
    "skip.header.line.count" = "1"

    # Partition projection: Athena calcula las particiones en cada consulta
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio},${var.fecha_fin}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"

    # Prefijo de cada partición (termina en /). $${fecha} evita que Terraform
    # interprete la variable: en AWS queda literalmente ${fecha}
    "storage.location.template" = "s3://${aws_s3_bucket.datos.bucket}/entregas/fecha=$${fecha}/"
  }

  # fecha NO es columna del CSV: sale de la carpeta fecha=yyyy-MM-dd
  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.bucket}/entregas/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name = "id_envio"
      type = "string"
    }
    columns {
      name = "ciudad"
      type = "string"
    }
    columns {
      name = "transportadora"
      type = "string"
    }
    columns {
      name = "estado"
      type = "string"
    }
    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# ---------------------------------------------------------------------------
# 4. Workgroup de Athena con resultados en resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_athena_workgroup" "entregas" {
  name          = var.nombre_workgroup
  force_destroy = true

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.bucket}/resultados-athena/"
    }
  }
}
