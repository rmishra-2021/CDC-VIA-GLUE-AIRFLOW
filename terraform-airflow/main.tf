provider "aws" {
  region = "us-east-1"
}

# 1. S3 Bucket for DAGs
resource "aws_s3_bucket" "airflow_bucket" {
  bucket = "test-airflow-dags"
  force_destroy = true
}

# 2. Upload DAG + Script
resource "aws_s3_object" "dag" {
  bucket = aws_s3_bucket.airflow_bucket.id
  key    = "dags/jinja_my_dag_list_parameter.py"
  source = "dags/jinja_my_dag_list_parameter.py"
  etag   = filemd5("dags/jinja_my_dag_list_parameter.py")
}

resource "aws_s3_object" "script" {
  bucket = aws_s3_bucket.airflow_bucket.id
  key    = "dags/jinja_my_python_list_parameter.py"
  source = "dags/jinja_my_python_list_parameter.py"
  etag   = filemd5("dags/jinja_my_python_list_parameter.py")
}

resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.airflow_bucket.id
  key    = "requirements.txt"
  source = "dags/requirements.txt"
  etag   = filemd5("dags/requirements.txt")
}

resource "aws_s3_object" "sqlfiles" {
  bucket = aws_s3_bucket.airflow_bucket.id
  key    = "dags/sql/jinja_sql_list_parameter.sql"
  source = "dags/sql/jinja_sql_list_parameter.sql"
  etag   = filemd5("dags/sql/jinja_sql_list_parameter.sql")
}


# 3. MWAA Environment
resource "aws_mwaa_environment" "airflow_env" {
  name              = "test-mwaa-env"
  #airflow_version   = "2.7.2"
  environment_class = "mw1.micro"

  source_bucket_arn = aws_s3_bucket.airflow_bucket.arn
  dag_s3_path       = "dags"
  requirements_s3_path = "requirements.txt"
  execution_role_arn = "arn:aws:iam::662235717802:role/service-role/AmazonMWAA-MyAirflowEnvironment-Oo6uq0"

  network_configuration {
    security_group_ids = ["sg-07ca75604822b1216"]  # Replace with valid SG
    subnet_ids         = [var.subnet_private1,var.subnet_private2] # Must be private subnets
  }

  webserver_access_mode = "PUBLIC_ONLY"

  tags = {
    Environment = "test"
    Project     = "airflow-python-runner"
  }
}
