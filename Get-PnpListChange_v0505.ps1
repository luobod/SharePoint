function Get-PnpListChange {
    param (
        [string]$WebUrl,
        [string]$ListName#,
        #[string]$ReportFolder
    )
    # Special thanks to https://www.sharepointdiary.com/2018/03/sharepoint-online-get-change-log-using-powershell.html
    # Use the pnp context, so you don't need to import the dll files.
    Connect-PnPOnline -Url $WebUrl -UseWebLogin
    $Ctx = Get-PnPContext

    #Get the web
    $Web = $Ctx.Web
    $Ctx.Load($Web)
    $Ctx.ExecuteQuery()
    
    #Get the List
    $List = $Ctx.Web.Lists.GetByTitle($ListName)
    $Ctx.Load($List)
    $Ctx.ExecuteQuery()

    $ChangeQuery = New-Object Microsoft.SharePoint.Client.ChangeQuery($true,$true)
    $ChangesCollection=$List.GetChanges($ChangeQuery)
    $Ctx.Load($ChangesCollection)
    $Ctx.ExecuteQuery()
    
    #Get All Changes                
    Write-Host "Number of Changes found:" $ChangesCollection.Count -BackgroundColor Yellow

    $ReportFile = -join("ChangeLog_",$ListName,"_$((Get-Date).ToString('yyyyMMdd_hhmm')).csv")
    $ReportPath = Join-Path $env:HOMEPATH $ReportFile
    $ChangesCollection | export-csv -NoTypeInformation -Encoding UTF8 -Path $ReportPath #(join-path $ReportFolder $Report)
    Set-Clipboard -Path $ReportPath
    Write-Host "Change Log Path:" $ReportPath
    Write-Host "Change Log has been COPIED to Clipboard!" -ForegroundColor Cyan
}