#!/usr/local/bin/python3

import json

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--file', help='path to json data file to parse',required=True)
args = parser.parse_args()


data = {}
with open(args.file) as json_file:
    data = json.load(json_file)

services = data["services"]


TL_trains = []
for s in services[:]:
    if s["atocCode"]=="TL":
        TL_trains.append(s)

total_TL = (len(TL_trains))
print(total_TL)

cancelled_due_to_shortage_crew = []

# TI - planning error = shortage of crew?

for s in TL_trains[:]:
    if s.get("locationDetail", {}).get("cancelReasonCode","") == "TI" and s.get("locationDetail", {}).get("displayAs","") == "CANCELLED_CALL":
            cancelled_due_to_shortage_crew.append(s)

len_cancelled_due_to_shortage_crew = len(cancelled_due_to_shortage_crew)

print(len_cancelled_due_to_shortage_crew)

print((len_cancelled_due_to_shortage_crew/total_TL) * 100)

# print(cancelled_due_to_shortage_crew[-2])
