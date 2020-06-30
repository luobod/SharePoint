function Get-ActualItemCount {
    param (
        [string]$TenantName,
        [string]$WebRelativeUrl,
        [string]$ListName
    )
    $TenantUrl = -join("https://",$TenantName,".sharepoint.com")

    $WebUrl = -join($TenantUrl,$WebRelativeUrl)
    Connect-PnPOnline -Url $WebUrl -UseWebLogin
    Get-PnPListItem -List $ListName -PageSize 5000 | Measure-Object
    Disconnect-PnPOnline
}