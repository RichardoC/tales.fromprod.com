import json

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--file', help='path to json data file to parse',required=True)
args = parser.parse_args()


data = {}
with open(args.file) as json_file:
    data = json.load(json_file)

sil = data["_embedded"]["service-instance-locations"]


relevant_trains = []
for s in sil[:]:
    if s["_embedded"]["service-instance"]["_embedded"]["service"]["_links"]["operator"]["href"]=="https://www.ontimetrains.co.uk/api/operator/national-rail/TL":
        relevant_trains.append(s)

total_TL = (len(relevant_trains))
print(total_TL)

cancelled_due_to_shortage_crew = []

for s in relevant_trains[:]:
    if s.get("_embedded", {}).get("service-instance", {}).get("cancelled", False):
        if "shortage of train crew" in s.get("_embedded", {}).get("service-instance", {}).get("cancelledReason",""):
            cancelled_due_to_shortage_crew.append(s)

len_cancelled_due_to_shortage_crew = len(cancelled_due_to_shortage_crew)

print(len_cancelled_due_to_shortage_crew)

print((len_cancelled_due_to_shortage_crew/total_TL) * 100)
