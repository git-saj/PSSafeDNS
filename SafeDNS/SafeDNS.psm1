Function Get-SafeDNSRecord {
    <#
	    .SYNOPSIS
	    Returns existing SafeDNS records
	    .DESCRIPTION
	    The function makes a JSON request to the SafeDNS API and responds with a record
	    .PARAMETER ID
        Add search criteria for record ID
        .PARAMETER Domain
        Add search criteria for record name
        .PARAMETER DNSZone
        Define the DNZZone to search
        .PARAMETER Type
        Add search criteria for record type
        .PARAMETER Content
        Add search criteria for record content
        .PARAMETER APIKey
	    Define an authorized API Key to use
	    .EXAMPLE
	    get-SafeDNSRecord -Domain "test.sajbox.co.uk" -DNSZone sajbox.co.uk -APIKey "xxxxxxxxxxxx"
	    .INPUTS
	    System.String
	    .OUTPUTS
	    System.String
	    .LINK
	    https://sajbox.co.uk
	#>
    [cmdletbinding()]
    Param (
        [Parameter()]
        [string]
        $ID,
        [Parameter()]
        [string]
        $Domain,
        [Parameter(Mandatory=$true)]
        [string]
        $DNSZone,
        [Parameter()]
        [string]
        $Type,
        [Parameter()]
        [string]
        $Content,
        [Parameter(Mandatory=$true)]
        [string]
        $APIKey
    )

    $object_get = @()

    $headers = @{"Authorization"="$APIKey"}

    $get_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records"

    $body_get_record_hash = @{}

    if ($ID) {
        $body_get_record_hash.Add("id", "$ID")
    }
    if ($Domain) {
        $body_get_record_hash.Add("name", "$Domain")
    }
    if ($Type) {
        $body_get_record_hash.Add("type", "$Type")
    }
    if ($Content) {
        $body_get_record_hash.Add("content", "$Content")
    }

    $result = Invoke-RestMethod -Method Get -Uri $get_url -Headers $headers -Body $body_get_record_hash -ContentType 'application/json'

    foreach ($res in $result.data) {
        $object_get += [PSCustomObject]@{
            ID = $res.id
            Domain = $res.name
            Type = $res.type
            Content = $res.content
            Updated = $res.Updated_at
        }
    }
    
    while ($result.meta.pagination.links.next) {
        $result = Invoke-RestMethod -Method Get -Uri $result.meta.pagination.links.next -Headers $headers -ContentType 'application/json'

        foreach ($res in $result.data) {
            $object_get += [PSCustomObject]@{
                ID = $res.id
                Domain = $res.name
                Type = $res.type
                Content = $res.content
                Updated = $res.Updated_at
            }
        }
    }

    return $object_get

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
        [Parameter(Mandatory=$true)]
        [string]
        $APIKey
    )

    $headers = @{"Authorization"="$APIKey"}

    $post_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records"

    $body_create_record_hash = @{}

    $body_create_record_hash.Add("name", "$Domain")

    $body_create_record_hash.Add("type", "$Type")

    $body_create_record_hash.Add("content", "$Content")

    $body_create_record_hash = $body_create_record_hash | ConvertTo-Json

    $result = Invoke-RestMethod -Method Post -Uri $post_url -Headers $headers -Body $body_create_record_hash -ContentType 'application/json'

    $result_id = $result.data.id

    Write-Output "New record created record ID: $result_id"

    
}

Function Remove-SafeDNSRecord {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]
        $ID,
        [Parameter()]
        [string]
        $Domain,
        [Parameter(Mandatory=$true)]
        [string]
        $DNSZone,
        [Parameter()]
        [string]
        $Type,
        [Parameter()]
        [string]
        $Content,
        [Parameter(Mandatory=$true)]
        [string]
        $APIKey
    )

    if (!$ID) {
        Write-Output "No record ID supplied"
        return
    }

    $headers = @{"Authorization"="$APIKey"}
    
    $get_record_hash = @{
        DNSZone = $DNSZone
        APIKey = $APIKey
        ID = $id
    }

    if ($Domain) {
        $get_record_hash.Add("domain", "$Domain")
    }
    if ($Type) {
        $get_record_hash.Add("type", "$Type")
    }
    if ($Content) {
        $get_record_hash.Add("content", "$Content")
    }
    $record = Get-SafeDNSRecord @get_record_hash
    
    

    foreach ($rid in $record.id) {
        Write-Output "Deleting record $rid"
        $del_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records/$rid"
        Invoke-RestMethod -Method Delete -Uri $del_url -Headers $headers -ContentType 'application/json'
    }

    

}

Function Set-SafeDNSRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ID,
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
        [Parameter(Mandatory=$true)]
        [string]
        $APIKey
    )

    $headers = @{"Authorization"="$APIKey"}

    $patch_url = "https://api.ukfast.io/safedns/v1/zones/$DNSZone/records/$id"

    $body_update_record_hash = @{}

    $body_update_record_hash.Add("name", "$Domain")

    $body_update_record_hash.Add("type", "$Type")

    $body_update_record_hash.Add("content", "$Content")

    $body_update_record_hash = $body_update_record_hash | ConvertTo-Json

    $result = Invoke-RestMethod -Method Patch -Uri $patch_url -Headers $headers -Body $body_update_record_hash -ContentType 'application/json'

    $result_id = $result.data.id

    Write-Output "Content updated for record ID: $result_id to: $Content"

    
}