
function Get-WebListsFields {
    param (
        $Web,
        $conn
    )
    Write-Host "Processing Web:" $web -BackgroundColor Magenta

    # To exclude the those lists that may not need to be cared about: Hidden lists/system lists/Lists with no items/known lists that we don't need to care about.
    $Lists = Get-PnPList -Web $Web -Includes IsSystemList | where-object {
        $_.Hidden -eq $false -and
        $_.IsSystemList -eq $false -and
        $_.ItemCount -gt 0 -and
        $_.Title -ne "Content and Structure Reports" -and
        $_.Title -ne "Reusable Content"
    }
    # Print the numbers of lists in the current web which will be processed.
    Write-Host "Number of Lists: " $lists.count -BackgroundColor Red

    $AllFields = @()

    foreach ($List in $Lists) {
        $ListID = $List.Id
        $ListTitle = $List.Title
        $ListUrl = $List.RootFolder.ServerRelativeUrl

        Write-Host "Processing List: $ListTitle"`n$ListUrl -BackgroundColor DarkCyan
        # Include only the "Lookup" fields and those fields must have a lookuplist with a list ID.
        $Fields = Get-PnPField -List $ListID -Web $Web | Where-Object {
            $_.FieldTypeKind -eq "Lookup" -and $_.LookupList -match "{.*}"
        }

        $LookupFields = @()

        foreach ($Field in $Fields) {
            Write-Host "Processing Field:" $Field.Title    

            $LookupWebId = $Field.LookupWebId

            $Obj = New-Object PSCustomObject -Property @{
                ListTitle = $ListTitle
                ListRelativeUrl = $ListUrl
                Title = $Field.Title
                InternalName = $Field.InternalName
                LookupField = $Field.LookupField
                # The point here is to use -Web to specify the web from where to query the lookup list. This is to export the Title of the lookup list, easy for engineers to find.
                LookupListTitle = (Get-PnPList -Identity $Field.LookupList -Web $LookupWebId).Title
                LookupListID = $Field.LookupList
                # The point here is to get the ServerRelativeUrl for a list, you MUST use .RootFolder.ServerRelativeUrl to get it.
                LookupListUrl = (Get-PnPList -Identity $Field.LookupList -Web $LookupWebId).RootFolder.ServerRelativeUrl
                LookupWebId = $LookupWebId
                FieldTypeKind = $Field.FieldTypeKind
            }
            $LookupFields += $Obj
        }
        $AllFields +=$LookupFields
        $LookupFields
    }
}


function Get-LookupColumn {
    param (
        [string]$Site,
        [string]$ReportFolder
    )
    
    $logName = "Transcript_$($site.Split('/')[-1])_$((Get-Date).ToString('MM-dd_hhmmss')).log"
    $logPath = Join-Path $ReportFolder $logName

    $ReportName = "LookupColumns_$($site.Split('/')[-1])_$((Get-Date).ToString('MM-dd')).csv" 
    $ReportPath = Join-Path $ReportFolder $ReportName

    Start-Transcript -Path $logPath -NoClobber

    Connect-PnPOnline -Url $Site -UseWebLogin
    
    $conn = Connect-PnPOnline -Url $site -UseWebLogin

    Get-WebListsFields -Web (Get-PnPWeb).ServerRelativeUrl | Select-Object ListTitle,ListRelativeUrl,Title,InternalName,LookupField,LookupListTitle,LookupListUrl,LookupListID,LookupWebId,FieldTypeKind | Export-Csv -Path $ReportPath -Encoding UTF8 -NoTypeInformation

    if (Get-PnPSubWebs) {
        [array]$SubWebs = Get-PnPSubWebs -Recurse
        foreach ($SubWeb in $Subwebs) {
            Get-WebListsFields -Web $SubWeb.ServerRelativeUrl | Export-Csv -Path $ReportPath -Encoding UTF8 -Append -NoTypeInformation
        }
    }
    # Do NOT forget to disconnect the connection to release the resources or you might run into issues logging into sites.
    Disconnect-PnPOnline -Connection $conn
    Stop-Transcript
}

# Get-ListLookupColumn -Site https://sapagrp.sharepoint.com/sites/profiles_ehsna -ReportFolder C:\Users\ricky\Desktop\PS\Get-LookupColumn