# Add FLY certificate to computer or something similiar, I got this from Zhang Long.
# This is not secure, it's better you just manually import the self-assigned certificate that FLY uses to the computer, so your computer trustes the certificate.

Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Set Global Variable, so that you don't need to define it everywhere.
Set-Variable -Name FlyApiKey -Value "a1DAUuU6ZfeTXVHnXAW1f0OBRVRSN2KpIyGKRiav3BolQ1msxii9r5Hero4sGWa5" -Scope global -Option Constant
Set-Variable -Name FlyUrl -Value "https://hydro01" -Scope global -Option Constant

# Create FLY plans

function New-FlyPlan {
    param (
        [string]$SiteMappingFile
    )

    #$FlyApiKey = "a1DAUuU6ZfeTXVHnXAW1f0OBRVRSN2KpIyGKRiav3BolQ1msxii9r5Hero4sGWa5"
    #$FlyUrl = 'https://hydro01:443'

    $FlyPolicies = Get-SPPolicy -APIKey $FlyApiKey -BaseUri $FlyUrl
    # 2020/05/05 Added FLY database logic
    $FlyDatabases  = Get-Database -APIKey $FlyApiKey -BaseUri $FlyUrl

    $AllPlanInfo = Import-Csv -Path $SiteMappingFile -Encoding UTF8
    
    foreach ($Line in $AllPlanInfo) {
        $SrcSite = $Line.'Migrate From'
        $TgtSite = $Line.'Migrate To'
        $Database = ($FlyDatabases.Content | Where-Object {$_.name -eq $Line.FlyDB}).Id
        $Policy = ($FlyPolicies.Content | Where-Object {$_.name -eq $Line.FlyPolicy}).ID
        $Batch =  $Line.Batch
        $Plan = $Line.Plan
        $TgtSiteSeq = $Line.'Migrate To'.replace("https://nhy.sharepoint.com/sites/Team-","")

        # Creating Plan
        
        $SourceCredential = New-SharePointCredentialObject -AppProfileName 'SAPA' #-AccountName 'ricky' 

        $DestinationCredential = New-SharePointCredentialObject -AppProfileName 'NHY' # -AccountName '<account name>' 

        $Source = New-SharePointObject -Level SiteCollection -Url $SrcSite

        $Destination = New-SharePointObject -Level SiteCollection -Url $TgtSite

        $MappingContent = New-SharePointMappingContentObject -Source $Source -Destination $Destination -Method Combine

        $Mappings = New-SharePointMappingObject -SourceCredential $SourceCredential -DestinationCredential $DestinationCredential -Contents @($MappingContent)

        $PlanNameLabel = New-PlanNameLabelObject -BusinessUnit $Batch -Wave $Plan -Name $TgtSiteSeq

        #$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

        $PlanSettings = New-SharePointPlanSettingsObject -MigrationMode HighSpeed -DatabaseId $Database -PolicyId $Policy -NameLabel $PlanNameLabel #-Schedule $Schedule

        $Plan = New-SharePointPlanObject -Settings $PlanSettings -Mappings $Mappings

        $response = Add-SPPlan -APIKey $FlyApiKey -BaseUri $FlyUrl -PlanSettings $Plan

        $response.Content
    }
}




# Get-FlyPlanId

function Get-FlyPlanId {
    param (
        [string]$PlanName
    )
    # Get all the SharePoint migration plans in FLY
    $FlyPlans = (Get-SPPlan -BaseUri $FlyUrl -APIKey $FlyApiKey).content

    $Found = $FlyPlans.Where({$_.Name -eq $PlanName.Trim()})

    #if ($FlyPlans.Name -contains $PlanName.Trim()) {
    if ($Found) {                                            
        $Found.Id
        #($FlyPlans.Where({$_.Name -eq $PlanName.Trim()})).Id
    }
    else {
        Write-Host "Cannot Find the Plan with Name:" $PlanName -ForegroundColor Red
    }
}


# Start Fly Job
function Start-FlyJob {
    param (
        [string]$PlanNameCsv
    )
    $FlyPlans = (Get-SPPlan -BaseUri $FlyUrl -APIKey $FlyApiKey).Content

    $PlanNames = Import-Csv $PlanNameCsv -Encoding UTF8

    foreach ($Plan in $PlanNames) {
        # Try to Get Job ID.
        $JobId = ($FlyPlans.Where({$_.Name -eq $Plan.PlanName.Trim()})).Id

        if (![string]::IsNullOrEmpty($JobId)) {
            $PlanMigrationType = New-PlanExecutionObject -MigrationType $Plan.MigrationType.Trim()

            Write-host "Starting Job:" $JobId ==> $($Plan.PlanName) -ForegroundColor Green
            try {
                $StartPlan = Start-SPJobByPlan -BaseUri $FlyUrl -APIKey $FlyApiKey -Id $JobId -PlanSettings $PlanMigrationType
                $StartPlan.Content
            }
            catch {
                $StartPlan.Errors
            }
        }
        else {
            Write-Host "Cannot Find Plan with Name:" $Plan -ForegroundColor Red
        }
    }
}

# 2020/06/18
# Get-FlyPlan will get all the plans if you don't specify the batch number.
function Get-FlyPlan {
    param (
        [string]$Batch
    )
    $BatchName = -join("B",$Batch)

    $SPPlans = (Get-SPPlan -BaseUri $FlyUrl -APIKey $FlyApiKey).Content

    switch ($BatchName) {
        "B" { $SPPlans }
        Default {$SPPlans.Where({$_.Name -match $BatchName})}
    }
}