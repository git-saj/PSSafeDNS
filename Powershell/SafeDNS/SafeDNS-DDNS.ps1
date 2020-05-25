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

Function Get-CurrentIP {
    (Invoke-WebRequest ipv4.icanhazip.com).content.trim()
}

Function Get-SafeDNSRecord {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]
        $Domain,
        [Parameter(Mandatory=$true)]
        [string]
        $DNSZone,
        [Parameter(Mandatory=$true)]
        [string]
        $Type,
        [Parameter(Mandatory=$true)]
        [string]
        $APIKey
    )

    if ($APIKey) {
        $headers = @{"Authorization"="$APIKey"}
    }

    $object = New-Object psobject

    $object | Add-Member -MemberType NoteProperty -Name "Name" -Value $Domain
    $object | Add-Member -MemberType NoteProperty -Name "Type" -Value $Type

    $get_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records"

    $body_get_record = @{
        "name"="$Domain"
        "type"="$Type"
    }
    
    Invoke-RestMethod -Method Get -Uri $get_url -Headers $headers -Body $body_get_record -ContentType 'application/json'

}

Function New-SafeDNSRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Domain,
        [Parameter(Mandatory=$true)]
        [string]
        $DNSZone,
        [Parameter(Mandatory=$true)]
        [string]
        $Type,
        [Parameter(Mandatory=$true)]
        [string]
        $Content,
        [Parameter()]
        [string]
        $APIKey
    )

    if ($APIKey) {
        $headers = @{"Authorization"="$APIKey"}
    }

    $post_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records"

    $body_create_record = @{
        "name"="$Domain"
        "type"="$Type"
        "content"="$Content"
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri $post_url -Headers $headers -Body $body_create_record -ContentType 'application/json' | Out-Null
    (Get-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -APIKey $APIKey).data
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
        $Domain,
        [Parameter(Mandatory=$true)]
        [string]
        $DNSZone,
        [Parameter(Mandatory=$true)]
        [string]
        $Type,
        [Parameter(Mandatory=$true)]
        [string]
        $Content,
        [Parameter()]
        [string]
        $APIKey
    )

    if ($APIKey) {
        $headers = @{"Authorization"="$APIKey"}
    }

    $patch_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records/$current_record_id"
    $body_patch_record = @{
        "name"="$Name"
        "type"="$Type"
        "content"="$Content"
    } | ConvertTo-Json

    Invoke-RestMethod -Method Patch -Uri $patch_url -Headers $headers -Body $body_patch_record -ContentType 'application/json' | Out-Null
    (Get-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -APIKey $APIKey).data

}

$current_record = Get-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -APIKey $APIKey


if (-not($current_record.data)) {
    $current_record = New-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -Content (Get-CurrentIP) -APIKey $APIKey
    (Get-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -APIKey $APIKey).data
    exit
} 

$current_record_id = $current_record.data.id
$current_record_content = $current_record.data.content
$compare = Compare-SafeDNSRecords -ReferenceRecord $current_record_content -DifferenceRecord (Get-CurrentIP)


if ($compare -eq $false) {
    Set-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -Content (Get-CurrentIP) -APIKey $APIKey
} else {
    (Get-SafeDNSRecord -Domain $Domain -DNSZone $DNSZone -Type A -APIKey $APIKey).data
}