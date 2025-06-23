
Steps:
1. terraform apply -auto-approve 

2. aws s3 cp . s3://testrawdata --recursive 

3. aws glue start-crawler --name test-multi-table-crawler



