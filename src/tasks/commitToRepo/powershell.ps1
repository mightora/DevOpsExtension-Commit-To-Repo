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

# Checkout the specified branch, create it if it doesn't exist
git checkout -b $branchName

# Stage changes - either from specific folders or all changes
if (![string]::IsNullOrEmpty($targetFolder)) {
    Write-Host "Targeting specific folder(s) for commit - ONLY these folders will be committed"
    
    # Reset the staging area to ensure we start clean
    git reset
    
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
                Write-Host "  ✓ Staged all changes in $relativePath"
            } else {
                Write-Warning "  ⚠ Folder not found: $relativePath"
            }
        }
    }
    
    # Verify what's staged
    Write-Host "`n=== Currently staged files (ONLY these will be committed) ==="
    $stagedFiles = git diff --cached --name-only
    if ($stagedFiles) {
        $stagedFiles | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Warning "No files are staged for commit!"
    }
    Write-Host "=========================================================`n"
    
} else {
    Write-Host "Staging all changes"
    git add --all
}

# Use the $commitMsg parameter for the commit message
git commit -m "$commitMsg"

# Add tags if specified
if (![string]::IsNullOrEmpty($tags)) {
    $tagsArray = $tags -split ","
    foreach ($tag in $tagsArray) {
        git tag $tag.Trim()
    }
}

Write-Output "Push code to repo"

# Push changes with authentication using System.AccessToken
git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin $branchName

# Push tags if specified
if (![string]::IsNullOrEmpty($tags)) {
    git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin --tags
}