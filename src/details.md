# Commit to Repo Extension

[![Visual Studio Marketplace Version](https://img.shields.io/visual-studio-marketplace/v/mightoraio.mightora-commit-to-repo-extension?label=VS%20Marketplace)](https://marketplace.visualstudio.com/items?itemName=mightoraio.mightora-commit-to-repo-extension)
[![Visual Studio Marketplace Installs](https://img.shields.io/visual-studio-marketplace/i/mightoraio.mightora-commit-to-repo-extension)](https://marketplace.visualstudio.com/items?itemName=mightoraio.mightora-commit-to-repo-extension)
[![Visual Studio Marketplace Rating](https://img.shields.io/visual-studio-marketplace/r/mightoraio.mightora-commit-to-repo-extension)](https://marketplace.visualstudio.com/items?itemName=mightoraio.mightora-commit-to-repo-extension)

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

### Input Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `commitMsg` | Yes | - | The commit message for the changes |
| `branchName` | Yes | `main` | The branch name to commit to |
| `tags` | No | - | Comma-separated list of tags to add to the commit |
| `targetFolder` | No | - | Specific folder to commit changes from. If empty, all changes will be committed. Can be relative (e.g., `docs`) or absolute path (e.g., `$(Build.SourcesDirectory)/wiki-output`) |

### Example Pipeline Usage

```yaml
# Example 1: Commit all changes
- task: mightoraCommitToRepo@2
  inputs:
    commitMsg: "Automated commit from pipeline"
    branchName: "main"

# Example 2: Commit changes from specific folder (relative path)
- task: mightoraCommitToRepo@2
  inputs:
    commitMsg: "Updated documentation"
    branchName: "docs-update"
    targetFolder: "docs"

# Example 3: Commit changes from specific folder (absolute path)
- task: mightoraCommitToRepo@2
  inputs:
    commitMsg: "Updated wiki output"
    branchName: "wiki-update"
    targetFolder: "$(Build.SourcesDirectory)/wiki-output"

# Example 4: Commit with tags
- task: mightoraCommitToRepo@2
  inputs:
    commitMsg: "Release version 1.0.0"
    branchName: "main"
    tags: "v1.0.0, release"
```