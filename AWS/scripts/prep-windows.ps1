# ----- Download File Function ------------------------------------------------------------------>
Function DownloadFileWithProgress {

    # Code for this function borrowed from http://poshcode.org/2461
    # Thanks Crazy Dave

    # This function downloads the passed file and shows a progress bar
    # It receives two parameters:
    #    $url - the file source
    #    $localfile - the file destination on the local machine

    param(
        [Parameter(Mandatory=$true)]
        [String] $url,
        [Parameter(Mandatory=$false)]
        [String] $localFile = (Join-Path $pwd.Path $url.SubString($url.LastIndexOf('/')))
    )


    begin {
        Write-Host -ForegroundColor DarkGreen "  download-module.DownloadFileWithProgress  $url"
        $client = New-Object System.Net.WebClient
        $Global:downloadComplete = $false
        $eventDataComplete = Register-ObjectEvent $client DownloadFileCompleted `
            -SourceIdentifier WebClient.DownloadFileComplete `
            -Action {$Global:downloadComplete = $true}
        $eventDataProgress = Register-ObjectEvent $client DownloadProgressChanged `
            -SourceIdentifier WebClient.DownloadProgressChanged `
            -Action { $Global:DPCEventArgs = $EventArgs }
    }
    process {
        Write-Progress -Activity 'Downloading file' -Status $url
        $client.DownloadFileAsync($url, $localFile)

        while (!($Global:downloadComplete)) {
            $pc = $Global:DPCEventArgs.ProgressPercentage
            if ($pc -ne $null) {
                Write-Progress -Activity 'Downloading file' -Status $url -PercentComplete $pc
            }
        }
        Write-Progress -Activity 'Downloading file' -Status $url -Complete
    }

    end {
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
        $client.Dispose()
        $Global:downloadComplete = $null
        $Global:DPCEventArgs = $null
        Remove-Variable client
        Remove-Variable eventDataComplete
        Remove-Variable eventDataProgress
        [GC]::Collect()
        # 2016-07-06  mkr  Errorchecking added. nice-to-have: integration into the above code.
        If (!((Test-Path "$localfile") -and ((Get-Item "$localfile").length -gt 0kb))) {
            Write-Error "Exiting because download missing or zero-length:    $localfile"
            exit 2
        }

    }
}
# <---- Download File Function -------------------------------------------------------------------

# ----- Get Directory of this script ------------------------------------------------------------>
$ScriptPath = dir "$($myInvocation.MyCommand.Definition)"
$ScriptDirectory = $ScriptPath.DirectoryName
# <---- Get Directory of this script -------------------------------------------------------------

# ----- Load Settings From Environment ---------------------------------------------------------->
$SaltBranch = $Env:SALT_BRANCH
$PythonVersion = $Env:PY_VERSION
# <---- Load Settings From Environment -----------------------------------------------------------

# ----- Do Work --------------------------------------------------------------------------------->
# Salt Repo Download Base URL
$BaseURL = "https://raw.githubusercontent.com/saltstack/salt/${SaltBranch}/pkg/windows"
$PipReqFilename = "req_pip.txt"
$PipWinReqFilename = "req_win.txt"
$BuildEnvScriptName = "build_env_${PythonVersion}.ps1"
$BuildEnvModulesNames = ("download-module.psm1",
                         "get-settings.psm1",
                         "start-process-and-test-exitcode.psm1",
                         "uac-module.psm1",
                         "zip-module.psm1")

# Download the build_env script
DownloadFileWithProgress "${BaseURL}/${BuildEnvScriptName}" "${ScriptDirectory}\${BuildEnvScriptName}"

# Download the PIP/Setuptools requirements file
DownloadFileWithProgress "${BaseURL}/${PipReqFilename}" "${ScriptDirectory}\${PipReqFilename}"

# Download the Windows specific file
DownloadFileWithProgress "${BaseURL}/${PipWinReqFilename}" "${ScriptDirectory}\${PipWinReqFilename}"

# Create the downloaded powershell modules directory
$PSModulesDirectory = "${ScriptDirectory}\modules"
New-Item -Path $PSModulesDirectory -ItemType directory

# Download the powershell modules
ForEach($ModuleName in $BuildEnvModulesNames) {
  DownloadFileWithProgress "${BaseURL}/modules/${ModuleName}" "${PSModulesDirectory}\${ModuleName}"
}

# Call Out the build env script
$BuildEnvScriptPath = "${ScriptDirectory}\${BuildEnvScriptName}"
$Command = "${BuildEnvScriptPath} -Silent -NoPipDependencies"

$ExitCode = 0
try {
  Write-Host "Running '${Command}'" -ForegroundColor Yellow
  Invoke-Expression -Command "${Command}"
} catch {
  $ErrorMessage = $_.Exception.Message
  $FailedItem = $_.Exception.ItemName
  Write-Error "Failed to run ${Command}: ${FailedItem} // ${ErrorMessage}"
  $ExitCode = 1
} finally {
  # Remove the downloaded modules
  Remove-Item $PSModulesDirectory -Force -Recurse
}
exit $ExitCode
# <---- Do Work ----------------------------------------------------------------------------------
