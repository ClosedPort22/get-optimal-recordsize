param (
	[Parameter(Mandatory)][ValidateRange(1,3)][int]$RaidLevel,
	[Parameter(Mandatory)][int]$StripeWidth,
	[int]$ashift=12,
	[int]$MaxPower=20
)
$MinPower=12 # 4k
$ize=[Math]::Pow(2,$ashift)
$Min=$RaidLevel+1
Write-Host "Minimum sectors: $Min"
$(for($i=$MinPower;$i -le $MaxPower;++$i){
	$Data=[Math]::Pow(2,$i-$ashift)
	$Parity=[Math]::Ceiling($Data/($StripeWidth-$RaidLevel))*$RaidLevel
	$Max=[Math]::Ceiling(($Data+$Parity)/$Min)*$Min
	$Padding=$Max-$Data-$Parity
	$Theoretical=$Data*$StripeWidth/($StripeWidth-$RaidLevel)
	$Overhead=$Max/$Theoretical-1
	New-Object psobject -Property ([ordered]@{'Record Size'=[Math]::Pow(2,$i);'Max Sectors'=$Max;'Data Sectors'=$Data;'Parity Sectors'=$Parity;'Padding Sectors'=$Padding;'Theoretical'=$Theoretical.ToString("#.##");'Overhead'=[String]::Format('{0:P2}', $Overhead)})
})|Format-Table
