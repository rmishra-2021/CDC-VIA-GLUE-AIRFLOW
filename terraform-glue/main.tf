provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

resource "aws_s3_bucket" "rawdata2025" {
  bucket = "testrawdata"  # nucket name must be globally unique

  tags = {
    Name        = "MyBucket"
    Environment = "test"
  }
}
resource "aws_s3_bucket" "transformeddata2025" {
  bucket = "testtransformeddata"  # Bucket name must be globally unique

  tags = {
    Name        = "MyBucket"
    Environment = "test"
  }
}


resource "aws_iam_role" "glue_crawler_role" {
  name = "glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_role_policy" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_policy" "glue_s3_access" {
  name        = "GlueS3AccessPolicy"
  description = "Policy to allow Glue to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::testrawdata",
          "arn:aws:s3:::testrawdata/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_access_policy" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}

resource "aws_glue_catalog_database" "test_db" {
  name = "test_data_catalog"
}


resource "aws_glue_crawler" "test_crawler" {
  name          = "test-multi-table-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.test_db.name

  s3_target {
    path = "s3://testrawdata/"
  }

  configuration = jsonencode({
    Version  = 1.0,
    Grouping = {
      TableLevelConfiguration = 3
    },
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  tags = {
    Environment = "test"
    Project     = "test"
  }
}
