# aks-deploy-source

Source repo that triggers CI/CD and fabrikate generation into next repo. An example of this destination repo is location [here](https://github.com/samiyaakhtar/aks-deploy-destination). 

# Setup

First we need to create a personal access token which will be used to push to the repository. Go to github settings > Developer settings > Personal access token. There should be a list of permissions to grant this new token, at the minimum it should have rights to read and write to a repository. Create the token and store it somewhere as you will not be able to view it again.

Setup azure pipelines on the source repository by creating a new build pipeline in Pipelines > Builds:

1. Copy the code below for `azure-pipelines.yml` into root folder of your project. 
2. Go into pipeline settings and add a new variable called `access_token` and set the value to your personal access token. Make sure the variable is set to secret. 
3. Add a variable `aks_manifest_repo` and set it to the destination repo, for eg. `samiyaakhtar/aks-deploy-destination`
4. Update the azure-pipelines.yml file to look like the following

```
trigger:
- master

pool:
  vmImage: 'Ubuntu-16.04'

steps:
- checkout: self
  persistCredentials: true
  clean: true

- bash: |
    curl $BEDROCK_BUILD_SCRIPT > build.sh
    chmod +x ./build.sh
  displayName: Download Bedrock orchestration script
  env:
    BEDROCK_BUILD_SCRIPT: https://raw.githubusercontent.com/Microsoft/bedrock/master/gitops/azure-devops/build.sh

- task: ShellScript@2
  displayName: Validate fabrikate definitions
  inputs:
    scriptPath: build.sh
  condition: eq(variables['Build.Reason'], 'PullRequest')
  env:
    VERIFY_ONLY: 1

- task: ShellScript@2
  displayName: Transform fabrikate definitions and publish to YAML manifests to repo
  inputs:
    scriptPath: build.sh
  condition: ne(variables['Build.Reason'], 'PullRequest')
  env:
    ACCESS_TOKEN_SECRET: $(ACCESS_TOKEN)
    COMMIT_MESSAGE: $(Build.SourceVersionMessage)
    AKS_MANIFEST_REPO: $(aks_manifest_repo)
```

**NOTE**: Besure to set the **aks_manifest_repo** variable value with the absolute URL to your manifest repo, (i.e. https://dev.azure.com/abrig/bedrock_gitops/_git/manifest_repo)  and the **access_token** with the personal access token you generated.

For rest of the instructions, refer to the full documentation [here](https://github.com/Microsoft/bedrock/tree/master/gitops/azure-devops)