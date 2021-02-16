Add-PSsnapin VMware.VimAutomation.Core

$vcserver="VCenterName"
$portvc="443"
$cred=Get-Credential

connect-VIServer $vcserver -port $portvc -credential $cred

#$VMHosts = get-content ".\HostPath.txt"
$VMHosts =  Get-VMHost  | Sort-Object -Property Name

	foreach ($VMHost in $VMHosts) {
    $esx = Get-VMHost -Name $vmhost
    $report = @()
    # fc or fnic for UCS VIC-Cards
	# Get-VMHostStorage -RescanAllHba -VMHost $esx | Out-Null
	foreach($hba in ($esx.ExtensionData.Config.StorageDevice.HostBusAdapter | Where-Object{$_.Driver -match 'fc' -or  $_.Driver -match 'fnic'-or  $_.Driver -match 'qla'})){
	  $paths = @()
      foreach($lun in $esx.ExtensionData.Config.StorageDevice.MultipathInfo.Lun){
        $paths += $lun.Path | Where-Object{$_.Adapter -match "$($hba.Device)" -and $_.Adapter -match 'FibreChannel'}
      }
      $groups = $paths | Group-Object -Property PathState
      $report += $hba | Select-Object @{N='VMHost';E={$esx.Name}},Device,
      @{N='Active';E={($groups | Where-Object-Object{$_.Name -eq 'active'}).Count}},
      @{N='Standby';E={($groups | Where-Object{$_.Name -eq 'standby'}).Count}},
      @{N='Dead';E={($groups | Where-Object{$_.Name -eq 'dead'}).Count}}
    }
    $report | Format-Table -AutoSize
  }

Disconnect-viserver $vcserver -confirm:$false
