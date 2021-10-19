
param (
    [Parameter(Mandatory=$true)]
    [string]
    $Domain,
    [Parameter(Mandatory=$true)]
    [string]
    $DNSZone,
    [Parameter(Mandatory=$true)]
    [string]
    $APIKey

)
Import-Module $PSScriptRoot\PSSafeDNS.psm1

Function Get-CurrentIP {
    (Invoke-WebRequest ipv4.icanhazip.com).content.trim()
}

Function Compare-SafeDNSRecords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ReferenceRecord,
        [Parameter(Mandatory=$true)]
        [string]
        $DifferenceRecord
    )

    if ( -not ($ReferenceRecord -eq $DifferenceRecord)) {
        return $false
    } else {
        return $true
    }
}


$current_record = Get-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -APIKey $APIKey


if (-not($current_record.id)) {
    New-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -Content (Get-CurrentIP) -APIKey $APIKey
    exit
} 


if (($current_record | Measure-Object).count -gt 1) {
    $i = 0
    Write-Output "More than one records exist"
    foreach ($cur in $current_record) {
        if (-not($i -eq 0)) {
            Remove-SafeDNSRecord -ID $cur.id -DNSZone $DNSZone -Type A -APIKey $APIKey
        }
        $i++
    }
    
    
}

$current_record = Get-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -APIKey $APIKey

$current_record_id = $current_record.id
$current_record_content = $current_record.content
$compare = Compare-SafeDNSRecords -ReferenceRecord $current_record_content -DifferenceRecord (Get-CurrentIP)

if ($compare -eq $false) {
    Set-SafeDNSRecord -ID $current_record_id -Domain $Domain -DNSZone $DNSZone -Type A -Content (Get-CurrentIP) -APIKey $APIKey
}
