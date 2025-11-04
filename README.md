# Commit to Repo Extension

[![Visual Studio Marketplace Version](https://img.shields.io/visual-studio-marketplace/v/mightoraio.mightora-commit-to-repo-extension?label=VS%20Marketplace)](https://marketplace.visualstudio.com/items?itemName=mightoraio.mightora-commit-to-repo-extension)
[![Visual Studio Marketplace Installs](https://img.shields.io/visual-studio-marketplace/i/mightoraio.mightora-commit-to-repo-extension)](https://marketplace.visualstudio.com/items?itemName=mightoraio.mightora-commit-to-repo-extension)
[![Visual Studio Marketplace Rating](https://img.shields.io/visual-studio-marketplace/r/mightoraio.mightora-commit-to-repo-extension)](https://marketplace.visualstudio.com/items?itemName=mightoraio.mightora-commit-to-repo-extension)

An Azure DevOps extension that automates committing changes made during pipeline runs directly to your Git repository.

## Overview

The Commit to Repo Extension streamlines your CI/CD workflows by automatically staging, committing, and pushing changes made during your Azure DevOps pipeline execution. Perfect for automated documentation updates, generated files, version bumps, and more.

## Key Features

✅ **Automated Git Commits** - Stage and commit all modifications during pipeline runs  
✅ **Selective Folder Commits** - Target specific folders or commit all changes  
✅ **Secure Authentication** - Uses pipeline's `System.AccessToken` for authentication  
✅ **Customizable Commit Messages** - Specify custom messages via task parameters  
✅ **Branch Management** - Create or checkout target branches automatically  
✅ **Tag Support** - Add tags to your commits  

## Quick Start

```yaml
- task: mightoraCommitToRepo@2
  inputs:
    commitMsg: "Automated commit from pipeline"
    branchName: "main"
    targetFolder: "docs"  # Optional: commit specific folder only
```

## Documentation

For complete documentation, examples, and detailed usage instructions, see:

📖 **[Full Documentation (details.md)](src/details.md)**

## Installation

Install from the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=mightoraio.mightora-commit-to-repo-extension)

## Support

- 🌐 Website: [mightora.io](https://mightora.io)
- 🐛 Issues: [GitHub Issues](https://github.com/mightora/DevOpsExtension-Commit-To-Repo/issues)
- 📧 Contact: Visit [mightora.io](https://mightora.io) for support

## License

See [LICENSE](LICENSE) file for details.

---

**Created by Mightora**
