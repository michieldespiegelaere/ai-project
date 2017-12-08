FUNCTION Test-Administrator {  
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

# Check if the script is running with admin privileges
# If it's not, display a warning and exit
IF (Test-Administrator) {
  Write-Output "Administrator privileges: Check!"
}
ELSE {
  Write-Output "NOT AN ADMIN!"
  Write-Output "Please execute the script with administrator privleges."
  PAUSE
  EXIT 1
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Output "Download Osquery"
# Add the "-y" flag to automatically confirm all prompts
choco install osquery -y

Write-Output "Install Osqueryd"
C:\ProgramData\osquery\osqueryd\osqueryd.exe --install

Write-Output "Configure Osqueryd"
$osqExampleConfPath = "C:\ProgramData\osquery\osquery.example.conf" 
if (Test-Path $osqExampleConfPath) {
  Remove-Item $osqExampleConfPath
}

$osqConfigFileUri = "https://raw.githubusercontent.com/BertGoens/ai-project/master/client/osquery/honeypot.osquery.conf"
$osqFlagFileUri = "https://raw.githubusercontent.com/BertGoens/ai-project/master/client/osquery/osquery.flags"
$osqConfigFileLocation = "C:\ProgramData\osquery\osquery.conf"
$osqFlagFileLocation = "C:\ProgramData\osquery\osquery.flags"

if (Test-Path $osqConfigFileLocation) {
  Remove-Item $osqConfigFileLocation
}
if (Test-Path $osqFlagFileLocation) {
  Remove-Item $osqFlagFileLocation
}

Invoke-WebRequest -Uri $osqConfigFileUri -OutFile $osqConfigFileLocation -UseBasicParsing
Invoke-WebRequest -Uri $osqFlagFileUri -OutFile $osqFlagFileLocation -UseBasicParsing

Write-Output "Restart Osquery"
Restart-Service osqueryd

# Create SendLogs.sp1 in C:\SendLog\SendLogs.ps1
$scriptFolderLocation = "C:\SendLog\"
$scriptFileLocation = $scriptFolderLocation + "SendLogs.ps1" 
If (!(Test-Path $scriptFolderLocation)) {
  New-Item -ItemType Directory -Force -Path $scriptFolderLocation
}

$sendLogsUri = "https://raw.githubusercontent.com/BertGoens/ai-project/master/client/scripts/send%20logs/SendLogs.ps1"
if (Test-Path $scriptFileLocation) {
  Remove-Item $scriptFileLocation
}
Invoke-WebRequest -Uri $sendLogsUri -OutFile $scriptFileLocation -UseBasicParsing

Write-Output "Create a task to run the script every 5 minutes"

# set up the action
$action = New-ScheduledTaskAction –Execute "$pshome\powershell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptFileLocation;"
# Set up the trigger
$repeat = (New-TimeSpan -Minutes 5)
$duration = (New-TimeSpan -Days 365)
$startDate = ([System.DateTime]::Now)
$trigger = New-ScheduledTaskTrigger -Once -At $startDate  -RepetitionInterval $repeat -RepetitionDuration $duration

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -DontStopOnIdleEnd
$User = "Administrator"
$jobname = "Sendlogs"
Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $trigger -RunLevel Highest -User $User -Settings $settings

# Create firewall rule to allow out outbound traffic

Write-Output "Installed Successfully"

PAUSE
