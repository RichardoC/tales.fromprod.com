---
layout: post
title: "Authenticating to AWS from GitHub actions"
date: 2024-08-21 09:00:00 -0000
categories: [GitHub]
---

# Authenticating to AWS from GitHub actions for multiple AWS accounts

If you're doing any sort of Infra as code on GitHub, and have AWS estate you're going to have to authenticate somehow.

You've two main options for doing this

- Creating an IAM user in AWS which requires manual key rotation and doesn't follow best practices (Don't do this)
- Using [OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) so you don't directly have to deal with credentials

## Using OIDC to authenticate to AWS from GitHub

Guides used

- <https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services>
- <https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/>

### Account layout

- AWS Organisation
  - Shared Services
  - Development
  - Production
  - ...

### IAM considerations

- I wanted teams to only have to add an IAM role if they needed some new access and it should "just work"
- The solution should only allow access to AWS IAM roles that have "opted in"
- The teams should be able to limit their access to their specific repos or Github workflows.

### How does it work?

- AWS Organisation
  - Shared Services (0000000000)
    - Identity Provider - Github OIDC
    - Github Assumed role - GithubRole
  - Development (1111111111)
    - Team managed role - DevelopmentDeployerRole
  - Production (2222222222)
    - Team managed role - ProductionDeployerRole
  - ...

Github workflows request a JWT from Github, and then use this to assume the `GithubRole`
They then use the sts token they received from AWS to assume the `DevelopmentDeployerRole` or `ProductionDeployerRole` and do whatever they need to.

### Details of how it actually works

#### Example github workflow

```
jobs:
  push:
    name: Push to ECR
    runs-on: ubuntu-latest

    steps:

	  # Do your building before
      - name: Configure initial AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: "arn:aws:iam::0000000000:role/GithubRole"
          aws-region: ${{ inputs.AWS_REGION }}

      - name: Configure AWS credentials for specific container registry
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: "arn:aws:iam::1111111111:role/DevelopmentDeployerRole"
          aws-region: ${{ inputs.AWS_REGION }}
          role-chaining: true
          role-skip-session-tagging: true

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
        with:
          registries: 1111111111.dkr.ecr.eu-west-1.amazonaws.com/hello-repository
	# Do the actually pushing following
      - name: Build, tag, and push image to Amazon ECR
        id: build-publish
        shell: bash
        env:
          ECR_REGISTRY: 1111111111.dkr.ecr.eu-west-1.amazonaws.com/hello-repository
          IMAGE_TAG: 00001
        run: |
          docker build "${{ inputs.docker_build_dir }}" -f "${{ inputs.path_to_dockerfile }}" -t "$ECR_REGISTRY:$IMAGE_TAG"
          docker push "$ECR_REGISTRY:$IMAGE_TAG"
          echo "IMAGE $IMAGE_TAG is pushed to $ECR_REGISTRY"
          echo "image_tag=$IMAGE_TAG"
          echo "full_image=$ECR_REGISTRY:$IMAGE_TAG"
permissions:
  id-token: write # required to issue a Github JWT to use against AWS
  contents: read # to actually read the repo to build your code
```

#### Example configuration `Identity Provider - Github OIDC`

This is an example from typescript using the [AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/work-with-cdk-typescript.html), within a CDK Stack

```typescript
const githubAuthProvider = new cdk.aws_iam.OpenIdConnectProvider(
  this,
  "GithubActions",
  {
    url: "https://token.actions.githubusercontent.com",
    clientIds: ["sts.amazonaws.com"],
    thumbprints: ["74f3a68f16524f15424927704c9506f55a9316bd"], // Found by hand following https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  }
);
```

#### Example configuration `Github Assumed role - GithubRole`

This is an example from typescript using the [AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/work-with-cdk-typescript.html), within a CDK Stack

This would allow all github workflows for all repos in your Github Organisation `example-org` to assume suitably tagged roles, regardless of account.

```typescript
const githubActionsRole = new cdk.aws_iam.Role(this, "GithubActionsRole", {
  roleName: "GithubActionsRole", // Must be static to make cross account auth easier
  assumedBy: new cdk.aws_iam.PrincipalWithConditions(
    new cdk.aws_iam.WebIdentityPrincipal(
      `arn:aws:iam::${this.account}:oidc-provider/token.actions.githubusercontent.com`
    ),
    // It's important that this role is locked down to only our github orgs, as otherwise anyone on github could use permissions on our AWS infrastructure.
    {
      StringEquals: {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      },
      StringLike: {
        "token.actions.githubusercontent.com:sub": "repo:example-org/*", // This currently allows all repos in the example-org github org to assume this role.
      },
    }
  ),
});
githubActionsRole.addToPolicy(
  new cdk.aws_iam.PolicyStatement({
    effect: cdk.aws_iam.Effect.ALLOW,
    actions: ["sts:AssumeRole"],
    resources: ["*"],
    // This should only be allowed to assume other roles that explicitly opt in via the tag below.
    // Prevents this role being able to assume every role in the shared-services account
    conditions: {
      StringEquals: {
        "iam:ResourceTag/example:allow-example-org-github-access": "true",
      },
    },
  })
);
```

#### Example configuration - `Team managed role - DevelopmentDeployerRole`

This is an example from typescript using the [AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/work-with-cdk-typescript.html), within a CDK Stack

```typescript
// For the assumeRoleChain
const githubActionsRole = new cdk.aws_iam.Role(
  this,
  "DevelopmentDeployerRole",

  {
    roleName: "DevelopmentDeployerRole", // Must be static since it's referenced in GitHub Actions resources
    assumedBy: new cdk.aws_iam.PrincipalWithConditions(
      new cdk.aws_iam.ArnPrincipal(
        "arn:aws:sts::0000000000:assumed-role/GithubRole/GitHubActions"
      ),
      {
        // Able to add conditions here to limit to specific repos / workflows
        StringLike: {
          "token.actions.githubusercontent.com:sub":
            "repo:example-org/repo-frontend/*", // This allows workflows from only the `repo-frontend` repo in the example-org organisation to assume the role via the chaining.
        },
      }
    ),
  }
);
// Github Action role limited to only assume roles with this tag
cdk.Tags.of(githubActionsRole).add(
  "example:allow-example-org-github-access",
  "true"
);

// now actually add the permissions you want this role to have
```
