Windows Update Remote Servers
------------------------------
This script will allow you to remotely install Windows updates on servers (that are running PowerShell 5 or above). 
To run it, all you need is to have a list of the servers to update at C://servers.txt on your machine, then run Powershell as admin and run ServerUpdates.ps1.

The servers.txt file must have a list of servers separated by a new line. It will put the value of each new line into an array and run for each of them.
An example servers.txt file that will update your local machine is included in this folder. If you use this, remember to move it to C:// or change the path in the script.



Troubleshooting:
-----------------
- Make sure PowerShell is run as admin

- Make sure you're connected to a VPN (if necessary)

- If you're getting the error "The term 'Install-Module' is not recognized..." make sure powershell is at least version 5. 
You can do this by running the following command from your own machine (Insert the name of the server you're having issues with):

Invoke-Command -ComputerName [ServerName] -Scriptblock {
    $PSVersionTable.PSVersion
}

If the PowerShell version is <=4, you'll have to upgrade to >=5 or install and import the module manually.



Useful Commands
----------------
PSWindowsUpdate:
Get-Command -Module PSWindowsUpdate: Shows the full list of commands available in this module. 

Get-WindowsUpdate: Lists the Windows updates available. Can also be used to download, install, or hide updates meeting predefined requisites, and set the rules of the restarts when installing the updates by using the following tags:
-Download: downloads approved updates but does not install them
-Install: installs approved updates
-Hide: hides specified updates to prevent them from being installed
-ScheduleJob: specifies the date when the job will start
-SendReport: sends a report from the installation process
-ComputerName: specifies target server or computer
-AutoReboot: automatically reboots system if required
-IgnoreReboot: suppresses automatic restarts
-ScheduleReboot: specifies the date when the system will be rebooted.

Remove-WindowsUpdate: Uninstalls an update

Get-WUHistory: Shows a list of installed updates

Get-WUInstallerStatus: Gets Windows Update Installer Status, whether it is busy or not

Enable-WURemoting: Enables firewall rules for PSWindowsUpdate remoting

Invoke-WUJob: Invokes PSWindowsUpdate actions remotely

(You can add -ComputerName [ServerName] to the end of most of these commands to run them on a remote machine. The ones that don't allow this will have to be run after Invoke-WUJob like in the update script) 



Powershell:

Invoke-Command -ComputerName [ServerName] -Scriptblock {  }: Runs the commands inside the block on the specified machine