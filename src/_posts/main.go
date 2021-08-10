package main

import (
	//Whatever other deps you need go here

	cloudidentity "google.golang.org/api/cloudidentity/v1"
	goption "google.golang.org/api/option"
)

// Variables to replace in this sample (nonworking) code
// CXXXXXXXX -> Your customer ID
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
	gsl := groupsService.List()
	// Replace CXXXXXXXX with the customer ID
	// you got during prerequisites
	gsl.Parent("customers/CXXXXXXXX")
	listedGroupsResponse, err := gsl.Do()
	if err != nil {
		log.Fatal(err)
	}

	listedGroups := listedGroupsResponse.Groups

	// The email address of the Group is actually the "GroupKey.Id"
	// logging out the first email address as we'll pretend that's what we want
	// Rather than taking the first element, you would loop through and select
	// the one you want

	var relevantGroup *cloudidentity.Group
	found := false

	for _, group := range listedGroups {
		if group.GroupKey.Id == "requiredGroup@example.com" {
			relevantGroup = group
			found = true
			break
		}
	}
	if !found {
		log.Fatal("Group not found")
	}

	log.Info("Email address of group was %+v", group.GroupKey.Id)

	// Now to get the membership of the group, so we can see the emails of the current members

	gms := cloudidentity.NewGroupsMembershipsService(cis)
	lmr, err := gms.List(groupName).Do()
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
	// TODO

	// Now to remove the extra members
	// TODO



}
