#!/usr/bin/env python

import json
import csv
import boto3
import logging
import urllib

from botocore.exceptions import ClientError
logging.basicConfig(format='[%(levelname)s] %(asctime)s: %(message)s', level=logging.INFO)


def add_record(record, table):
    """
    Add records in dynamodb
    :param record: list of record to store in dynamodb
    :param table: name   of the table
    :return:
    """
    dynamodb = boto3.client('dynamodb',
                            region_name="us-east-1")
    try:
        dynamodb.put_item(
            TableName=table,
            Item={
                'user_id': {'N': str(record[0])},
                'person_name': {'S': str(record[1])},
                'person_last_name': {'S': str(record[2])},
                'city': {'S': str(record[3])},
                'number_of_visit': {'S': str(record[4])}
            }
        )
        logging.info('Record for user_id {} added in Dynamodb'.format(record[0]))

    except ClientError as e:
        logging.error("Unexpected error: {}".format(e))
        raise


def read_csv_from_s3(s3_bucket, s3_key):
    """
    Get .csv file from s3 and get records from the file
    :param s3_bucket: name of the s3 bucket
    :param s3_key: name of the csv bucket
    :return:
    """
    s3 = boto3.client("s3")
    try:
        s3_key = urllib.parse.unquote(s3_key)
        csv_file = s3.get_object(Bucket=s3_bucket,
                                 Key=s3_key)

        lines = csv_file['Body'].read().decode('utf-8').splitlines(True)
        reader = csv.reader(lines)
        return reader

    except Exception as e:
        logging.error("Error error: {}".format(e))
        raise


def lambda_handler(event, context):
    if event is None:
        bucket = "user-travel-history-bucket"
        key = "user_travel_history.csv"
    else:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']

    data = read_csv_from_s3(bucket, key)

    for record in data:
        add_record(record, table="user-travel-history")

    return {
        'statusCode': 200,
        'body': json.dumps("CSV uploaded to DynamoDb Successfully")
    }


if __name__ == '__main__':
    lambda_handler(event=None, context=None)
