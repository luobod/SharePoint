# Example Below:
# Compare-ListInfo -MappingFilePath .\Compare-ListInfo\Batch_05.csv -ListsPath .\Compare-ListInfo -ReportPath .\B05\B05_Reports

function Compare-GroupInfo {
    param (
        [string]$MappingFilePath,
        [string]$ListsPath,
        [string]$ReportPath = $ListsPath
    )
    $Mappings = Import-Csv $MappingFilePath -Encoding UTF8

    foreach ($mapping in $Mappings) {
        $src = $mapping."migrate from".split("/",5)[-1]
        write-host "Source Site: $src"
        $dst = $mapping."migrate To".split("/",5)[-1]
        write-host "Destination Site: $dst"
    
        $srcCsv = Import-Csv (join-path $ListsPath *$src*.csv) -Encoding UTF8
        $dstCsv = Import-Csv (join-path $ListsPath *$dst*.csv) -Encoding UTF8
    
        $ReportName = "Group_Src_'$Src'_Dst_'$Dst'_$((Get-Date).ToString('MMdd')).csv"
        $ReportFile = Join-Path $ReportPath $ReportName
        write-host "Report Name: $ReportName"
    
        $Report = @()
        foreach ($R in $SrcCsv) {
            #$RefUrl =  $r.ServerRelativeUrl.Split("/",4)[-1]
            $obj = [PSCustomObject]@{
                Src_Title = $R.Title
                Dst_Title = ""
                Src_LoginName = $R.LoginName
                Dst_LoginName = ""
                Src_RootWebPermissions = $R.RootWebPermissions
                Dst_RootWebPermissions = ""
                Src_OwnerTitle = $R.OwnerTitle
                Dst_OwnerTitle = ""
                Src_OnlyAllowMembersViewMembership = $R.OnlyAllowMembersViewMembership
                Dst_OnlyAllowMembersViewMembership = ""
                Src_AllowMembersEditMembership = $R.AllowMembersEditMembership
                Dst_AllowMembersEditMembership = ""
                Src_AllowRequestToJoinLeave = $R.AllowRequestToJoinLeave
                Dst_AllowRequestToJoinLeave = ""
                Src_AutoAcceptRequestToJoinLeave = $R.AutoAcceptRequestToJoinLeave
                Dst_AutoAcceptRequestToJoinLeave = ""
            }

            foreach ($D in $DstCsv) {
                if ($R.Title -eq $D.Title) {
                    $Obj.Dst_LogInName = $D.LoginName
                    $Obj.Dst_Title = $D.Title
                    $Obj.Dst_RootWebPermissions = $D.RootWebPermissions
                    $Obj.Dst_OwnerTitle = $D.OwnerTitle
                    $Obj.Dst_OnlyAllowMembersViewMembership = $D.OnlyAllowMembersViewMembership
                    $Obj.Dst_AllowMembersEditMembership = $D.AllowMembersEditMembership
                    $Obj.Dst_AllowRequestToJoinLeave = $D.AllowRequestToJoinLeave
                    $Obj.Dst_AutoAcceptRequestToJoinLeave = $D.AutoAcceptRequestToJoinLeave
                }
            }
            $report += $obj
        }
        $Report | Export-Csv $ReportFile -NoTypeInformation -Encoding utf8
    }
}