param (
    [string]$SourcePath,
    [string]$ReplicaPath,
    [string]$LogFilePath
)

function Backup-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Write-Output $logEntry
    Add-Content -Path $LogFilePath -Value $logEntry
}

# Normalize paths to avoid issues with trailing slashes
$SourcePath = $SourcePath.TrimEnd('\')
$ReplicaPath = $ReplicaPath.TrimEnd('\')

# Create the log file in case not present
if (-not (Test-Path -Path $LogFilePath)) {
    try {
        New-Item -ItemType File -Force -Path $LogFilePath | Out-Null
        Backup-Message "INFO: Log file created at '$LogFilePath'."
    }
    catch {
        Write-Error "ERROR: Failed to create log file at '$LogFilePath'. Exception: $_"
        exit 1
    }
}

# Validate source path
if (-not (Test-Path -Path $SourcePath)) {
    Backup-Message "ERROR: Source path '$SourcePath' is missing."
    exit 1
}

# Validate or create replica path
if (-not (Test-Path -Path $ReplicaPath)) {
    Backup-Message "INFO: Replica path '$ReplicaPath' is missing. Creating directory."
    try {
        New-Item -ItemType Directory -Force -Path $ReplicaPath | Out-Null
        Backup-Message "INFO: Replica directory '$ReplicaPath' created."
    }
    catch {
        Backup-Message "ERROR: Failed to create replica directory '$ReplicaPath'. Exception: $_"
        exit 1
    }
}


# Synchronize the folders
try {
    $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse
    $replicaFiles = Get-ChildItem -Path $ReplicaPath -Recurse
}
catch {
    Backup-Message "ERROR: Failed to retrieve file lists. Exception: $_"
    exit 1
}

# Copy the files from source to replica folders
foreach ($sourceFile in $sourceFiles) {
    $relativePath = $sourceFile.FullName.Substring($SourcePath.Length)
    $replicaFilePath = Join-Path $ReplicaPath $relativePath

    if (-not (Test-Path -Path $replicaFilePath) -or (Get-Item $sourceFile.FullName).LastWriteTime -gt (Get-Item $replicaFilePath).LastWriteTime) {
        # Make sure the directory exists
        $replicaDir = Split-Path $replicaFilePath -Parent
        if (-not (Test-Path -Path $replicaDir)) {
            try {
                New-Item -ItemType Directory -Force -Path $replicaDir | Out-Null
                Backup-Message "INFO: Created directory '$replicaDir'."
                Backup-Message "INFO: Adding files to new directory '$replicaDir'."
            }
            catch {
                Backup-Message "ERROR: Failed to create directory '$replicaDir'. Exception: $_"
                continue
            }
        }
        # Copy
        try {
            Copy-Item -Path $sourceFile.FullName -Destination $replicaFilePath -Force
            Backup-Message "Copied/Updated: $replicaFilePath"
        }
        catch {
            Backup-Message "ERROR: Failed to copy $($sourceFile) to $replicaFilePath. Exception: $_"
            continue
        }
    }
}

# Remove files in replica that are not in source
foreach ($replicaFile in $replicaFiles) {
    $relativePath = $replicaFile.FullName.Substring($ReplicaPath.Length)
    $sourceFilePath = Join-Path $SourcePath $relativePath

    # Check if the parent directory still exists in the replica before attempting to remove the file
    $replicaParentDir = Split-Path $replicaFile.FullName -Parent

    if ((-not (Test-Path -Path $sourceFilePath)) -and (Test-Path -Path $replicaParentDir)) {
        try {
            Remove-Item -Path $replicaFile.FullName -Force -Recurse
            Backup-Message "Removed: $replicaFile"
        }
        catch {
            Backup-Message "ERROR: Failed to remove $($replicaFile). Exception: $_"
            continue
        }
    }
}

Backup-Message "Synchronization completed."
