$URL = Read-Host -Prompt "URL"

$HTTP_Request = [System.Net.WebRequest]::Create($URL)

$HTTP_Response = $HTTP_Request.GetResponse()

$HTTP_Status = [int]$HTTP_Response.StatusCode

$HTTP_Status