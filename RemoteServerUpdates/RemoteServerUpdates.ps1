#Update server script

#If PSWindowsUpdate isn't installed on the user's machine, install it
try {
    If ($null -eq (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
        Install-Module PSWindowsUpdate -Force
        Import-Module PSWindowsUpdate
    }
}
catch {
    Write-Host 'Error installing PSWindowsUpdate on local machine' -ForegroundColor RED
    #$PSItem is the current Error
    Write-Host 'Error:' $PSItem.Exception.Message -ForegroundColor RED
}

#Pull in an array of servers from a text file (Each new line in the file is a new element)
$servers = Get-Content -Path F:\servers.txt

foreach ($server in $servers) {
    try {
        #Adds the server to the user's trusted hosts list
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $server.ToString() -Force
        #Checks if PSWindowsUpdate is installed on the server, install it and NuGet if not. 
        Invoke-Command -ComputerName $server -Scriptblock {
            If ($null -eq (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
                Write-Host 'Installing Nuget and PSWindowsUpdate on ' $server
                #Changes the security protocol for the current session to allow the downloads
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Install-PackageProvider -Name NuGet -Force
                Install-Module PSWindowsUpdate -Force
                Import-Module PSWindowsUpdate
            }
        }
    }
    catch {
        Write-Host 'Error installing packages on' $server -ForegroundColor RED
        Write-Host 'Error:' $PSItem.Exception.Message -ForegroundColor RED
    }
    
    try {
        Write-Host 'Installing updates on' $server
        #Installs all updates on the server, doesn't reboot when complete.
        Invoke-WUJob -ComputerName $server -Script { Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot } -Confirm:$false -Verbose -RunNow
    }
    catch {
        Write-Host 'Error installing updates on' $server -ForegroundColor RED
        Write-Host 'Error:' $PSItem.Exception.Message -ForegroundColor RED
    }

    try {
        If ($null -eq (Get-Module -Name Test-PendingReboot -ListAvailable)) {
            Install-Module Test-PendingReboot -Force
        }
    }
    catch {
        Write-Host 'Error installing Test-PendingReboot on local machine' -ForegroundColor RED
        #$PSItem is the current Error
        Write-Host 'Error:' $PSItem.Exception.Message -ForegroundColor RED
    }
    #Checks if the server needs a reboot
    $needReboot = (Test-PendingReboot -ComputerName $server -SkipConfigurationManagerClientCheck -SkipPendingFileRenameOperationsCheck).isRebootPending

    #If the server does need a reboot
    if ($needReboot) {
        try {
            Invoke-Command -ComputerName $server -Scriptblock {
                #Sets the parts for the scheduled task in variables so the 'New-ScheduledTask' line is cleaner. 
                #Sets restartDate to 1 AM tomorrow. Gets the date, sets the time to 1 AM, adds 1 day.
                $restartDate = (Get-Date -Hour 1 -Minute 0 -Second 0 -Millisecond 0).AddDays(1)
                #Executes powershell, then runs the argument(s)
                $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument 'Restart-Computer -Force'
                #Run once, at the time specified in the restartDate variable
                $trigger = New-ScheduledTaskTrigger -Once -At $restartDate
                #Delete the task 1 second after it's expired
                $settings = New-ScheduledTaskSettingsSet  -DeleteExpiredTaskAfter 00:00:01
                #Run as 'system'
                $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
                #Schedule a task using the variables defined above
                $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal
                #Register the scheduled task defined above in the task variable. The pipe sets an end boundary (expiration) 2 minutes after it's executed. This is so the task can be deleted.
                Register-ScheduledTask 'RestartServer' -InputObject ( $task | % { $_.Triggers[0].EndBoundary = $restartDate.AddMinutes(2).ToString('s') ; $_ } )
                Write-Host 'Restart scheduled on' $restartDate
            }
        }
        catch {
            Write-Host 'Error scheduling restart for' $server -ForegroundColor RED
            Write-Host 'Error:' $PSItem.Exception.Message -ForegroundColor RED
        }
    }
    #If the server doesn't need a reboot, inform the user
    else {
        Write-Host 'Windows Update indicated that no reboot is required.'
    }
}