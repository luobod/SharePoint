function Remove-RoleAssignment {
    param (
        [string]$WebUrl
    )
    Connect-PnPOnline -Url $WebUrl -UseWebLogin
    # Get the Role assignments of the web
    $Web = Get-PnPWeb -Includes RoleAssignments

    # Put all the role assignments to delete in a new collection ($RaToDelete) because we cannot delete objects in a collection inside a foreach loop.
    $RaToDelete = @()
    foreach ($RA in $Web.RoleAssignments) {
        $RaToDelete += $RA
    }
    # Delete the role assignments
    foreach ($RA in $RaToDelete) {
        $Member = $RA.Member
        $loginName = Get-PnpProperty -ClientObject $Member -Property LoginName
    
        Write-Host "Deleting:" $loginName`n

        try {
            $RA.DeleteObject()
            Invoke-PnPQuery
        }
        catch {
            $_.Exception.Message
        }
    }
    #Disconnect PnpOnine to save resouce.
    Disconnect-PnPOnline
}



# Clear the permissions for the archive webs.
function Clear-Permission {
    param (
        [string]$BatchFilePath
    )

    $WebUrls = (Import-Csv $BatchFilePath -Encoding UTF8).where({$_."Migration Type" -eq "Archive"})."Migrate To"

    foreach ($WebUrl in $WebUrls) {
        Connect-PnPOnline -Url $WebUrl -UseWebLogin
        $Web = Get-PnPWeb -Includes RoleAssignments,HasUniqueRoleAssignments

        if ($Web.HasUniqueRoleAssignments -eq $true) {
            Write-Host "$WebUrl has UNIQUE permissions, start to clear the permissions." -ForegroundColor Yellow
            Remove-RoleAssignment -WebUrl $Web.Url
        }
        else {
            Write-Host "$WebUrl has inherited permissions, breaking the inheritance." -ForegroundColor Yellow
            $web.BreakRoleInheritance($false,$true)
            Invoke-PnPQuery

            Write-Host "Clearing permissions" -ForegroundColor Yellow
            Remove-RoleAssignment -WebUrl $Web.Url
        }  
    }
}