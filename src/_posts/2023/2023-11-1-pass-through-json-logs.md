---
layout: post
title:  "Pass through JSON logs with vector or filebeat"
date:   2023-11-01 11:00:00 -0000
categories: [JSON, logging,  ElasticSearch]
---
# Pass through JSON logs with vector or filebeat

Say you are using an application that emits JSON formatted logs, with one log per line in the log file, and you want to store these in ElasticSearch and view them natively in kibana - how would you manage this?

Both Vector and filebeat have quirks, so I've written this guide on how I got these log processors to perform as I wanted - just passing through the original json object so elastic search can parse it as expected

## Vector

[Vector](https://vector.dev/docs/) is a log processor written in Rust supported by Datadog.

One of the main quirks is that it automatically puts you message in `.message` in the data model, with some other metadata that isn't documented in any single place

Using the snippet below, the logs are read from a series of files in `tmp` that have a json object on each line, and are named "my_log" with a suffix

```yaml
# vector.yaml

---
healthchecks:
  enabled: true
  require_healthy: true
sources:
  my_application_log_file:
    type: file
    include:
        - /tmp/my-log*
transforms:
  audit_files_json_parser:
    inputs:
      - my_application_log_file
    type: remap
    source: |-
      . = parse_json!(.message)
sinks:
  elasticsearch:
    type: elasticsearch
    inputs:
      - audit_files_json_parser
    auth:
      strategy: basic
      user: "${ELASTICSEARCH_USER}"
      password: "${ELASTICSEARCH_PASSWORD}"
    endpoints: ["${ELASTICSEARCH_URL}"]
    bulk:
      index: "my_application"
      action: create
    mode: bulk
```

## Filebeat

[Filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/index.html) is a log processor maintained by Elastic

The equivalent configuration for filebeat is

```yaml
---
filebeat.inputs:
    - type: filestream
    id: my_application_log_file
    paths:
        - /tmp/my-log*

processors:
  - decode_json_fields:
      fields: [message]
      process_array: false
      max_depth: 2
      overwrite_keys: true
      add_error_key: true
  - move_fields:
      from: "message"
      fields: []
      to: "" # move message fields up to root

output.elasticsearch:
  hosts: ['${ELASTICSEARCH_URL}']
  username: ${ELASTICSEARCH_USER}
  password: ${ELASTICSEARCH_PASSWORD}
  index: my_application
  bulk_max_size: 50
  compression_level: 3

logging.to_stderr: true


```

### Gotchas

Despite the docs claiming that the following works, it won't with a particularly unhelpful error message `{\"type\":\"document_parsing_exception\",\"reason\":\"[1:1537] object mapping for [message] tried to parse field [message] as object, but found a concrete value\"}, dropping event!","service.name":"filebeat","ecs.version":"1.6.0"}`

```yaml
  - decode_json_fields:
      fields: [message]
      process_array: false
      max_depth: 2
      overwrite_keys: true
      add_error_key: true
      target: "" # will place the json in the root object
```

My best guess is that it needs to do this in two operations rather than one, hence the snippet above.
