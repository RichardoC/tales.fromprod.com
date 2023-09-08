---
categories:
- Google
- APIs
- Golang
- Go
date: "2022-01-11T19:00:00Z"
title: Attempt 2 - Managing Google Groups via the API, aka what they don't want you
  to do!
---
# Attempt 2 - Managing Google Groups via the API, despite their best efforts
Due to some issues with the groupsService.List() (still pending with Google Support) I found a cleaner way to find the groups, by using a lookup based on the group email address.
I have rewritten this guide to use this instead, as it's a more sensible way of approaching this problem. The old guide will remain as it should work...


## Managing Google Groups via the API, despite their best efforts
Google have made it difficult to do this, they somewhat document two different APIs to achieve this, with limited success. This is especially true if you want to use a service account rather than a user API token for the management.

* [Using the directory API](https://developers.google.com/admin-sdk/directory/v1/guides/manage-groups)
* [Using the Cloud Identity APIs - newer and seems to be preferred going forward](https://cloud.google.com/identity/docs/how-to/create-dynamic-groups)

At the time of writing, these are not sufficiently detailed to do more than work out those are the APIs to use. That's where this guide comes in.

## What this will help you achieve

A golang binary which manages the membership of a Google Group for you. The steps will likely apply to the other language client libraries

## Prerequisites
* Google Cloud Identity Premium
* A paid for Google Workspace
* A Google cloud Service Account (SA)
  * An API key for that SA
  * The email address of that SA
  * This SA requires **no permissions at all** in the cloud console
* The google group you wish to manage
  * You should add the SA's email address as an "OWNER" of that group, and change the subscription to "no emails" as it can't receive them.

### Dependencies
* A source of email addresses to add to your group
* The [cloud identity client library](https://pkg.go.dev/google.golang.org/api@v0.51.0/cloudidentity/v1)
* The [Google API options library](https://pkg.go.dev/google.golang.org/api@v0.52.0/option)

The following is example code and won't compile without changes, and lacks niceties like error handling and retrying in the face of inevitable errors.

This should provide a clearer understanding of the hierarchy of the Google Groups data model.



```golang
package main

import (
	//Whatever other deps you need go here

	cloudidentity "google.golang.org/api/cloudidentity/v1"
	goption "google.golang.org/api/option"
)

// Variables to replace in this sample (nonworking) code
// requiredGroup@example.com -> The email address of the google group you care about
// "a@a.com", "b@a.com" -> The actual list of emails you want added
// addDelta -> A function to say which emails need added to the group based on current emails
// removeDelta -> A function to say which emails need removed from the group based on current emails

func main() {

	// Create your goptions from your credential file.
	// This is the Service Account Key you downloaded during
	// The prerequisites.
	goptions := goption.WithCredentialsFile("/some/file/location.json")

	ctx := context.Background()
	cis := cloudidentity.NewService(ctx, goptions)

	// Next you'll want to get the group you're interested in
	// The only way I found was to get all accessible groups
	// Then filter for the relevant email address

	groupsService := cloudidentity.NewGroupsService(cis)

	// Different from old verison
	// Finding the groupName by using the fact that the GroupKeyId 
	// Is actually the email address of the group
	// The group name is a magic thing of format  groups/{group_id}
	groupsServiceLookup := groupsService.Lookup()
	groupsServiceLookup.GroupKeyId(ggroupemail)

	groupLookupResponse, err := groupsServiceLookup.Do()
	if err != nil {
		log.Fatal(err)
	}

	// If we wanted the group directly
	// reqGroup, err := gs.Get(groupLookupResponse.Name).Do()

	// Now to get the membership of the group, so we can see the emails of the current members

	gms := cloudidentity.NewGroupsMembershipsService(cis)

	// Response containing list of memberships
	lmr, err := gms.List(groupLookupResponse.Name).Do()
	// Pulling out just the memberships
	currentMemberships := lmr.Memberships

	var currentEmails []string

	for _, member := range currentMemberships {
		// The EntityKey == PreferredMemberKey == the user email
		email := member.PreferredMemberKey.Id
		currentEmails = append(currentEmails, email)
	}

	desiredEmails := []string{"a@a.com", "b@a.com"}

	//The following functions aren't defined, you need to define this logic yourself

	// Example if you wish to only add the new emails
	// Rather than deal with 409 which you get
	// if the email is already a member
	additionalEmails := addDelta(desiredEmails, currentEmails)
	// Example if you wish to remove any members who shouldn't be there
	emailsToRemove := removeDelta(desiredEmails, currentEmails)

	// Now to add the new members

	for _, email := range additionalEmails {
		key := &cloudidentity.EntityKey{Id: email}
		roles := []*cloudidentity.MembershipRole{&cloudidentity.MembershipRole{Name: "MEMBER"}}
		// Despite the docs saying it's Member by default, we must explicitly set it
		// Or you will get ERROR: googleapi: Error 400: resource.roles must be specified, badRequest
		// when trying to create the membership

		mem := &cloudidentity.Membership{PreferredMemberKey: key, Roles: roles}

		// This part youll want to make retriable
		// Any 409's are "fine" as it means the member already exists
		// Using the "Name" found earlier as it's annoying to create due to format
		_, err = gms.Create(relevantGroup.Name, mem).Do()
		errStr := fmt.Sprint(err)
		if err != nil && !strings.Contains(errStr, "Error 409") {
			log.Error(err)
			continue
		}

	}

	// Now to remove the extra members

	// Have a horrible loop as there doesn't seem to be a nice way to get a membership ID...
	// MembershipLookupCall doesn't exist :(

	for _, email := range emailsForRemoval {

		found := false

		for _, Membership := range currentMemberships {
			if Membership.PreferredMemberKey.Id == email {
				found = true
				_, err := gms.Delete(Membership.Name).Do()
				if err != nil {
					e := fmt.Errorf("Encountered error while deleting membership %+v", err)
					log.Error(e)
					continue
				}
			}
		}
		if !found {
			log.Error(err)
			continue
		}

	}

}

```


