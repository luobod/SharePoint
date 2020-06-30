# Example Below:
# Compare-ListInfo -MappingFilePath .\Compare-ListInfo\Batch_05.csv -ListsPath .\Compare-ListInfo -ReportPath .\B05\B05_Reports

function Compare-ListInfo {
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
    
        $ReportName = "Src_'$Src'_Dst_'$Dst'_$((Get-Date).ToString('MM-dd')).csv"
        $ReportFile = Join-Path $ReportPath $ReportName
        write-host "Report Name: $ReportName"
    
        $Report = @()
        foreach ($r in $SrcCsv) {
            $RefUrl =  $r.ServerRelativeUrl.Split("/",4)[-1]
            $obj = New-Object -TypeName PSCustomObject
            $obj | Add-Member -MemberType NoteProperty -Name SrcTitle -Value $r.Title
            $obj | Add-Member -MemberType NoteProperty -Name DestTitle -Value ""
            $obj | Add-Member -MemberType NoteProperty -Name SrcItemCount -Value $r.ItemCount
            $obj | Add-Member -MemberType NoteProperty -Name DestItemCount -Value ""
            $obj | Add-Member -MemberType NoteProperty -Name SrcDefaultViewUrl -Value $r.DefaultViewUrl
            $obj | Add-Member -MemberType NoteProperty -Name DestDefaultViewUrl -Value ""
            $obj | Add-Member -MemberType NoteProperty -Name Comments -Value ""
            foreach ($d in $DstCsv) {
                $DifUrl = $d.ServerRelativeUrl.Split("/",4)[-1]
                if ($RefUrl -eq $DifUrl) {
                    $obj.DestTitle = $d.Title
                   # $obj | Add-Member -MemberType NoteProperty -Name SrcItemCount -Value $r.ItemCount
                    $obj.DestItemCount = $d.ItemCount
                   # $obj | Add-Member -MemberType NoteProperty -Name SrcDefaultViewUrl -Value $r.DefaultViewUrl
                    $obj.DestDefaultViewUrl = $d.DefaultViewUrl
                }
            }
            $report += $obj
            #$r | Export-Csv $CompareResults -NoTypeInformation -Encoding utf8 -Append
        }
        $Report | Export-Csv $ReportFile -NoTypeInformation -Encoding utf8
    }
}