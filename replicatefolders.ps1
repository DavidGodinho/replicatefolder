param (
    [string]$SourcePath,
    [string]$ReplicaPath,
    [string]$LogFilePath
)

function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Write-Output $logEntry
    Add-Content -Path $LogFilePath -Value $logEntry
}

# Validate paths
if (-not (Test-Path -Path $SourcePath)) {
    Log-Message "ERROR: Source path '$SourcePath' is missing."
    exit 1
}

if (-not (Test-Path -Path $ReplicaPath)) {
    Log-Message "INFO: Replica path '$ReplicaPath' is missing. You should create one in the case it does not exist."
    New-Item -ItemType Directory -Force -Path $ReplicaPath | Out-Null
}

# Synchronize the folders
$sourceFiles = Get-ChildItem -Path $SourcePath -Recurse
$replicaFiles = Get-ChildItem -Path $ReplicaPath -Recurse

# Copy the files from source to replica folders
foreach ($sourceFile in $sourceFiles) {
    $relativePath = $sourceFile.FullName.Substring($SourcePath.Length)
    $replicaFilePath = Join-Path $ReplicaPath $relativePath

    if (-not (Test-Path -Path $replicaFilePath) -or (Get-Item $sourceFile.FullName).LastWriteTime -gt (Get-Item $replicaFilePath).LastWriteTime) {
        # Make sure the directory exists
        $replicaDir = Split-Path $replicaFilePath -Parent
        if (-not (Test-Path -Path $replicaDir)) {
            New-Item -ItemType Directory -Force -Path $replicaDir | Out-Null
        }
        # Copy
        Copy-Item -Path $sourceFile.FullName -Destination $replicaFilePath -Force
        Log-Message "Copied/Updated: $replicaFilePath"
    }
}

# Remove files in replica that are not in source which is done so that the replica folder is an exact match at the point the script runs
foreach ($replicaFile in $replicaFiles) {
    $relativePath = $replicaFile.FullName.Substring($ReplicaPath.Length)
    $sourceFilePath = Join-Path $SourcePath $relativePath

    if (-not (Test-Path -Path $sourceFilePath)) {
        Remove-Item -Path $replicaFile.FullName -Force
        Log-Message "Removed: $replicaFile.FullName"
    }
}

Log-Message "Synchronization completed."