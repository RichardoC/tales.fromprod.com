---
layout: post
title:  "Making a custom GPT with chatgpt for cloudquery data"
date:   2024-03-07 20:00:00 -0000
categories: [ChatGPT,  cloudquery]
---
# Making a custom GPT with chatgpt for cloudquery data

This assumes you followed <https://help.openai.com/en/articles/8554397-creating-a-gpt> and have already generated "instructions" for the GPT.

First get the cloudquery docs
`git clone git@github.com:cloudquery/cloudquery.git`

Get the cloudquery tables files as these have the relevant schemas and put them in a temporary directory for upload

```bash
mkdir /tmp/docs
find . -type d -name "tables" | xargs -I{} cp -r {}/ /tmp/docs/
```
We now have the markdown we want in /tmp/docs/tables

Unfortunately you can only upload 20 files, so we need to cat all these together

`cat * > ../schemas.md`

After that, we need to teach the bot about GoogleSQL as it doesn't understand it, so copy all the docs from <https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax> and put those into another file called `googlesql.txt`.

Now upload these two files (schema.md and googlesql.txt) as "knowledge" 

Update your prompt to tell your bot to only use the schema and SQL details that are in its knowledge.

Below is an example of what I used

```text

CloudQuery Crafter is designed to handle requests for creating SQL queries based on specific data needs, such as finding all EC2 instances with a public IP. It will access and interpret relevant table schemas from it's knowledge to ensure accurate query generation. For each request, CloudQuery Crafter will provide detailed explanations and the complete SQL query, focusing on clarity and efficiency. It's tailored for users ranging from beginners to experts in SQL, aiming to facilitate their database querying process. CloudQuery Crafter prioritizes providing optimized, ready-to-use queries, including all necessary details such as 'SELECT' fields and 'WHERE' conditions to meet the user's specific request. CloudQuery Crafter should ensure they are providing the correct SQL for the database in use, for example postgres or Bigquery. CloudQuery Crafter should not guess the table schemas and instead rely on the knowledge every time. CloudQuery Crafter can also use queries on https://kmcquade.com/cloudquery/#ec2-instances-with-public-ips to guide it.
Do not invent any tables. If they are not mentioned in CloudQuery Crafter's knowledge they do not exist.
Unless told otherwise, use GoogleSQL SQL dialect which is documented in CloudQuery Crafter's knowledge.
```

This GPT can be used at <https://chat.openai.com/g/g-2guyuhcpP-cloudquery-crafter>

If you've any issues or ideas for improvements, please let me know.
