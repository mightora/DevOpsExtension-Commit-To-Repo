# Commit to Repo Extension
The Commit to Repo Extension is a streamlined tool designed to automate the process of committing changes made during a pipeline run to your Git repository.

**Created by:**

[![Mightora Logo](https://raw.githubusercontent.com/TechTweedie/techtweedie.github.io/main/static/logo-01_150x150.png)](https://techtweedie.github.io)

# Setup 
- Install the DevOps extension in your DevOps Organization using the **Get it free** button.
- Navigate to your pipeline.
- Add the `commitToRepo` task to your pipeline.
- Ensure your pipeline has the `System.AccessToken` variable enabled.

# Support
Please visit [mightora.io](https://mightora.io)

# Key Features 

## Commit To Git Repository

### Overview
This task automates committing changes made during a pipeline run to your Git repository, ensuring everything is pushed automatically.

### Key Features
- **Automated Git Commits**: Stages and commits all modifications to the Git repository.
- **Selective Folder Commits**: Optionally target specific folders for commits, or commit all changes.
- **Secure Authentication**: Uses the pipeline's `System.AccessToken` for authentication.
- **Customizable Commit Message**: Specify a commit message via the task's input parameters.
- **Flexible Configuration**: Set up Git configurations like user email and name.

### How to Use
1. Add the task to your Azure DevOps pipeline.
2. Specify the commit message using the `commitMsg` input.
3. Ensure your pipeline has the `System.AccessToken` variable enabled.
4. Run the pipeline to commit and push changes to the repository.

### Example Pipeline Usage

```yaml
# Commit all changes
- task: commitToRepo@1
  inputs:
    commitMsg: "Automated commit from pipeline"

# Commit changes from specific folder only
- task: commitToRepo@1
  inputs:
    commitMsg: "Updated documentation"
    targetFolder: "docs"
```