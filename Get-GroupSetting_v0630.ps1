# All SharePoint Groups are in the same site collections, no matter you created it from the root web or a subweb.
# So all we need to do is pull the groups from the site collections and export the information to a .CSV file.
#

function Get-GroupSetting {
    param (
        [string]$Site,
        [string]$ReportPath
    )
    
    Connect-PnPOnline -Url $Site -UseWebLogin
    $ReportName = "Group_Report_$($Site.Split('/')[-1])_$((Get-Date).ToString('MMdd_hhmmss')).csv" 

    $Groups = (Get-PnPGroup).Where({$_.LoginName -notmatch "SharingLinks."})

    $AllGroupInfo = @()

    foreach ($Group in $Groups) {
        $GroupSetting = Get-PnPGroup -Identity $Group.LoginName

        $GroupPerms = (Get-PnPGroupPermissions -Identity $Group.LoginName -ErrorAction SilentlyContinue).where({$_.Hidden -eq $false})
        $GroupPermToString = $GroupPerms.Name -join "; "

        $Obj = [PSCustomObject]@{
            Title = $GroupSetting.Title
            LoginName = $GroupSetting.LoginName
            # Group Owner
            OwnerTitle = $GroupSetting.OwnerTitle
            # Who Can View The Membership of the group?
            OnlyAllowMembersViewMembership = $GroupSetting.OnlyAllowMembersViewMembership
            # Who Can edit the membership of the group?
            AllowMembersEditMembership = $GroupSetting.AllowMembersEditMembership
            # Allow requests to join/leave this group?
            AllowRequestToJoinLeave = $GroupSetting.AllowRequestToJoinLeave
            # Auto-accept requests?
            AutoAcceptRequestToJoinLeave = $GroupSetting.AutoAcceptRequestToJoinLeave
            # Root Web Permissions
            RootWebPermissions = $GroupPermToString
        }
        $AllGroupInfo += $Obj
    }
    $AllGroupInfo | Export-Csv $ReportPath\$ReportName -Encoding UTF8 -NoTypeInformation

    Disconnect-PnPOnline
}


function Get-GroupInfo {
    param (
        [string]$MappingFilePath,
        [string]$CsvHeader,
        [string]$ReportPath = "."
    )

    $SiteMappings = Import-Csv -Path $MappingFilePath -Encoding UTF8

    foreach ($Mapping in $SiteMappings) {
        write-host "Processing:" $Mapping.$CsvHeader
        Get-GroupSetting -Site $Mapping.$CsvHeader -ReportPath $ReportPath
    }
}