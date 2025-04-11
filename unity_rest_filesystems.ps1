###############
# PowerShell - Unity File System Reporting Tool
# This script will prompt for credentials, pull a list of Unity DNS names from a text file, query them all for information about the 
# file systems they contain, and dump the data to a CSV file. 
# This script work with PowerShell core on Mac, Linux, and Windows, and of course various versions of Windows PowerShell

###### Credentials ##########
# Create credentials that will be converted to basic authentication string

$creds = Get-Credential
  $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($creds.UserName + ':' + $creds.GetNetworkCredential().Password))

###### HEADER ##########
# Create auth header

$headers = @{
    "Accept" = "application/json"
    "Content-type" = "application/json"
    "X-EMC-REST-CLIENT" = "true"
    "Authorization" = "Basic $auth"
}

#creating this for CSV file uniqueness and tracking
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_hhmm")

# input and output
$unitys = Get-Content unitys.txt
$csvFile = "$TimeStamp.file_system_export.csv"

#FILE SYSTEMS Query (Check EMC documentation online for more details)
$query = "/api/types/filesystem/instances?compact=True&fields=id,name,description,type,sizeTotal,sizeUsed,isThinEnabled,pool,nasServer"

foreach ($unity in $unitys){

    try {
        $base = "https://$unity`:443"
        $fs = Invoke-WebRequest -Uri $base$query -Method Get -Headers $headers -SkipCertificateCheck -PreserveAuthorizationOnRedirect -SessionVariable unityrest1
        $fsdata = $fs.Content | ConvertFrom-Json 
        if (!(Test-Path $csvFile)) {
            $fsdata.entries | Select-Object id,name,description,type,@{n="sizeTotalGB";e={[int]($_.sizeTotal/1GB)}},`
            @{n="sizeUsedGB";e={[int]($_.sizeUsed/1GB)}},isThinEnabled |
        Export-Csv -Path $csvFile -NoTypeInformation
    }
        else {
            $fsdata.entries | Select-Object id,name,description,type,@{n="sizeTotalGB";e={[int]($_.sizeTotal/1GB)}},`
            @{n="sizeUsedGB";e={[int]($_.sizeUsed/1GB)}},isThinEnabled |
        Export-Csv -Path $csvFile -NoTypeInformation -Append
        }
    }
    catch {
        Write-Host "Greetings Professor Falken.   Shall we play a game?" -ForegroundColor green
    }
    }

    # Output the results in your terminal
    $fsdata.entries | Select-Object -ExpandProperty content | Select-Object id,name,description,type,@{n="sizeTotalGB";e={[int]($_.sizeTotal/1GB)}},`
    @{n="sizeUsedGB";e={[int]($_.sizeUsed/1GB)}},isThinEnabled | Format-Table -AutoSize


# Uncomment and run the lines below to probe the data that was returned.    

# $fs.StatusCode
# $fs.Headers
# $fs.Content
# $fs.Content | ConvertFrom-Json

# Send to Grid-View (Windows Only)
# $fsdata.entries | Select-Object -ExpandProperty content | Select-Object id,name,description,type,@{n="sizeTotalGB";e={[int]($_.sizeTotal/1GB)}},`
# @{n="sizeUsedGB";e={[int]($_.sizeUsed/1GB)}},@{n="sizeAllocatedGB";e={[int]($_.sizeAllocated/1GB)}},isThinEnabled | out-gridview
