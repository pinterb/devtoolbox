Param (
  [String]$version = "1.9.1",
  [String]$goroot = "C:\Go",
  [String]$gopath = "$env:USERPROFILE\go",
  [Boolean]$debug = 0,
  [Boolean]$wslpath = 0,
  [switch]$h = $false,
  [switch]$help = $false
)

$SCRIPT=$MyInvocation.MyCommand.Name
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent())
$isadmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function print_usage() {
  echo @"
Download and install Golang on Windows. It sets the GOROOT environment
variable and adds GOROOT\bin to the PATH environment variable. By default,
it uses Golang's defaults for GOROOT and GOPATH. 

To update required environment variables, this script must be run with Admin
privileges.  Otherwise, run with -debug flag set to get variables you will set
manually.

Finally, use the -wslpath flag to display the WSL-equivalent GOPATH.
  
Usage:
  $SCRIPT 

Options:
  -h | -help
    Print the help menu.
  -version
    Golang version to install. (default: $version)
  -goroot
    Where to install Golang. (default: $goroot)
  -gopath
    The GOPATH to use for your development work. (default: $gopath)
  -wslpath
    Flag used to output WSL-equivalent GOPATH (default: $wslpath)
  -debug
    Output debug messages. (default: $debug)
"@
}

# install golang using defaults as described at:
#  https://golang.org/doc/install
function install() {
  Param (
    [Boolean]$isupgrade = 0
  )

  $downloadDir = $env:TEMP
  $packageName = 'golang'
  $url32 = 'https://storage.googleapis.com/golang/go' + $version + '.windows-386.zip'
  $url64 = 'https://storage.googleapis.com/golang/go' + $version + '.windows-amd64.zip'

  # Determine type of system
  if ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $url = $url64
  } else {
    $url = $url32
  }

  if ($debug) {
    echo "Downloading $url"
  }

  $zip = "$downloadDir\golang-$version.zip"
  if (!(Test-Path "$zip")) {
    $downloader = new-object System.Net.WebClient
    $downloader.DownloadFile($url, $zip)
  }
  
  if ($debug) {
    echo "Extracting $zip to $goroot"
  }

  if (Test-Path "$downloadDir\go") {
    rm -Force -Recurse -Path "$downloadDir\go"
  }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory("$zip", $downloadDir)
  
  if ($isupgrade) {
    rm -Force -Recurse -Path $goroot
  }
  mv "$downloadDir\go" $goroot
 
  if (!($isupgrade)) {
    if ($debug) {
      echo "Setting PATH for Machine"
    }

    $p = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $p = "$goroot\bin;$p"
  
    if ($isadmin) {
      [System.Environment]::SetEnvironmentVariable("PATH", "$p", "Machine")
    } elseif ($debug) {
      echo ""
      echo "You're not running with Administrator privileges."
      echo "You need to add the following to the PATH environment variable:"
      echo "  $goroot\bin"
    } else {
      exit 1
    }

    # only need to set $GOROOT if it's non-standard
    if ($goroot -ne "C:\Go") {
      set_goroot
    } elseif ($debug) {
      echo "Using standard GOROOT"
    }
  }
}

# set the $GOROOT
function set_goroot() {
  if ($debug) {
    echo "Setting GOROOT for Machine"
  }
  
  if ($isadmin) {
    [System.Environment]::SetEnvironmentVariable("GOROOT", "$goroot", "Machine")
  } elseif ($debug) {
    echo ""
    echo "You're not running with Administrator privileges."
    echo "You need to set the following GOROOT environment variable:"
    echo "  $goroot"
  } else {
    exit 1
  }
}

# create a GOPATH 
function mk_gopath() {
  if (Test-Path "$gopath") {
    exit 1
  } elseif ($debug) {
    echo "Creating a GOPATH"
  }

  New-Item -ItemType Directory -Force -Path $gopath
  New-Item -ItemType Directory -Force -Path $gopath\src
  New-Item -ItemType Directory -Force -Path $gopath\pkg
  New-Item -ItemType Directory -Force -Path $gopath\bin

  # only need to set $GOPATH if it's non-standard
  if ($gopath -ne "$env:USERPROFILE\go") {
    set_gopath
  } elseif ($debug) {
    echo "Using standard GOPATH"
  }
}

# set the $GOPATH
function set_gopath() {
  if ($debug) {
    echo "Setting GOPATH for Machine"
  }
  
  if ($isadmin) {
    [System.Environment]::SetEnvironmentVariable("GOPATH", "$gopath", "Machine")
  } elseif ($debug) {
    echo ""
    echo "You're not running with Administrator privileges."
    echo "You need to set the following GOPATH environment variable:"
    echo "  $gopath"
  } else {
    exit 1
  }
  
#  $p = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
#  $p = "$gopath\bin;$p"
#  [System.Environment]::SetEnvironmentVariable("PATH", "$p", "Machine")
}
  
if ($help -or $h) {
  print_usage
  exit 0
}
if ($args -ne "") {
  Write-Error "Error: Unknown option $args"
  print_usage
  exit 1
}
 
if ($debug) {
  echo "Specified goroot: $goroot"
  echo "Specified gopath: $gopath"
}
 
if (Test-Path "$goroot\bin\go.exe") {
  $v = (go version).Split(" ")
  $desiredv = "go"+$version
  if ($v[2..2] -ne $desiredv) {
    # effectively, this is an in-place upgrade
    install -isupgrade 1 
  } elseif ($debug) {
    echo "Go already installed to current version"
  }
} else {
  if ($debug) {
    echo "Go is not installed"
  }
  install
}
 
if (!(Test-Path "$gopath")) {
  if ($debug) {
    echo "Specified gopath does not exist"
  }
  mk_gopath
}

if ($wslpath) {
  $drive = $gopath.Substring(0,1).ToLower()
  $winpath = $gopath.Substring(2)
  $unixpath = $winpath.Replace("\", "/")
  $posixpath = "/mnt/"+$drive+$unixpath
  echo $posixpath
}