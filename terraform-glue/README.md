
Steps:
terraform apply -auto-approve 
aws s3 cp . s3://testrawdata --recursive 
aws glue start-crawler --name test-multi-table-crawler



