---
layout: post
title:  "Managing Google Groups via the API, aka what they don't want you to do!"
date:   2021-08-10 2:00:00
categories: [Google, APIs,  Golang, Go]
---
# Managing Google Groups via the API, despite their best efforts
Google have made it difficult to do this, they somewhat document two different APIs to achieve this, with limited success. This is especially true if you want to use a service account rather than a user API token for the management.

* [Using the directory API](https://developers.google.com/admin-sdk/directory/v1/guides/manage-groups)
* [Using the Cloud Identity APIs - newer and seems to be preferred going forward](https://cloud.google.com/identity/docs/how-to/create-dynamic-groups)

At the time of writing, this are not sufficiently detailed to do more than work out those are the APIs to use. That's where this guide comes in.

## What you'll achieve by the end of this and why you care//rephrase

A google group who's membership is managed (via email address) by a Golang binary. The steps will apply to the other language client libraries

## Prerequisites
* Google Cloud Identity Premium
* A paid for Google Workspace
* A Google cloud Service Account (SA)
  * An API key for that SA
  * To record the email address of that SA
  * This SA requires **no permissions at all** in the cloud console
* The magic "Customer ID"
  * This can only be obtained through the steps on [https://support.google.com/a/answer/10070793?hl=en] by a workspace admin
* The google group you wish to manage
  * You should add the SA's email address as an "OWNER" of that group, and change the subscription to "no emails" as it can't receive them.

## Managing Google Group membership in Golang
These steps should be equivalent for other languages, but haven't tried.

### Dependencies
* A source of email addresses to add to your group
* The (cloud identity client library)[https://pkg.go.dev/google.golang.org/api@v0.51.0/cloudidentity/v1]
* The (Google API options library)[https://pkg.go.dev/google.golang.org/api@v0.52.0/option]

The following is pseudo code and won't compile without changes

```golang
package main

import (
  //Whatever other deps you need go here

  goption "google.golang.org/api/option"
  cloudidentity "google.golang.org/api/cloudidentity/v1"
)

func main() {

  // Create your goptions from your credential file.
  // This is the Service Account Key you downloaded during
  // The prerequisites.
  goptions := goption.WithCredentialsFile("/some/file/location.json")

  // Next you'll want to get the group you're interested in
  // The only way I found was to get all accessible groups
  // Then filter for the relevant email address

  groupsService := cloudidentity.NewGroupsService(cis)
	gsl := groupsService.List()
  // Replace CXXXXXXXX with the customer number
  // you got during prerequisites
	gsl.Parent("customers/CXXXXXXXX")
	listedGroupsResponse, err := gsl.Do()
	if err != nil {
		log.Error(err)
	}

  listedGroups := listedGroupsResponse.Groups

  // The email address of the Group is actually the "GroupKey.Id"
  // logging out the first email address as we'll pretend that's what we want
  // Rather than taking the first element, you would loop through and select
  // the one you want
  relevantGroup := listedGroups[0]
  log.Info("Email address of group was %+v", group.GroupKey.Id)

  // Now to get the membership of the group, so we can see the emails of the current members
  


}
```


