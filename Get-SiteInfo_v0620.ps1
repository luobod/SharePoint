function Get-SiteInfo {
    param (
        $SiteCsvPath
    )
    $ReportFolder = Split-Path -Path $SiteCsvPath
    $Sites = Import-Csv -Path $SiteCsvPath -Encoding UTF8

    Connect-PnPOnline -Url "https://sapagrp-admin.sharepoint.com" -UseWebLogin

    $SiteLockStates = @()

    foreach ($Site in $Sites.Url) {
        $SiteInfo = Get-PnPTenantSite -Url $Site

        $Obj = New-Object PSCustomObject -Property @{
            SiteUrl = $SiteInfo.Url
            Title = $SiteInfo.Title
            LockState = $SiteInfo.LockState
            LockIssue = $SiteInfo.LockIssue
            DenyAddAndCustomizePages = $SiteInfo.DenyAddAndCustomizePages
            CommentsOnSitePagesDisabled = $SiteInfo.CommentsOnSitePagesDisabled
            LastContentModifiedDate = $SiteInfo.LastContentModifiedDate
            Template = $SiteInfo.Template
            WebsCount = $SiteInfo.WebsCount
        }
        $SiteLockStates += $Obj
    }
    $SiteLockStates | Export-Csv $ReportFolder\SiteInfo_$((get-date).ToString("MMdd_yyyy")).csv -Encoding UTF8 -NoTypeInformation
}