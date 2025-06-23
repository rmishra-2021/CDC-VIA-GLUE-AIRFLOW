from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from jinja_my_python_list_parameter import run_my_jinja_job

with DAG(
    dag_id="athena_query_with_parameters",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,  # Trigger manually
    catchup=False,
    tags=["athena", "jinja", "parameterized"],
    params={
        "data_format": "PARQUET",
        "compression": "SNAPPY",
        "table_list": [
            {
                "target_table": "sporting_event_ticket",
                "key_column": "id"
            },
            {
                 "target_table": "ticket_purchase_hist",
                 "key_column": "purchased_by_id,sporting_event_ticket_id,transferred_from_id"

            }
           
          
        ]
    

    }
) as dag:


    run_query = PythonOperator(
        task_id="render_and_run_looped_sql",
        python_callable=run_my_jinja_job,
        provide_context=True
    )
