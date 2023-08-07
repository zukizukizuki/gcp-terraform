import base64
import json
import os
from collections import defaultdict
from typing import Dict, Iterable
from google.cloud import compute_v1
from google.cloud import storage

BUCKET_NAME = str(os.getenv("GCE_START_STOP_CONFIG_BUCKET"))
EXCLUDE_INSTANCES_LIST_KEY = str(os.getenv("EXCLUDE_INSTANCES_LIST"))
PROJECT_LIST_KEY = str(os.getenv("PROJECT_LIST"))


def control_server(command: str, project_list: list, exclude_instances: list) -> None:
    instance_client = compute_v1.InstancesClient()

    exclude_list = [exclude_instance.strip() for exclude_instance in exclude_instances]

    for project_id in project_list:
        request = compute_v1.AggregatedListInstancesRequest()
        request.project = project_id.strip()

        # max_resultsは最大値である500を設定(2023/1/19 山岡)
        request.max_results = 500

        for zone, response in instance_client.aggregated_list(request=request):
            if response.instances:
                for instance in response.instances:
                    if f"{request.project}.{instance.name}" in exclude_list or 'gke' in instance.name:
                        continue
                    match command:
                        case "start":
                            operation = instance_client.start(project=request.project, zone=zone.replace(
                                'zones/', ''), instance=instance.name)
                        case "stop":
                            operation = instance_client.stop(project=request.project, zone=zone.replace(
                                'zones/', ''), instance=instance.name)
                    print(f"{command} {instance.name} {request.project}")


def get_gcs_file_contents(bucket_name: str, object_key: str) -> str:
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = storage.Blob(object_key, bucket)
    gcs_file_contents = blob.download_as_string().decode()
    return gcs_file_contents


def main(event, _) -> None:
    # pubsubから受け取ったdataを変数に入れる
    base64_encoded_message = event['data']
    # base64_encoded_messageをbase64デコードして変数に入れる
    json_message_string = base64.b64decode(base64_encoded_message)
    # jsonの文字列を辞書に変換する
    message_dict = json.loads(json_message_string)

    server_status = message_dict["server_status"]
    gcs_exclude_list = get_gcs_file_contents(
        BUCKET_NAME, EXCLUDE_INSTANCES_LIST_KEY).splitlines()
    gcs_project_list = get_gcs_file_contents(
        BUCKET_NAME, PROJECT_LIST_KEY).splitlines()
    return control_server(server_status, gcs_project_list, gcs_exclude_list)