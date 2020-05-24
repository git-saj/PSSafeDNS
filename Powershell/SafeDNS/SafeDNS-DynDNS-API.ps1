param (
    [Parameter(Mandatory=$true)][string]$Domain
)

$get_url = "https://api.ukfast.io/safedns/v1/zones/sajbox.co.uk/records"

$headers = @{"Authorization"="Ndxx3RnJhbedP86VgWTfctTCQ74f548E"}

$body_current_record = @{
    "name"="$Domain"
    "type"="A"
}

$current_server_ip = (Invoke-WebRequest ipv4.icanhazip.com).content.trim()

$current_record = Invoke-RestMethod -Method Get -Uri $get_url -Headers $headers -Body $body_current_record -ContentType 'application/json'

$current_record_id = $current_record.data.id
$current_record_content = $current_record.data.content

if ( -not ($current_record_content -eq $current_server_ip)) {
    $patch_url = "https://api.ukfast.io/safedns/v1/zones/sajbox.co.uk/records/$current_record_id"
    $body_patch_record = @{
        "name"="$Domain"
        "type"="A"
        "content"="$current_server_ip"
    } | ConvertTo-Json

    $body_patch_record = $body_patch_record
    Invoke-RestMethod -Method Patch -Uri $patch_url -Headers $headers -Body $body_patch_record -ContentType 'application/json'
}
