import boto3
import time
from jinja2 import Template
import json


def empty_s3_bucket(bucket_name, prefix=None):
    s3 = boto3.resource("s3")
    bucket = s3.Bucket(bucket_name)

    print(f"Emptying bucket: {bucket_name} {'with prefix: ' + prefix if prefix else ''}")

    if prefix:
        objects = bucket.objects.filter(Prefix=prefix)
    else:
        objects = bucket.objects.all()

    # Delete in batches of 1000 (S3 max per call)
    delete_batches = []
    batch = []

    for obj in objects:
        batch.append({'Key': obj.key})
        if len(batch) == 1000:
            delete_batches.append(batch)
            batch = []

    if batch:
        delete_batches.append(batch)

    for i, batch in enumerate(delete_batches):
        print(f"Deleting batch {i+1}/{len(delete_batches)}...")
        bucket.delete_objects(Delete={'Objects': batch})

    print("✅ Bucket emptied successfully.")


    

def run_athena_query(
    query,
    database,
    output_s3,
    region="us-east-1",
    workgroup="primary"
):
    client = boto3.client("athena", region_name=region)

    response = client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={"Database": database},
        ResultConfiguration={"OutputLocation": output_s3},
        WorkGroup=workgroup
    )

    query_execution_id = response["QueryExecutionId"]
    print(f"Started query execution: {query_execution_id}")

    # Wait until the query finishes
    while True:
        result = client.get_query_execution(QueryExecutionId=query_execution_id)
        status = result["QueryExecution"]["Status"]["State"]

        if status in ["SUCCEEDED", "FAILED", "CANCELLED"]:
            break

        time.sleep(2)

    if status == "SUCCEEDED":
        print(f"Query succeeded: {query_execution_id}")
        return query_execution_id
    else:
        reason = result["QueryExecution"]["Status"].get("StateChangeReason", "Unknown")
        raise Exception(f"Query failed: {status} — {reason}")

def run_my_jinja_job(**kwargs):
    print("******Running my custom Python job in Airflow!******")
    #if __name__ == "__main__":
    print("Step#1 emptying the s3 bucket...")
    empty_s3_bucket("testtransformeddata")
    database = "test_data_catalog"
    output_s3 = "s3://testtransformeddata/"
 
    params = kwargs.get("params", {})
    print(params)
    template_path = '/usr/local/airflow/dags/sql/jinja_sql_list_parameter.sql'

    # Render Jinja template
    with open(template_path, 'r') as f:
        template = Template(f.read())
    context = str(kwargs.get("params", {}))
    new_context = context.replace("\"", "")
    context = new_context.replace("'", "\"")
    new_context = json.loads(context)
      
    rendered_sql = template.render(new_context)
    print("Rendered SQL:\n", rendered_sql)

   # Run Athena queries
    for entry in rendered_sql.split(';'):
        query = entry.strip()
        if query:
            print(f"Executing query: {query[:60]}...")
            run_athena_query(query, database, output_s3)

