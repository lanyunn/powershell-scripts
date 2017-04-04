﻿<########

Configuration and starting time tracking
URL for details:
http://www.freenode-windows.org/resources/vista-7/windows-update

#########>
$StartDate = Get-Date
$scriptname = "WindowsUpdatePatch.ps1"
$logfile= "WindowsUpdatePatch.log"
$pcname = $env:computername

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$dir = (Get-Item -Path $dir -Verbose).FullName

<#

function to check for reboots

#>

function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
}

<########

Download function for updates
uses the url provided and the output provided to download to the location of where the script is ran.

#########>

function Download-Updates(){
Param([string]$url, [string]$output)
    
    $start_time = Get-Date

    $out = "$dir\$output"

    if(test-path $out){

        "${output} already downloaded" |Out-File -Append $outfile
    }else{
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $out)

        $end_time = Get-date
        $TimeSpent = New-TimeSpan -Start $start_time -End $end_time
        $TotalMinutes = $TimeSpent.TotalMinutes 
        $Data = "${pcname}, ${output}, ${TotalMinutes}, ${start_time}, ${end_time}"
        $outfile ="${dir}\${logfile}"
        $Data |Out-File -Append $outfile
    }
    
}

<########

running download functions
-output is the final file names
-url is the dowload link

#########>

Download-Updates -output "1.KB3020369x32.msu" -url "http://download.windowsupdate.com/d/msdownload/update/software/updt/2015/04/windows6.1-kb3020369-x86_82e168117c23f7c479a97ee96c82af788d07452e.msu"
Download-Updates -output "2.KB3172605x32.msu" -url "http://download.windowsupdate.com/d/msdownload/update/software/updt/2016/09/windows6.1-kb3172605-x86_ae03ccbd299e434ea2239f1ad86f164e5f4deeda.msu"
Download-Updates -output "3.KB3125574x32.msu" -url "http://download.windowsupdate.com/d/msdownload/update/software/updt/2016/05/windows6.1-kb3125574-v4-x86_ba1ff5537312561795cc04db0b02fbb0a74b2cbd.msu"

<###########

Prep for windows update patch
###########>

$rmpth = 'c:\windows\softwaredistribution\WuRedir\'
$ws = get-service wuauserv
$outfile ="${dir}\${logfile}"

if($ws.Status -eq "Stopped"){
	"Update Service Stopped" | out-file -Append $outfile
}else{
    "Stopping Update Service" | out-file -Append $outfile
	stop-service wuauserv -Force
}

if(test-path $rmpth){
    "Removing ${rmpth}" | out-file -Append $outfile
	remove-item $rmpth -Force -Confirm:$false -Recurse
}

<###########

installing windows update patch using the scripts directory

#########>


Foreach($item in (ls $dir *.msu -Name))
{

    if(Test-PendingReboot){
        Restart-Computer -Wait
    }
    echo $item
    $item = $dir + "\" + $item
    if($item -contains "3.KB"){
        wusa $item /quiet /forcerestart | Out-Null
    }
    
    wusa $item /quiet /norestart | Out-Null
    "${item} installed" | Out-File -Append $outfile
}
<###########

Ending script and time tracking

#########>

$EndDate = Get-Date
$TimeSpent = New-TimeSpan -Start $StartDate -End $EndDate
$TotalMinutes = $TimeSpent.TotalMinutes 
$Data = "${pcname}, ${scriptname}, ${TotalMinutes}, ${StartDate}, ${EndDate}"
$totaltime ="${dir}\timetracking.txt"
$Data |Out-File -Append $totaltime