
function Get-Batch {
    param (
        # Specify the batch number
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Batch
    )
    # Updated the list url on 2020/05/20
    $site = "https://nhy.sharepoint.com/sites/Team-004732/ess_o365/SPO_PBI_Track"
    $list = "Migration status"
    # 2020/05/05: Change Date format to yyyy_MMdd
    $batchPath = Join-Path $env:HOMEPATH \Desktop\Batch_$($batch)_$((Get-Date).ToString("yyyy_MMdd")).csv
    
    Connect-PnPOnline -Url $site -UseWebLogin

    $items = Get-PnPListItem -List $list
    
    $result = @()
    
    foreach ($item in $items) {
        $obj = New-Object -TypeName psobject
        if ($item["Batch_x0020_Id"].LookupValue -eq $batch) {      
            $obj | Add-Member -MemberType NoteProperty -Name "Source Mailbox" -Value $item["Source_x0020_SMTP_x0020_address"]  
            $obj | Add-Member -MemberType NoteProperty -Name "Destination Name" -Value $item["Title"]  
            $obj | Add-Member -MemberType NoteProperty -Name "Destination Mailbox" -Value $item["Destination_x0020_SMTP_x0020_add"]  
            $obj | Add-Member -MemberType NoteProperty -Name "Batch" -Value $item["Batch_x0020_Id"].LookupValue
            $obj | Add-Member -MemberType NoteProperty -Name "TeamsEnabled" -Value $item["Teams_x0020_enabled_x0020_on_x00"]  
            $obj | Add-Member -MemberType NoteProperty -Name "MigStart" -Value $item["Batch_x0020_Id_x003a_Migration_x"].LookupValue 
            $obj | Add-Member -MemberType NoteProperty -Name "MigFinish" -Value $item["Batch_x0020_Id_x003a_Migration_x0"].LookupValue  
            $obj | Add-Member -MemberType NoteProperty -Name "Migrate From" -Value $item["Source_x0020_URL"]
            $obj | Add-Member -MemberType NoteProperty -Name "Migrate To" -Value $item["Destination_x0020_Url"]
            $obj | Add-Member -MemberType NoteProperty -Name "RemovedFromBatch" -Value $item["Removed_x0020_from_x0020_batch"]
            # Added the following property on April 7, 2020
            $obj | Add-Member -MemberType NoteProperty -Name "Migration Type" -Value $item["Requested_x0020_migration_x0020_"]
        
            $result += $obj
        }
    }
    
    $result | Export-Csv $batchPath -NoTypeInformation -Encoding UTF8

    Set-Clipboard -Path $batchPath
    Write-Host "Batch_$($batch) Report Path:" $batchPath
    write-host "COPIED to Clipboard!" -ForegroundColor Cyan
    # Start-Sleep 1
    # Write-Host "Opening Logs and Jobs..."
    # explorer $batchPath
}

function Get-AllSubWebs {
    param (
        [string]$WebUrl
    )
    $conn = Connect-PnPOnline -Url $WebUrl -UseWebLogin

    Get-PnPSubWebs -Recurse -Connection $conn

    Disconnect-PnPOnline -Connection $conn
}
