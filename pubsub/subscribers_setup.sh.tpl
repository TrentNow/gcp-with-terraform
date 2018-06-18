#!/bin/bash

curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
pip install virtualenv
virtualenv env
source env/bin/activate
pip install names
pip install crontabs
pip install random
pip install argparse
pip install google.cloud
pip install google-cloud-pubsub
pip install google-cloud-bigquery

cat << EOF > /tmp/subscribers_load.py
#!/usr/bin/env python
import argparse
import names
import random
from google.cloud  import pubsub
import time
from google.cloud import bigquery
import json



def write_messages_to_bq(dataset_id, table_id, messages):
    client = bigquery.Client()
    dataset_ref = client.dataset(dataset_id)
    table_ref = dataset_ref.table(table_id)
    table = client.get_table(table_ref)

    errors = client.create_rows(table, messages)
    if not errors:
        print('Loaded {} row(s) into {}:{}'.format(len(messages), dataset_id, table_id))
    else:
        print('Errors:')
        for error in errors:
            print(error)

# decodes the message from PubSub
def collect_messages(data,bqdatasetid,bqtableid):
    messages = []
    data_raw = json.loads(data)
    recordObject = (str(data_raw['name']), data_raw['age'],data_raw['message_number'])
    messages.append(recordObject)
    write_messages_to_bq(bqdatasetid, bqtableid, messages)



def pull_messages(project, subscription_name,bqdatasetid, bqtableid, sleep ):
    subscriber = pubsub.SubscriberClient()
    subscription_path = subscriber.subscription_path(
        project, subscription_name)

    def callback(message):
        print('Received message: {}'.format(message))
        collect_messages(message.data,bqdatasetid, bqtableid)
        message.ack()

    subscription = subscriber.subscribe(subscription_path, callback=callback)
    print('Listening for messages on {}'.format(subscription_path))

    #future = subscription.open(callback)
    #try:
    #    future.result()
    #except Exception as e:
    #    print(
    #        'Listening for messages on {} threw an Exception: {}'.format(
    #            subscription_name, e))
    #    raise

    while True:
        time.sleep(float(sleep))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('project', help='Your Google Project Name')
    parser.add_argument(
        '--subscription',
        help='Subscription Name',
        default="")
    parser.add_argument(
        '--bqdatasetid',
        help='bqdatasetid',
        default="")
    parser.add_argument(
        '--bqtableid',
        help='BQ Table ID',
        default="")
    parser.add_argument(
        '--sleep',
        help='Interval topic',
        default=60)
    args = parser.parse_args()

    # Will run with a 5 second interval synced to the top of the minute
    pull_messages(args.project, args.subscription, args.bqdatasetid, args.bqtableid, args.sleep)

write()
EOF

chmod +x /tmp/subscribers_load.py
/tmp/subscribers_load.py ${project} --subscription=${subscription} --bqdatasetid=${bigquery_dataset} --bqtableid=${bigquery_table} --sleep=${sleep}  &> /tmp/output.log
