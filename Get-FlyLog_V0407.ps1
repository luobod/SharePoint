
Function Search-FlyLog($Path,$Pattern) {
    Get-ChildItem $path -Recurse | Select-String -Pattern $pattern -Encoding utf8 | Select-Object LineNumber,Path | ft -AutoSize -Wrap
}


Function Get-FLYLog([string]$jobID){

    $logPath = "$env:programfiles\APElements\FLY\Agent\Logs"
    $jobPath = "$env:programfiles\APElements\FLY\Agent\jobs"

    $destPath = "$env:HOMEPATH\Desktop\$jobid.zip"

    $logs = Get-ChildItem -Path $logPath\* -Include *$jobID*
    $jobs = Get-ChildItem  -Path $jobPath | Where-Object {$_.Name -match $jobid}

    Write-Host "Getting Logs..."
    $logs | Compress-Archive -DestinationPath $destPath -Update
    Write-Host "Getting Jobs..."
    $jobs | Compress-Archive -DestinationPath $destPath -Update
    Write-Host "Got Logs and Jobs in $destPath"
    sleep 1
    Write-Host "Copying Logs and Jobs to clipboard..."
    Set-Clipboard -Path $destPath
    sleep 1
    Write-Host "Opening Logs and Jobs..."
    explorer $destPath

}