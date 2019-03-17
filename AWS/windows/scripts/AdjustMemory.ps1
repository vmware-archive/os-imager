# Source: https://p0w3rsh3ll.wordpress.com/2013/03/17/pagefile-configuration-and-guidance/
#Requires -Version 3.0

if (!($IsLinux -or $IsOSX))
{
  Write-Host "Current WINRS config"
  winrm get winrm/config/winrs
  Write-Host ""
  Write-Host ""
  Write-Host "Current Page file(s):"
  try {
      Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction Stop |Select-Object Name,
        @{Name="InitialSize(MB)";Expression={if($_.InitialSize -eq 0){"System Managed"}else{$_.InitialSize}}},
        @{Name="MaximumSize(MB)";Expression={if($_.MaximumSize -eq 0){"System Managed"}else{$_.MaximumSize}}}|
        Format-Table -AutoSize
  } catch {
      Write-Warning -Message "Failed to query Win32_PageFileSetting class because $($_.Exception.Message)"
  }
  Write-Host ""
  Write-Host ""

  $drive_letter = $Env:DRIVE_LETTER
  $initial_size = $Env:INITIAL_SIZE
  $maximum_size = $Env:MAXIMUM_SIZE

  Write-Host "DriveLetter: $drive_letter // InitialSize: $initial_size // MaximumSize: $maximum_size"
  reg add "hklm\system\currentcontrolset\control\session manager\memory management" /v pagingfiles /t reg_multi_sz /d "$drive_letter`:\pagefile.sys $initial_size $maximum_size" /f

  Write-Host "Done."
  Write-Host ""
  Write-Host "Final Page file(s):"
  try {
      Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction Stop |Select-Object Name,
        @{Name="InitialSize(MB)";Expression={if($_.InitialSize -eq 0){"System Managed"}else{$_.InitialSize}}},
        @{Name="MaximumSize(MB)";Expression={if($_.MaximumSize -eq 0){"System Managed"}else{$_.MaximumSize}}}|
        Format-Table -AutoSize
  } catch {
      Write-Warning -Message "Failed to query Win32_PageFileSetting class because $($_.Exception.Message)"
  }
}
else
{
    Write-Error "This script is currently only supported on the Windows operating system."
}
