#
# A utility script to download a file.
#
# The motivation for this script is that earlier TLS protocols are widely deprecated across the Internet,
# and some of the tools we use for downloading (including NAnt native features, wget.exe and others)
# do not provide a way to prefer the TLS 1.2 protocol.
# https://blog.pcisecuritystandards.org/are-you-ready-for-30-june-2018-sayin-goodbye-to-ssl-early-tls
#

param(
    [Parameter(Mandatory=$true)][string]$url, 
    [Parameter(Mandatory=$true)][string]$destination,
    [switch]$overwrite=$false)

# Set the script location
Set-Location $PSScriptRoot
[Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath

# Suppress progress messages
$ProgressPreference = "SilentlyContinue"

# Stop on any error
$ErrorActionPreference = "Stop"

# Fail if there is already a file at the destination path.
# This check can be bypassed with the "-overwrite" flag.
if ((Test-Path $destination) -and (-not $overwrite)) {
    Throw "The destination file ""${destination}"" already exists and ""-overwrite"" was not specified." 
}

# Use a temporary file for the download destination to avoid prematurely
# overwriting whatever might have been there to begin with.
$temp = "$destination.incomplete"

# Require TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11;

# Download a file from a URL to a temporary file.
(new-object System.Net.WebClient).DownloadFile($url, $temp)

# Move the temporary file to the destination path.
Move-Item $temp $destination -Force
