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

# Get inputs from the task
$commitMsg = Get-VstsInput -Name 'commitMsg'
$branchName = Get-VstsInput -Name 'branchName'
$tags = Get-VstsInput -Name 'tags'
$targetFolder = Get-VstsInput -Name 'targetFolder'
$createOrphanBranch = Get-VstsInput -Name 'createOrphanBranch' -AsBool
$pushStrategy = Get-VstsInput -Name 'pushStrategy'

Write-Output "Commit all changes"

Write-Output "Working Directory: $(Get-Location)"

cd $env:Build_SourcesDirectory

Write-Output "Working Directory Updated to: $(Get-Location)"

# Accessing pipeline variables
$userEmail = $env:BUILD_REQUESTEDFOREMAIL
$userName = $env:BUILD_REQUESTEDFOR
$accessToken = $env:SYSTEM_ACCESSTOKEN

# Check if $userEmail is null or empty, and assign a default value if it is
if ([string]::IsNullOrEmpty($userEmail)) {
    $userEmail = "no.email.in.pipeline.variables@mightora.io"
}

# Check if $userName is null or empty, and assign a default value if it is
if ([string]::IsNullOrEmpty($userName)) {
    $userName = "No name in pipeline variables"
}

Write-Host "Configuring Git user.email with: $userEmail"
git config user.email "$userEmail"

Write-Host "Configuring Git user.name with: $userName"
git config user.name "$userName"

# Determine branch creation strategy
if (![string]::IsNullOrEmpty($targetFolder) -and $createOrphanBranch) {
    Write-Host "Creating ORPHAN branch '$branchName' - will contain ONLY specified folders with no history"
    
    # Create an orphan branch (starts with no files, no history)
    git checkout --orphan $branchName
    
    # Remove all files from staging area
    Write-Host "Clearing staging area..."
    git rm -rf --cached . 2>&1 | Out-Null
    
} else {
    Write-Host "Creating/checking out branch '$branchName'"
    # Try to checkout the specified branch, create it if it doesn't exist (normal branch)
    $checkoutResult = git checkout -b $branchName 2>&1
    # If branch already exists, just switch to it
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Branch may already exist, switching to it..."
        git checkout $branchName 2>&1 | Out-Null
    } else {
        Write-Host "Created new branch '$branchName'"
    }
}

# Stage changes - either from specific folders or all changes
if (![string]::IsNullOrEmpty($targetFolder)) {
    if ($createOrphanBranch) {
        Write-Host "Adding ONLY specified folder(s) to orphan branch"
    } else {
        Write-Host "Targeting specific folder(s) for commit - ONLY these folders will be committed"
        # Reset the staging area to ensure we start clean
        git reset
    }
    
    # Split by comma to support multiple folders
    $folders = $targetFolder -split ',' | ForEach-Object { $_.Trim() }
    
    # Process each folder
    foreach ($folder in $folders) {
        if (![string]::IsNullOrEmpty($folder)) {
            # Convert to relative path if absolute path is provided
            $relativePath = $folder
            if ([System.IO.Path]::IsPathRooted($folder)) {
                $currentDir = (Get-Location).Path
                # Make sure both paths end with a separator for consistent comparison
                if (-not $currentDir.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
                    $currentDir += [System.IO.Path]::DirectorySeparatorChar
                }
                if ($folder.StartsWith($currentDir)) {
                    # Remove the current directory from the target folder path
                    $relativePath = $folder.Substring($currentDir.Length)
                } else {
                    # If not under current directory, use as-is (Git will handle it)
                    $relativePath = $folder
                }
            }
            
            # Convert backslashes to forward slashes for Git
            $relativePath = $relativePath -replace '\\', '/'
            
            # Remove leading/trailing slashes
            $relativePath = $relativePath.Trim('/')
            
            Write-Host "Staging changes from folder: $relativePath"
            
            # Check if folder exists and has changes
            if (Test-Path $relativePath) {
                # Add all files in this specific folder (including subdirectories)
                git add "$relativePath/"
                Write-Host "  [OK] Staged all changes in $relativePath"
            } else {
                Write-Warning "  [WARNING] Folder not found: $relativePath"
            }
        }
    }
    
    # Verify what's staged
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
    Write-Host "Staging all changes"
    git add --all
}

# Use the $commitMsg parameter for the commit message
$commitResult = git commit -m "$commitMsg" 2>&1
if ($LASTEXITCODE -ne 0) {
    if ($commitResult -like "*nothing to commit*") {
        Write-Warning "No changes to commit. Skipping commit and push."
        exit 0
    } else {
        Write-Error "Failed to commit changes: $commitResult"
        exit 1
    }
}

# Add tags if specified
if (![string]::IsNullOrEmpty($tags)) {
    $tagsArray = $tags -split ","
    foreach ($tag in $tagsArray) {
        git tag $tag.Trim()
    }
}

Write-Output "Push code to repo"

# Push changes based on selected strategy
Write-Host "Using push strategy: $pushStrategy"

switch ($pushStrategy) {
    "force" {
        Write-Host "⚠️ Force pushing to remote (will overwrite any remote changes)"
        git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin $branchName --force
    }
    "deleteAndRecreate" {
        Write-Host "Deleting remote branch '$branchName' (if exists)..."
        git push origin --delete $branchName 2>&1 | Out-Null
        Write-Host "Pushing new branch '$branchName' to remote..."
        git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin $branchName
    }
    default {
        Write-Host "Performing normal push to remote..."
        git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin $branchName
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push to remote repository"
    exit 1
}

# Push tags if specified
if (![string]::IsNullOrEmpty($tags)) {
    Write-Host "Pushing tags to remote..."
    git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin --tags
}