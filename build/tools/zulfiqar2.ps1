#
# Zulfiqar 2.0
#
# This script is used to upload and download binary packages to/from S3 storage.
# The data file "ztools.json" specifies the packages that are required locally.
# Archives are downloaded into the "zpkgs" directory, and installed into the 
# "ztools" directory.
# When executed in "download" mode, all packages listed in "ztools.json" are downloaded
# and installed.
# When executed in "upload" model, all archives in "zpkgs" are uploaded to the specified
# S3 bucket.
#
# Download usage:
#   powershell.exe -file zulfiqar2.ps1
#
# Upload usage:
#   powershell.exe -file zulfiqar2.ps1 -sync -syncbucket optimatics-zulfiqar2
#

param([switch]$sync=$false, 
    [string]$syncbucket)

# Suppress progress messages
$ProgressPreference = "SilentlyContinue"

# Stop on any error
$ErrorActionPreference = "Stop"

# Extract a '7z' archive
Function Extract7zArchive() {
    param($archive, $destination)

    New-Item -ItemType Directory -Force -Path "$destination" | Out-Null
    & "${PSScriptRoot}\ztools\7zip-9.20\7za.exe" x $archive -o"$destination" 2>&1 | Out-Null
}

# Extract a 'zip' archive
Function UnZipFile() {
    param($archive, $destination)
    
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($archive, $destination)
}

# Download a file from a URL
Function DownloadFile() {
    param($url, $destination)
    
    (new-object System.Net.WebClient).DownloadFile($url, $destination)
}

# The directory that zipped archives are stored in
$zpkgsDir = New-Item -ItemType Directory -Force -Path "${PSScriptRoot}\zpkgs" | % { $_.FullName }
$zpkgsDir | %{ Set-ItemProperty -Path $_ -Name Attributes -Value ([IO.FileAttributes]::Hidden) } | Out-Null

# The directory that tools are installed to
$ztoolsDir = New-Item -ItemType Directory -Force -Path "${PSScriptRoot}\ztools" | % { $_.FullName }

if ($sync) {
    # If "sync" is specified, we upload rather than download packages.

    # TODO: Make "aws.exe" available on the system path.
    
    # Assert that a destination bucket was specified on the command-line.
    if ([string]::IsNullOrEmpty($syncbucket)) {
        throw "Sync Bucket was not specified";
    }
    
    # Upload any files, also setting them to "Public" read access.
    &aws s3 sync "$zpkgsDir" "s3://${syncbucket}" --acl public-read --size-only

    # List objects in the bucket
    $objects = (&aws s3api list-objects-v2 --bucket $syncbucket --output json --no-paginate | Out-String | ConvertFrom-Json).Contents

    # Report all of the objects in the bucket
    Write-Host The following objects exist on S3:
    foreach ($key in $objects) {    
        # &aws s3api put-object-acl --bucket optimatics-zulfiqar2 --key $key.Key --acl public-read
        $url = "https://s3.amazonaws.com/${syncbucket}/" + ([uri]::EscapeDataString($key.Key))
        Write-Host $url
    }
} else {
    # Download packages

    # Read the list of packages
    $pkgs = Get-Content "${PSScriptRoot}\ztools.json" | Out-String | ConvertFrom-Json

    ### Download the package
    foreach ($pkg in $pkgs) {
        $archive = Join-Path $zpkgsDir ($pkg.name + [System.IO.Path]::GetExtension($pkg.url))

        # Download the archive if it does not exist locally
        if (-not (Test-Path $archive)) {
            Write-Host $pkg.name downloading package from URL $pkg.url
            DownloadFile $pkg.url $archive
            Write-Host $pkg.name package has been downloaded to local path $archive
        }

        $installDir = Join-Path $ztoolsDir $pkg.name
        $z2meta = Join-Path $installDir .z2

        # Install the package if it is not installed locally
        if (-not (Test-Path $z2meta)) {
            Write-Host $pkg.name installing package to "$installDir"

            if ([System.IO.Path]::GetExtension($pkg.url) -eq ".zip") {
                UnZipFile $archive $installDir
            } else {
                Extract7zArchive $archive $installDir
            }
            
            # Install a meta-data file to flag successful installation
            New-Item $z2meta -ItemType File | Out-Null
            Write-Host $pkg.name installation complete
        }

        # Emit a success message
        Write-Host ($pkg.name) package OK
    }
}
