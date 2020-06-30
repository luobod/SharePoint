function Get-WebListInfo {
    param (
        [string]$WebUrl,
        $conn
    )
    # Using this report name will put all the list information of the site collection into one report. If you want each subweb to have a individual report, you can add_hhmmss to the end of the reprot file.
    #$reportName = "ListInfo_$($site.Split('/')[-1])_$((Get-Date).ToString('MM-dd')).csv" 
    #$reportPath = Join-Path $ReportPath $reportName

    $lists = Get-PnPList -Web $WebUrl -Connection $conn | Where-Object {
        $_.Hidden -eq $false -and $_.Title -ne "MicroFeed" -and $_.Title -ne "Style Library"
    }

    $listInfo = @()
    foreach ($list in $lists) {
        $obj = New-Object -TypeName PSCustomObject
        # If you want more properties of list, add them here.
        $obj | Add-Member -MemberType NoteProperty -Name ServerRelativeUrl -Value $list.RootFolder.serverRelativeUrl    
        $obj | Add-Member -MemberType NoteProperty -Name Title -Value $list.Title
        $obj | Add-Member -MemberType NoteProperty -Name ItemCount -Value $list.ItemCount
        $obj | Add-Member -MemberType NoteProperty -Name DefaultViewUrl -Value $list.DefaultViewUrl

        $listInfo += $obj
    }
    # Put all the lists of the current site collection in the same report file. If you want each site to have a individual report, you can add the time stamp to the file name.
    $listInfo #| Export-Csv $reportPath -NoTypeInformation -Encoding UTF8
 }

function Get-SiteListInfo {
    param (
        $site
        # The only purpose of passing $site is used for setup the connection.
    )
    $logName = "Transcript_$($site.Split('/')[-1])_$((Get-Date).ToString('MM-dd_hhmmss')).log"
    $logPath = Join-Path $ReportPath $logName
   
    $reportName = "ListInfo_$($site.Split('/')[-1])_$((Get-Date).ToString('MM-dd')).csv" 
    $OutputPath = Join-Path $ReportPath $reportName

    # Generate Logs
    Start-Transcript -Path $logPath -NoClobber
    
    $conn = Connect-PnPOnline -Url $site -UseWebLogin
    # Removed all -conn $conn, the script seems faster.
    Get-WebListInfo -WebUrl (Get-PnPWeb).serverRelativeUrl | Export-Csv -Path $OutputPath -Encoding UTF8 -NoTypeInformation

    if (Get-PnPSubWebs) {
        [array]$subWebs = Get-PnPSubWebs -Recurse
        foreach ($web in $subwebs) {
            Get-WebListInfo -WebUrl $web.serverRelativeUrl | Export-Csv -Path $OutputPath -Encoding UTF8 -Append -NoTypeInformation
        }
    }

    Disconnect-PnPOnline -Connection $conn

    Stop-Transcript
}

function Get-ListInfo {
    param (
        [string]$CsvPath,
        [string]$CsvHeader,
        [string]$ReportPath
    )

    $sites = Import-Csv -Path $CsvPath -Encoding UTF8

    foreach ($site in $sites) {
        Get-SiteListInfo -site $site.$CsvHeader
    }
}

# Example Below:
# Get-ListInfo -CsvPath "C:\Users\ricky\Desktop\Get-ListItemCount\Batch_05B.csv" -CsvHeader "migrate from" -ReportPath "C:\Users\ricky\Desktop\Get-ListItemCount\Test"