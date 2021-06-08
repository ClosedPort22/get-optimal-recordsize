param (
	[int]$MaxPower=20, # 1m
	[int]$ashift=12,
	[string]$Path='.',
	[int]$AvgMetadataPerBlock=97 # Empirical value for COMPRESSED metadata
)

$MinPower=12 # 4k
$SectorSize=[Math]::Pow(2,$ashift)
$List=gci -File -Path $Path -Recurse
$DataSize=0
foreach($Item in $List){
	$DataSize+=$Item.Length
}
Write-Host "Data size is $DataSize bytes"
for($i=$MinPower;$i -le $MaxPower;++$i){
	$Current=[Math]::Pow(2,$i)
	$ActualSize=0
	foreach($Item in $List){
		if($Item.Length -ge $Current){
			$ActualSize+=([Math]::Ceiling($Item.Length/$Current)*($Current+$AvgMetadataPerBlock))
			continue
		}
		$ActualSize+=([Math]::Ceiling($Item.Length/$SectorSize)*($SectorSize+$AvgMetadataPerBlock))
	}
	$Overhead=($ActualSize-$DataSize)/$DataSize
	New-Object psobject -Property ([ordered]@{'Record Size'=$Current;'Actual Size'=$ActualSize;'Slack Space'=$ActualSize-$DataSize;'Slack Space %'=[String]::Format('{0:P2}', $Overhead)})
}