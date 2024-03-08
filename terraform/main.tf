resource "google_storage_bucket" "create_buckets" {
  count = length(keys(var.buckets_names))

  project       = "${var.buckets_names[keys(var.buckets_names)[count.index]][1]}"
  name          = "${var.buckets_names[keys(var.buckets_names)[count.index]][0]}"
  
  location      = var.location
  storage_class = "STANDARD"
  force_destroy = true
  uniform_bucket_level_access = false
}

resource "null_resource" "copy_files" {
  provisioner "local-exec" {

    command     = "bash scripts/build.sh"
    working_dir = "../"
    environment = {
      "BUCKET_NAME"               = "${var.buckets_names[keys(var.buckets_names)[2]][0]}"
      "TARGET"                    = "app_files"
      "PROJECT_NAME"              = "${var.project}"
      "SERVICE_ACCOUNT_KEY_PATH"  = "#{serviceAccount}#"
      "DATA_STAGE"                = "${var.data_stage}"
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    google_storage_bucket.create_buckets
  ]
}

resource "google_dataproc_workflow_template" "create_workflow_template" {
  count         = length(keys(var.workflow_names))
  project       = "${var.project}"
  name          = "${var.workflow_names[keys(var.workflow_names)[count.index]][0]}"
  location      = "${var.location}"
  dag_timeout   = "28800s"

  placement {
    managed_cluster {
      cluster_name = "${var.cluster_name}"
      config {
        staging_bucket = "${var.bucket_workflow}"
        gce_cluster_config {
          network = "default"
          service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
          zone = "${var.zone}"
        }
        master_config {
          disk_config {
            boot_disk_size_gb  = 150
            boot_disk_type     = "pd-standard"
            # num_local_ssds     = 1
          }
            machine_type = "n2-standard-8"
            num_instances    = 1
          }
        software_config {
          image_version = "2.1-debian11"
          properties = {
            "dataproc:dataproc.logging.stackdriver.job.driver.enable" = "true"
            "dataproc:dataproc.allow.zero.workers"                    = "true"
            "dataproc:pip.packages"                                   = "dynaconf==3.2.2,toml==0.10.2,great-expectations==0.18.7"
          }
        }
        # worker_config {
        #   disk_config {
        #     boot_disk_size_gb  = 150
        #     boot_disk_type     = "pd-standard"
        #   }
        #   machine_type = "n2-standard-32"
        #   num_instances    = 2
        # }
      }      
    }
  }

  jobs {
    pyspark_job {
      args = "${var.workflow_names[keys(var.workflow_names)[count.index]][1]}"
      jar_file_uris = [
        "gs://${var.buckets_names[keys(var.buckets_names)[2]][0]}/app_files/dist/${var.data_stage}.toml",
        "gs://${var.buckets_names[keys(var.buckets_names)[2]][0]}/app_files/dist/default.toml",
      ]
      main_python_file_uri = "gs://${var.buckets_names[keys(var.buckets_names)[2]][0]}/app_files/dist/main.py"
      properties = {
        "spark.app.name"                                                  = "trusted_workflow_${var.data_stage}"
        "spark.jars.packages"                                             = "io.delta:delta-core_2.12:2.3.0"
        "spark.sql.extensions"                                            = "io.delta.sql.DeltaSparkSessionExtension"
        "spark.sql.catalog.spark_catalog"                                 = "org.apache.spark.sql.delta.catalog.DeltaCatalog"
        "spark.databricks.delta.properties.defaults.enableChangeDataFeed" = "false"
        "spark.databricks.delta.retentionDurationCheck.enabled"           = "false"
        "spark.databricks.delta.autoCompact.enabled"                      = "auto"
        "spark.databricks.delta.optimizeWrites.enabled"                   = "true"
        "spark.databricks.delta.properties.defaults.targetFileSize"       = "10485760"
        "spark.databricks.delta.optimize.repartition.enabled"             = "true"
        "spark.executor.heartbeatInterval"                                = "100000"
        "spark.network.timeout"                                           = "300"
        "spark.sql.debug.maxToStringFields"                               = "150"
        "spark.sql.parquet.int96RebaseModeInWrite"                        = "LEGACY"
        "spark.sql.shuffle.partitions"                                    = "64"
        "spark.sql.files.ignoreCorruptFiles"                              = "true"
        "spark.sql.parquet.datetimeRebaseModeInWrite"                     = "CORRECTED"
        "spark.sql.autoBroadcastJoinThreshold"                            = "-1"
        "spark.sql.adaptive.enabled"                                      = "false"
      }
      python_file_uris = [
        "gs://${var.buckets_names[keys(var.buckets_names)[2]][0]}/app_files/dist/quind_data_library.zip",
        "gs://${var.buckets_names[keys(var.buckets_names)[2]][0]}/app_files/dist/flows.zip",
      ]
    }
    step_id = "${var.dataproc_job_name}"
  }
  depends_on = [
    null_resource.copy_files
  ]
}

resource "google_cloud_scheduler_job" "create_scheduler_job" {
  count = length(keys(var.scheduler_name))

  project     = "${var.project}"
  name        = "${var.scheduler_name[keys(var.scheduler_name)[count.index]][0]}"
  region      = "${var.location}"
  description = "Esta programación es la encargada de ejecutar el job asociado al flujo de trabajo ${var.scheduler_name[keys(var.scheduler_name)[count.index]][1]}"
  schedule    = "${var.scheduler_name[keys(var.scheduler_name)[count.index]][2]}"
  time_zone   = "America/Bogota"

  http_target {
    uri         = "https://dataproc.googleapis.com/v1/projects/${var.project}/regions/${var.location}/workflowTemplates/${var.scheduler_name[keys(var.scheduler_name)[count.index]][1]}:instantiate?alt=json"
    http_method = "POST"
    oauth_token {
      service_account_email = "${var.service_account}"
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
    headers = {
      "User-Agent" = "Google-Cloud-Scheduler"
    }
  }

  retry_config {
    retry_count          = 3
    max_retry_duration   = "10800s"
    min_backoff_duration = "3600s"
    max_backoff_duration = "86400s"
    max_doublings        = 5
  }

  depends_on = [
    google_dataproc_workflow_template.create_workflow_template
  ]
}

resource "google_bigquery_dataset" "create_dataset" {
  for_each = toset(var.bq_dataset_names)
  
  dataset_id = "${each.value}"
  location   = "US"
  project    = "${var.project}"

  depends_on = [
    google_cloud_scheduler_job.create_scheduler_job
  ]
}

resource "google_bigquery_table" "native_table" {
  count = length(var.table_names["row3"])

  project     = var.project
  dataset_id  = var.bq_dataset_names[2]
  table_id    = var.table_names["row3"][count.index]

  schema = var.table_names["row3"][count.index] == "dim_Indicador" ? file("/#{System.DefaultWorkingDirectory}#/scripts/dim_indicadores_schema.json") : file("/#{System.DefaultWorkingDirectory}#/scripts/native_table_schema.json")

  deletion_protection = false

  depends_on = [
    google_bigquery_dataset.create_dataset
  ]
}

resource "google_bigquery_table" "view_native_table" {
  count = length(var.table_names["row4"])

  project     = var.project
  dataset_id  = var.bq_dataset_names[1]
  table_id    = var.table_names["row4"][count.index]
  view {
    query = "SELECT * FROM `${var.project}.${var.bq_dataset_names[2]}.${var.table_names["row3"][count.index]}`"
    use_legacy_sql = false
  }
  deletion_protection = false

  depends_on = [
    google_bigquery_table.native_table
  ]
}

resource "google_bigquery_table" "external_table" {
  count = length(var.table_names["row1"])

  dataset_id = var.bq_dataset_names[0]
  project    = var.project
  table_id   = var.table_names["row1"][count.index]

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = can(regex("fact", var.table_names["row1"][count.index])) ? [
       "gs://${var.bucket_data}/FUNNEL/EXCEL/${ var.table_names_path[count.index] }/part*parquet"
      ] : [
       "gs://${var.bucket_data}/FUNNEL/TERADATA/${ var.table_names_path[count.index] }/part*parquet" 
      ]
  }

  deletion_protection = false

  depends_on = [
    google_bigquery_dataset.create_dataset
  ]

}

resource "google_bigquery_table" "view_table" {
  count = length(var.table_names["row2"])

  project     = var.project
  dataset_id  = var.bq_dataset_names[1]
  table_id    = var.table_names["row2"][count.index]
  view {
    query = "SELECT * FROM `${var.project}.${var.bq_dataset_names[0]}.${var.table_names["row1"][2]}`"
    use_legacy_sql = false
  }
  deletion_protection = false

  depends_on = [
    google_bigquery_table.native_table
  ]
}

