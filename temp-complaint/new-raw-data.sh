#!/bin/bash

export DAY="2022/09/06"

# api.rtt.io/api/v1/



# /json/search/STP/2022/08/28


curl "https://api.rtt.io/api/v1/json/search/STP/$DAY" -u "$USER:$TOKEN" --output "/tmp/raw-data-$(echo $DAY | sed -e 's/\//-/g').json"

echo "/tmp/raw-data-$(echo $DAY | sed -e 's/\//-/g').json"
    