param (
    [Parameter(Mandatory=$true)][string]$Domain,
    [Parameter(Mandatory=$true)][string]$DNSZone,
    [Parameter(Mandatory=$true)][string]$APIKey

)

Function Get-CurrentIP {
    (Invoke-WebRequest ipv4.icanhazip.com).content.trim()
}

Function Get-SafeDNSRecord {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        [Parameter(Mandatory=$true)]
        [string]
        $Type
    )
    $get_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records"

    $body_get_record = @{
        "name"="$name"
        "type"="$type"
    }
    
    Invoke-RestMethod -Method Get -Uri $get_url -Headers $headers -Body $body_get_record -ContentType 'application/json'

}

Function New-SafeDNSRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        [Parameter(Mandatory=$true)]
        [string]
        $Type,
        [Parameter(Mandatory=$true)]
        [string]
        $Content
    )

    $post_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records"

    $body_create_record = @{
        "name"="$name"
        "type"="$type"
        "content"="$content"
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri $post_url -Headers $headers -Body $body_create_record -ContentType 'application/json' | Out-Null
    (Get-SafeDNSRecord -Name $Domain -Type A).data
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

Function Set-SafeDNSRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        [Parameter(Mandatory=$true)]
        [string]
        $Type,
        [Parameter(Mandatory=$true)]
        [string]
        $Content
    )

    $patch_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records/$current_record_id"
    $body_patch_record = @{
        "name"="$Name"
        "type"="$Type"
        "content"="$Content"
    } | ConvertTo-Json

    Invoke-RestMethod -Method Patch -Uri $patch_url -Headers $headers -Body $body_patch_record -ContentType 'application/json' | Out-Null
    (Get-SafeDNSRecord -Name $Domain -Type A).data

}

$headers = @{"Authorization"="$APIKey"}

$current_record = Get-SafeDNSRecord -Name $Domain -Type A


if (-not($current_record.data)) {
    $current_record = New-SafeDNSRecord -Name $Domain -Type A -Content (Get-CurrentIP)
    (Get-SafeDNSRecord -Name $Domain -Type A).data
    exit
} 

$current_record_id = $current_record.data.id
$current_record_content = $current_record.data.content
$compare = Compare-SafeDNSRecords -ReferenceRecord $current_record_content -DifferenceRecord (Get-CurrentIP)


if ($compare -eq $false) {
    Set-SafeDNSRecord -Name $Domain -Type A -Content (Get-CurrentIP)
} else {
    (Get-SafeDNSRecord -Name $Domain -Type A).data
}