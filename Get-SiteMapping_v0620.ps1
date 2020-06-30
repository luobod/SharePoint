# Purpose of this script: generate a CSV file for creating migration plan in FLY
# Requirements: you need to use Get-Batch to export the site mappings for each batch, then feed Get-SiteMapping with the CSV file;
# Output: Get-SiteMapping will generate a CSV file contains only the site collection mappings, also provide some arguments which will be used when creating the migration plans;

function Connect-Sapa {
    param (
    )
    Connect-PnPOnline -url "https://sapagrp-admin.sharepoint.com" -UseWebLogin
}

function Get-SapaSiteSize {
    param (
        $SiteCollectionUrl
    )
    $Size = ((Get-PnPTenantSite -Url $SiteCollectionUrl).StorageUsage)/1024
    [math]::Round($Size,2)
}

function Get-SiteMapping {
    param (
        [string]$OldMapping#,
        #[string]$ExportPath
    )
    $csv = Import-Csv $OldMapping -Encoding UTF8
    # 2020/05/05: Set report path to user's desktop
    $ReportPath = Join-Path $env:HOMEPATH \Desktop\Mappings_$((Get-Date).ToString("yyyy_MMdd")).csv

    connect-sapa

    $Mappings = @()
   
    foreach ($item in $csv) {
        # To detect how many "/" are there in the URL, refer to [[https://dinushaonline.blogspot.com/2014/04/powershell-count-occurrences-of.html]]
        $slashCount = ($item."migrate from".ToCharArray() | Where-Object {$_ -eq '/'}).count
        if ($slashCount -gt 4){
            $StringToRemove = "/" + $item.'Migrate From'.Split("/",6)[-1]
            
            # 2020/05/04 Fixed the bug by using Substring not replace, replace can make mistake when the strings that you want to remove exist more than 1 time.
            #$srcSite = $item.'Migrate From'.Replace($StringToRemove,"")
            $srcSite = $item.'Migrate From'.substring(0, $item.'Migrate From'.Length - $StringToRemove.Length)
            #$dstSite = $item.'Migrate To'.Replace($StringToRemove,"")
            $dstSite = $item.'Migrate To'.substring(0, $item.'Migrate To'.Length - $StringToRemove.Length)

            Write-Host "Processing" $item.'Migrate From'
            $obj = New-Object PSCustomObject -Property @{
                "Migrate From" = $srcSite
                "Object Level" = "SiteCollection"
                "Migrate To" = $dstSite
                "Dest_Object Level" = "SiteCollection"
                "Method" = "Combine"
                # 2020/05/04 Added Batch column
                "Batch" = $item.Batch
            }
        }else {
            $srcSite = $item.'Migrate From'.TrimEnd("/")
            Write-Host "Processing" $item.'Migrate From'
            $obj = New-Object PSCustomObject -Property @{
                "Migrate From" = $srcSite
                "Object Level" = "SiteCollection"
                "Migrate To" = $item.'Migrate To'.TrimEnd("/")
                "Dest_Object Level" = "SiteCollection"
                "Method" = "Combine"
                # 2020/05/04 Added Batch column
                "Batch" = $item.Batch
            }
        }
        $Mappings += $obj
    }

    # 2020/05/04 Added deduplicate logic.
    $Dedup = $mappings | Select-Object * -Unique

# After we get only the site Urls, then we get the storage usage for each site.
    $NewCsv = @()
    # Index for the site collection mappings. This value will be used as the sequence of the plans.
    $i = 1

    foreach ($Mapping in $Dedup) {
        $SrcSite = $Mapping.'Migrate From'.trim()
        $PlanSeq = '{0:D2}' -f $i
        $Batch = "B".ToUpper() + $Mapping.Batch
        # Added 2020/06/20, to reduce the times of pulling site info.
        $TenantSiteInfo = Get-PnPTenantSite -Url $SrcSite

        $StorageUsage = $TenantSiteInfo.StorageUsage/1024
        $RoundResult = [math]::Round($StorageUsage,2)
        # Added DenyAddAndCustomizePages property on April 7, 2020. Fixed bug 2020/05/05
        # $DenyAddAndCustomizePages = (Get-PnPTenantSite -Url $SrcSite).DenyAddAndCustomizePages

        $obj = New-Object pscustomobject -Property @{
            "Migrate From" = $SrcSite #$Mapping.'Migrate From'
            "Object Level" = "SiteCollection"
            "Migrate To" = $Mapping.'Migrate To'
            "Dest_Object Level" = "SiteCollection"
            "Method" = "Combine"
            "StorageUsageInGB" = $RoundResult
            "DenyAddAndCustomizePages" = $TenantSiteInfo.DenyAddAndCustomizePages
            CommentsOnSitePagesDisabled = $TenantSiteInfo.CommentsOnSitePagesDisabled
            LastContentModifiedDate = $TenantSiteInfo.LastContentModifiedDate
            Template = $TenantSiteInfo.Template
            WebsCount = $TenantSiteInfo.WebsCount
            # Added another column on April 9, 2020. Updated on May 4, 2020
            "Plan" = "P".ToUpper() + $PlanSeq
            # Added more columns on May 4, 2020
            "Batch" = $Batch
            # Modified on May 5, 2020
            "FlyDB" = "FLY_" + $Batch
            "FlyPolicy" = $Batch + "_Full"
        }
        $NewCsv += $obj
        $i ++
    }

    Disconnect-PnPOnline

    $NewCsv | select-object "Migrate From","Object Level","Migrate To","Dest_Object Level","Method","Batch","Plan","FlyDB","FlyPolicy","StorageUsageInGB","DenyAddAndCustomizePages","WebsCount","Template","CommentsOnSitePagesDisabled","LastContentModifiedDate" -Unique | Export-Csv -Encoding UTF8 -NoTypeInformation $ReportPath #$ExportPath\"Mapping_$((Get-Date).ToString('MM-dd_hhmm')).csv" 
    Set-Clipboard -Path $ReportPath
    Write-Host "Mapping File Path:" $ReportPath
    Write-Host "Mapping File has been Copied to Clipboard!" -ForegroundColor Cyan
}