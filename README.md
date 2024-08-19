Simple script file for replicating the contents of a folder with a log file recording changes. Log file is updated whenever the script finishes running.

Type: .\replicatefolders.ps1 -SourcePath "Source Folder" -ReplicaPath "ReplicaFolder" -LogFilePath "LogfilePath/logfile.txt" to run it.

"SourcePath" - Parameter representing the original file you want to commit changes to.

"ReplicaPath" - Parameter representing the file that copies the original file. It will create a new one it isn't present.

"LogFilePath" - Path where your logfile is, catalloguing the changes commited between each use of the script. If not present it will create a new log file.
