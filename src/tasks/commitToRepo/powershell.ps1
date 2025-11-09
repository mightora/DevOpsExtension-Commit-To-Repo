<#
    ===========================================================
    Task: Mightora Commit To Git Repository
    
    Originally Created By: Ian Tweedie [https://iantweedie.biz] (Date: 2024-10-08)
    Date: 2024-10-08

    Contributors:
    - Developer A (Contributions: Improved Git configuration handling)
    - Developer B (Contributions: Added support for custom commit messages)
    
    ===========================================================
#>

[CmdletBinding()]

param()

# Fetch and display the developer message
function Fetch-DeveloperMessage {
    $url = "https://developer-message.mightora.io/api/HttpTrigger?appname=commitToRepo"
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        return $response.message
    } catch {
        return "Developer message not available."
    }
}

# Display the developer message
$developerMessage = Fetch-DeveloperMessage
Write-Host "Developer Message: $developerMessage"


# Output the script information at runtime
Write-Host "==========================================================="
Write-Host "Task: Mightora Commit To Git Repository"
Write-Host "Originally Created By: Ian Tweedie [https://iantweedie.biz] (Date: 2024-10-08)"
Write-Host "Contributors:"
#Write-Host " - Developer A (Contributions: Improved Git configuration handling)"
#Write-Host " - Developer B (Contributions: Added support for custom commit messages)"
Write-Host "==========================================================="
Write-Host "Please tell us what you think of this task: https://go.iantweedie.biz/mightoria-testimonials"
Write-Host "==========================================================="

# ============================================================
# STEP 1: Get inputs from the Azure DevOps task configuration
# ============================================================
$commitMsg = Get-VstsInput -Name 'commitMsg'              # The commit message text
$branchName = Get-VstsInput -Name 'branchName'            # Target branch name
$tags = Get-VstsInput -Name 'tags'                        # Optional: comma-separated Git tags
$targetFolder = Get-VstsInput -Name 'targetFolder'        # Optional: specific folder(s) to commit
$createOrphanBranch = Get-VstsInput -Name 'createOrphanBranch' -AsBool  # Create branch with no history
$pushStrategy = Get-VstsInput -Name 'pushStrategy'        # Push strategy: normal, force, or deleteAndRecreate

Write-Output "Commit all changes"

Write-Output "Working Directory: $(Get-Location)"

# Navigate to the repository root directory
cd $env:Build_SourcesDirectory

Write-Output "Working Directory Updated to: $(Get-Location)"

# ============================================================
# STEP 2: Configure Git user identity from pipeline variables
# ============================================================
# Pull user information from Azure DevOps pipeline variables
$userEmail = $env:BUILD_REQUESTEDFOREMAIL  # Email of user who triggered the pipeline
$userName = $env:BUILD_REQUESTEDFOR        # Display name of user who triggered the pipeline
$accessToken = $env:SYSTEM_ACCESSTOKEN     # Pipeline authentication token for Git operations

# Provide fallback values if pipeline variables are not available
# (This can happen in certain pipeline configurations)
if ([string]::IsNullOrEmpty($userEmail)) {
    $userEmail = "no.email.in.pipeline.variables@mightora.io"
}

if ([string]::IsNullOrEmpty($userName)) {
    $userName = "No name in pipeline variables"
}

# Configure Git with user identity (required for commits)
Write-Host "Configuring Git user.email with: $userEmail"
git config user.email "$userEmail"

Write-Host "Configuring Git user.name with: $userName"
git config user.name "$userName"

# ============================================================
# STEP 3: Checkout or create the target branch
# ============================================================
# Three different branch strategies are supported:
# 1. Orphan branch (new branch with no history) - for publishing specific folders only
# 2. Simple checkout (normal operations) - straightforward branch creation
# 3. Advanced checkout (force/delete strategies or target folders) - handles complex scenarios

if (![string]::IsNullOrEmpty($targetFolder) -and $createOrphanBranch) {
    # === ORPHAN BRANCH MODE ===
    # Creates a branch with no parent commits - useful for gh-pages or clean documentation branches
    Write-Host "========================================="
    Write-Host "BRANCH STRATEGY: ORPHAN BRANCH MODE"
    Write-Host "========================================="
    Write-Host "Creating ORPHAN branch '$branchName' - will contain ONLY specified folders with no history"
    
    # Create an orphan branch (starts with empty history)
    git checkout --orphan $branchName
    
    # Remove all files from staging area (start with a clean slate)
    Write-Host "Clearing staging area..."
    git rm -rf --cached . 2>&1 | Out-Null
    
} elseif ([string]::IsNullOrEmpty($targetFolder) -and ($pushStrategy -eq "normal" -or [string]::IsNullOrEmpty($pushStrategy))) {
    # === SIMPLE MODE (NORMAL OPERATIONS) ===
    # Most common use case: just checkout/create a branch and commit all changes
    # This matches the behavior of the original simple script
    Write-Host "========================================="
    Write-Host "BRANCH STRATEGY: SIMPLE MODE"
    Write-Host "========================================="
    Write-Host "Checking out branch '$branchName' (simple checkout)"
    git checkout -b $branchName 2>&1 | Out-Null
    
} else {
    # === ADVANCED MODE ===
    # Used when force pushing, deleting/recreating branches, or working with specific target folders
    # Requires careful branch management to avoid conflicts
    Write-Host "========================================="
    Write-Host "BRANCH STRATEGY: ADVANCED MODE"
    Write-Host "========================================="
    Write-Host "Creating/checking out branch '$branchName' (advanced mode with branch detection)"
    
    # Get current branch name (returns "HEAD" if in detached HEAD state, common in pipelines)
    $currentBranch = git rev-parse --abbrev-ref HEAD 2>&1
    
    # Optimization: Skip checkout if we're already on the target branch
    if ($currentBranch -eq $branchName) {
        Write-Host "Already on branch '$branchName'"
    } else {
        # Check if branch exists locally (suppress error output to avoid confusing messages)
        git rev-parse --verify $branchName 2>&1 | Out-Null
        $localBranchExists = ($LASTEXITCODE -eq 0)
        
        # Check if branch exists on remote origin
        # ls-remote returns data if branch exists, empty if it doesn't
        $remoteBranchCheck = git ls-remote --heads origin $branchName 2>&1
        $remoteBranchExists = ![string]::IsNullOrEmpty($remoteBranchCheck)
        
        if ($localBranchExists) {
            # Branch exists locally, just switch to it
            Write-Host "  → Route: Switching to existing local branch '$branchName'"
            git checkout $branchName 2>&1 | Out-Null
        } elseif ($remoteBranchExists) {
            # Branch exists on remote but not locally (common in Azure DevOps pipelines)
            # Create a local tracking branch from the remote branch
            Write-Host "  → Route: Branch exists on remote, creating local tracking branch '$branchName'"
            git checkout -b $branchName origin/$branchName 2>&1 | Out-Null
        } else {
            # Branch doesn't exist anywhere, create it from current HEAD
            Write-Host "  → Route: Creating new branch '$branchName' (doesn't exist locally or remotely)"
            git checkout -b $branchName 2>&1 | Out-Null
        }
    }
}

# ============================================================
# STEP 4: Stage changes for commit
# ============================================================
# Two modes: stage specific folders only, or stage all changes

if (![string]::IsNullOrEmpty($targetFolder)) {
    # === FOLDER-SPECIFIC MODE ===
    # Only commit changes from specified folder(s) - useful for monorepos or selective deployments
    Write-Host ""
    Write-Host "========================================="
    Write-Host "STAGING STRATEGY: TARGET FOLDERS"
    Write-Host "========================================="
    
    if ($createOrphanBranch) {
        Write-Host "Adding ONLY specified folder(s) to orphan branch"
    } else {
        Write-Host "Targeting specific folder(s) for commit - ONLY these folders will be committed"
        # Reset the staging area to ensure we start clean (clear any previously staged files)
        git reset
    }
    
    # Split by comma to support multiple folders (e.g., "docs,src/app")
    $folders = $targetFolder -split ',' | ForEach-Object { $_.Trim() }
    
    # Process each folder individually
    foreach ($folder in $folders) {
        if (![string]::IsNullOrEmpty($folder)) {
            # === PATH NORMALIZATION ===
            # Convert absolute paths to relative paths for Git compatibility
            $relativePath = $folder
            if ([System.IO.Path]::IsPathRooted($folder)) {
                # Folder is an absolute path (e.g., D:\a\1\s\docs)
                $currentDir = (Get-Location).Path
                # Make sure both paths end with a separator for consistent comparison
                if (-not $currentDir.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
                    $currentDir += [System.IO.Path]::DirectorySeparatorChar
                }
                if ($folder.StartsWith($currentDir)) {
                    # Remove the current directory from the target folder path to make it relative
                    $relativePath = $folder.Substring($currentDir.Length)
                } else {
                    # If not under current directory, use as-is (Git will handle it)
                    $relativePath = $folder
                }
            }
            
            # Convert Windows backslashes to Git-compatible forward slashes
            $relativePath = $relativePath -replace '\\', '/'
            
            # Remove leading/trailing slashes for clean path
            $relativePath = $relativePath.Trim('/')
            
            Write-Host "Staging changes from folder: $relativePath"
            
            # Verify folder exists before attempting to stage
            if (Test-Path $relativePath) {
                # Stage all files in this specific folder (including subdirectories)
                git add "$relativePath/"
                Write-Host "  [OK] Staged all changes in $relativePath"
            } else {
                Write-Warning "  [WARNING] Folder not found: $relativePath"
            }
        }
    }
    
    # === STAGING VERIFICATION ===
    # Display what files are staged to provide visibility before commit
    Write-Host ""
    Write-Host "=== Currently staged files (ONLY these will be committed) ==="
    $stagedFiles = git diff --cached --name-only
    if ($stagedFiles) {
        $stagedFiles | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Warning "No files are staged for commit!"
    }
    Write-Host "========================================================="
    Write-Host ""
    
} else {
    # === STAGE ALL MODE ===
    # Most common use case: commit all changes in the repository
    Write-Host ""
    Write-Host "========================================="
    Write-Host "STAGING STRATEGY: ALL CHANGES"
    Write-Host "========================================="
    Write-Host "Staging all changes in repository"
    git add --all
}

# ============================================================
# STEP 5: Create the Git commit
# ============================================================
# Commit staged changes with the provided commit message
$commitResult = git commit -m "$commitMsg" 2>&1

# Check if commit was successful
if ($LASTEXITCODE -ne 0) {
    if ($commitResult -like "*nothing to commit*") {
        # No changes detected - exit gracefully without error
        Write-Warning "No changes to commit. Skipping commit and push."
        exit 0
    } else {
        # Commit failed for another reason - exit with error
        Write-Error "Failed to commit changes: $commitResult"
        exit 1
    }
}

# ============================================================
# STEP 6: Apply Git tags (optional)
# ============================================================
# Tags are useful for marking releases or important commits
if (![string]::IsNullOrEmpty($tags)) {
    # Support multiple tags separated by commas (e.g., "v1.0.0,release")
    $tagsArray = $tags -split ","
    foreach ($tag in $tagsArray) {
        git tag $tag.Trim()
    }
}

Write-Output "Push code to repo"

# ============================================================
# STEP 7: Push changes to remote repository
# ============================================================
# Three push strategies available:
# - normal: Standard push (fails if remote has changes you don't have)
# - force: Overwrites remote branch completely (⚠️ DESTRUCTIVE)
# - deleteAndRecreate: Deletes remote branch first, then pushes (useful for clean history)

Write-Host ""
Write-Host "========================================="
Write-Host "PUSH STRATEGY: $($pushStrategy.ToUpper())"
Write-Host "========================================="

switch ($pushStrategy) {
    "force" {
        # Force push - overwrites any remote changes
        # ⚠️ WARNING: This can cause data loss for other developers!
        Write-Host "  → Route: FORCE PUSH (will overwrite any remote changes)"
        Write-Host "  ⚠️ WARNING: This is a destructive operation!"
        git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin $branchName --force
    }
    "deleteAndRecreate" {
        # Delete the remote branch first, then push as new
        # This ensures a completely clean branch on remote
        Write-Host "  → Route: DELETE AND RECREATE"
        Write-Host "Deleting remote branch '$branchName' (if exists)..."
        git push origin --delete $branchName 2>&1 | Out-Null
        Write-Host "Pushing new branch '$branchName' to remote..."
        git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin $branchName
    }
    default {
        # Normal push - will fail if remote has changes you don't have locally
        Write-Host "  → Route: NORMAL PUSH"
        git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin $branchName
    }
}

# Verify push was successful
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push to remote repository"
    exit 1
}

# ============================================================
# STEP 8: Push Git tags (optional)
# ============================================================
# Tags need to be pushed separately from commits
if (![string]::IsNullOrEmpty($tags)) {
    Write-Host "Pushing tags to remote..."
    git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin --tags
}