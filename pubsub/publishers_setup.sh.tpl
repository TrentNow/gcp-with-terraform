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

cat << EOF > /tmp/publishers_load.py
#!/usr/bin/env python
import argparse
import names
import random
from google.cloud import pubsub
from crontabs import Cron, Tab
import base64
import json

publisher = pubsub.PublisherClient()
topic_path = publisher.topic_path("${project}", "${pubsub_topic}")

def call_pubsubfunction():
    name_value = names.get_full_name().encode('utf-8')
    age_value = random.randint(0, 50)
    message_number = random.randint(0, 500000)
    body = {'name': name_value, 'age' : age_value , 'message_number' : message_number}
    str_body = json.dumps(body)
    data = str_body.encode('utf8')
    response=publisher.publish(topic_path, data=data)
    print('Published messages with custom attributes. Message number->'+str(message_number))




if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('project', help='Your Google Project Name')
    parser.add_argument(
        '--topic',
        help='pubsub topic',
        default="")
    parser.add_argument(
        '--sleep',
        help='Interval topic',
        default=5)
    args = parser.parse_args()
    # Will run with a 5 second interval synced to the top of the minute
    Cron().schedule(
        Tab(name='publish_information').every(seconds=int(args.sleep)).run(call_pubsubfunction)
    ).go()

write()
EOF

chmod +x /tmp/publishers_load.py
/tmp/publishers_load.py ${project} --topic ${pubsub_topic} --sleep ${sleep}  &> /tmp/output.log
