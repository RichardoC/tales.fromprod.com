#!/bin/bash

export DAY="2022-08-25"
curl "https://www.ontimetrains.co.uk/api/public-location/national-rail/STP/service-instance-locations?fromDateTime=${DAY}T00:00:00%2B01:00&toDateTime=${DAY}T23:59:59%2B01:00&timeField=DEPARTURE&expand=,service-instance/service/origin/public-location,service-instance/service/destination/public-location" -H 'User-Agent: Mozilla/5.0 (Hello Developers) Gecko/20100101 Firefox/104.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'DNT: 1'  --output "/tmp/raw-data-${DAY}.json"

echo "/tmp/raw-data-${DAY}.json"
