# Variables de los buckets

variable "buckets_names" {
  type        = map(list(string))
  default = {
    row1 = [
      "#{gcs_raw_bucket}#" ,
      "#{project}#",
    ],
    row2 = [
      "#{gcs_trusted_bucket}#" ,
      "#{project}#" ,
    ],
    row3 = [
      "#{gcs_app_bucket}#" ,
      "#{project}#" ,
    ],
  }
}

#//////////////////////////

# Variables de los workflow

variable "workflow_names" {
  type        = map(any)
  default = {
    row1 = [
      "#{dataproc_workflow_name_delta_1}#",
        [
          #{create_dataproc_workflow_arg_delta_1}#
        ],
    ],
    row2 = [
      "#{dataproc_workflow_name_delta_2}#",
        [
          #{create_dataproc_workflow_arg_delta_2}#
        ],
    ],
    row3 = [
      "#{dataproc_workflow_name_delta_3}#",
        [
          #{create_dataproc_workflow_arg_delta_3}#
        ],
    ],
    row4 = [
      "#{dataproc_workflow_name_delta_4}#",
        [
          #{create_dataproc_workflow_arg_delta_4}#
        ],
    ],
    row5 = [
      "#{dataproc_workflow_name_1}#",
        [
          #{create_dataproc_workflow_arg_1}#
        ],
    ],
    row6 = [
      "#{dataproc_workflow_name_2}#",
        [
          #{create_dataproc_workflow_arg_2}#
        ],
    ],
    row7 = [
      "#{dataproc_workflow_name_3}#",
        [
          #{create_dataproc_workflow_arg_3}#
        ],
    ],
  }
}

variable "cluster_name" {
  type    = string
  default = "#{cluster_name_workflow}#"
}

variable "dataproc_job_name" {
  type    = string
  default = "#{dataproc_job_name}#"
}

variable "bucket_workflow" {
  type    = string
  default = "#{bucket_name_workflow}#"
}

#//////////////////////////

# Variables de los dataset

variable "bq_dataset_names" {
  type = list(string)
  default = [
    "#{bq_dataset_tablas_externas}#",
    "#{bq_dataset_vistas}#",
    "#{bq_dataset_tablas_nativas}#",
    "#{bq_dataset_stored_procedures}#",
  ]
}


variable "table_names" {
  type        = map(list(string))
  default = {
    row1 = [
        #{create_table}#
    ],
    row2 = [
        #{create_view}#
    ],
    row3 = [
        #{create_native_table}#
    ],
    row4 = [
        #{create_view_native}#
    ],
  }
}

variable "table_names_path" {
  type = list(string)
  default = [
    #{create_table_path}#
  ]
}
#//////////////////////////

# Variables de los scheduler

variable "scheduler_name" {
  type        = map(list(string))
  default = {
    row1 = [
      "#{scheduler_job_name_1}#" ,
      "#{dataproc_workflow_name_delta_1}#",
      "#{scheduler_program_1}#",
    ],
    row2 = [
      "#{scheduler_job_name_2}#" ,
      "#{dataproc_workflow_name_delta_2}#" ,
      "#{scheduler_program_2}#",
    ],
    row3 = [
      "#{scheduler_job_name_3}#" ,
      "#{dataproc_workflow_name_delta_3}#" ,
      "#{scheduler_program_3}#",
    ],
    row4 = [
      "#{scheduler_job_name_4}#" ,
      "#{dataproc_workflow_name_delta_4}#",
      "#{scheduler_program_4}#",
    ],
  }
}

#//////////////////////////

variable "bucket_data" {
  type    = string
  default = "#{bucket_name_bigquery}#"
}

variable "data_stage" {
  type    = string
  default = "#{data_stage}#"
}

variable "project" {
  type    = string
  default = "#{project}#"
}

variable "location" {
  type    = string
  default = "#{location}#"
}

variable "zone" {
  type    = string
  default = "#{zone}#"
}

variable "service_account" {
  type    = string
  default = "#{service_account_scheduler}#"
}

