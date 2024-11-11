#!/bin/python3
import ssl
import socket
import datetime
import requests


#DomainName you need to check
domains = ["zerodhafundhouse.com:443", "gorattle.com:443"]

#Slack channel webhook
url = 'https://hooks.slack.com/services/T04GQBNDJPL/B07V0CP3QDV/xxxxxxxxxxxxxxxxxx'
headers = {'content-type': 'application/json'}

for i in domains:
    name = i.split(":")[0]
    port = i.split(":")[1]
    context = ssl.create_default_context()
    with context.wrap_socket(socket.socket(socket.AF_INET), server_hostname=name) as sock:
        sock.settimeout(5)
        sock.connect((name, 443))
        cert = sock.getpeercert()
    expiry_date = datetime.datetime.strptime(cert['notAfter'], "%b %d %H:%M:%S %Y %Z")
    remaining_days = (expiry_date - datetime.datetime.utcnow()).days

    if remaining_days >= 15:
        message = "Certificate is about to Expire for domain {} in *{}* days, Please Renew it ....".format(name,remaining_days)
        payload = '{{"text":"{}"}}'.format(message)
        r = requests.post(url, data=payload, headers=headers)
