param (
	[int]$MaxPower=20, # 1m
	[int]$ashift=12,
	[ValidateScript({Test-Path -LiteralPath $_}, ErrorMessage="The specified directory does not exist.")][string]$Path='.',
	[int]$AvgMetadataPerBlock=97 # Empirical value for compressed metadata
)
$MinPower=12 # 4k
$SectorSize=[Math]::Pow(2,$ashift)
$FileList=gci -File -Path $Path -Recurse
$DataSize=(gci -path $Path -File -Recurse|measure -Sum Length).Sum
Write-Host "Data size is $DataSize bytes"
for($i=$MinPower;$i -le $MaxPower;++$i){
	$Current=[Math]::Pow(2,$i)
	$ActualSize=0
	foreach($Item in $FileList){
		$Unit=if($Item.Length -ge $Current){$Current}else{$SectorSize}
		$ActualSize+=[Math]::Ceiling($Item.Length/$Unit)*($Unit+$AvgMetadataPerBlock)
	}
	$Overhead=($ActualSize-$DataSize)/$DataSize
	New-Object psobject -Property ([ordered]@{'Record Size'=$Current;'Actual Size'=$ActualSize;'Slack Space'=$ActualSize-$DataSize;'Slack Space %'=[String]::Format('{0:P2}', $Overhead)})
}