# Reserved for instructions
#
function Move-SpoFile {
    param (
        [string]$WebUrl,
        [string]$FlyReportPath,
        [string]$LogFolder
    )

    $SitePath = $WebUrl.Split("/",6)[4]
    Start-Transcript -Path $LogFolder\Logs_$SitePath.log -NoClobber

    Connect-PnPOnline -Url $WebUrl -UseWebLogin
    
    $Csv = Import-Csv $FlyReportPath -Encoding UTF8

    $Documents = $csv | Where-Object {
        $_.type -eq "Document" -and $_.'Target Url' -match $WebUrl
    }

    foreach ($Doc in $Documents) {
        $From = -join("/sites/$SitePath/",$Doc.'Target Url'.split("/",6)[-1])
        $To = -join("/sites/$SitePath/",$doc.'Source Url'.split("/",6)[-1])

        Write-Host "From:" $From -ForegroundColor yellow
        Write-Host "To  :" $To -ForegroundColor Green

        if($To -ne $From) {
            try{
                Move-PnPFile -ServerRelativeUrl $From -TargetUrl $To -Force
            }
            catch{
                Write-host "Error moving:" $(-join($TenantPath,$From))
                $_.exception.message
            }
        }
        else {
            Write-Host "======URL Correct======" $(-join($TenantPath,$From))
        }
    }

    Disconnect-PnPOnline

    Stop-Transcript
}
