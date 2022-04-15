param (
    [Parameter()] [string] $ThingIDs = "",
    [Parameter()] [string] $Token = "56edfc79ecf25922b98202dd79a291aa",
    [Parameter()] [string] $Location = "Z:\STL"
)

function Download-Thing {

    param (
        [Parameter(mandatory=$true)] [string] $ThingID
    )

    
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.79 Safari/537.36"

    try 
{
    $thing_raw_metadata = Invoke-WebRequest -UseBasicParsing -Uri "https://api.thingiverse.com/things/$ThingID" `
        -WebSession $session `
        -Headers @{
            "authority"="api.thingiverse.com"
            "method"="GET"
            "path"="/things/$ThingID"
            "scheme"="https"
            "accept"="*/*"
            "accept-encoding"="gzip, deflate, br"
            "accept-language"="de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7"
            "authorization"="Bearer $Token"
            "cache-control"="no-cache"
            "origin"="https://www.thingiverse.com"
            "pragma"="no-cache"
            "referer"="https://www.thingiverse.com/"
            "sec-fetch-dest"="empty"
            "sec-fetch-mode"="cors"
            "sec-fetch-site"="same-site"
            "sec-gpc"="1"
        } `
        -ErrorAction Stop

    $thing_raw_files = Invoke-WebRequest -UseBasicParsing -Uri "https://api.thingiverse.com/things/$ThingID/files" `
        -WebSession $session `
        -Headers @{
            "authority"="api.thingiverse.com"
            "method"="GET"
            "path"="/things/$ThingID/files"
            "scheme"="https"
            "accept"="*/*"
            "accept-encoding"="gzip, deflate, br"
            "accept-language"="de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7"
            "authorization"="Bearer $Token"
            "cache-control"="no-cache"
            "origin"="https://www.thingiverse.com"
            "pragma"="no-cache"
            "referer"="https://www.thingiverse.com/"
            "sec-fetch-dest"="empty"
            "sec-fetch-mode"="cors"
            "sec-fetch-site"="same-site"
            "sec-gpc"="1"
        } `
        -ErrorAction Stop
} 
catch 
{
  Write-Error "Could not download API information, please provide a new token"
  Exit 1
}

try 
{
    $thing_metadata = $thing_raw_metadata.Content | ConvertFrom-Json
    $thing_files = $thing_raw_files.Content | ConvertFrom-Json

    $directory_name = $thing_metadata.name -replace "[^a-zA-Z0-9-]",'_' -replace "[_]+",'_' -replace '(^_|_$)',''
    $directory = "{0}\{1}" -f $Location.Path, $directory_name

    Write-Output("Directory {0}" -f $directory)
    $null = New-Item -Path $directory -ItemType Directory -force
    foreach ($file in $thing_files){
        $target_file = "{0}\{1}" -f $directory, $file.name
        Write-Output("Downloading {0} ..." -f $file.name)
        Invoke-WebRequest -Uri $file.public_url -OutFile $target_file
    }

    $list = get-childitem -Path $directory -recurse *.zip 

    foreach ($item in $list) {
        try {
          $decompress = "{0}\{1}" -f $item.DirectoryName, $item.Basename
          Expand-Archive -Path $item.FullName -DestinationPath $decompress -ErrorAction Stop
          Remove-Item -Path $item.FullName
        } 
        catch {
            Write-Error $PSItem.ToString()
        }
    }
}
catch 
{
     Write-Error $PSItem.ToString()
}
}

if ($ThingIDs -eq "") {
  $ThingIDs = Read-Host -Prompt "ThingIDs splittet with comma"
}

if ($ThingIDs -notmatch '^([0-9]+,)*[0-9]+$') {
    Write-Output "Invalid list of ThingIDs"
    exit 1
}

$thingList = $ThingIDs -split ","
foreach ($thing in $thingList){
    Download-Thing -ThingID $thing
}

