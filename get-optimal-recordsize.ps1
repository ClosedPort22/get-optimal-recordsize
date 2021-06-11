param (
	[Parameter(Mandatory)][ValidateRange(0,3)][int]$RAIDZLevel, # specify 0 for striped or mirrored pools
	[Parameter(Mandatory)][int]$StripeWidth, # =the number of disks in each vdev(?)
	[int]$MaxExponent=20, # 1m
	[int]$ashift=12,
	[ValidateScript({Test-Path -LiteralPath $_}, ErrorMessage="The specified directory does not exist.")][string]$Path='.',
	[int]$AvgMetadataPerBlock=97 # Empirical value for compressed metadata
)
$MinPower=12 # 4k
$MinStripeSize=$RAIDZLevel+1
$SectorSize=[Math]::Pow(2,$ashift)
$FileList=gci -File -Path $Path -Recurse
$DataSize=($FileList|measure -Sum Length).Sum
Write-Host "Data size is $DataSize bytes"
for($i=$MinPower;$i -le $MaxExponent;++$i){
	$CurrentRecordSize=[Math]::Pow(2,$i)
	$ActualSize=0
	foreach($Item in $FileList){
		#Write-Verbose ($Item|Format-Table Name,Length|Out-String)
		if($Item.Length -ge $CurrentRecordSize){
			$DataBlockCount=[Math]::Ceiling($Item.Length/$CurrentRecordSize)
			$BlockSize=$CurrentRecordSize
		}else{
			$DataBlockCount=1
			$BlockSize=[Math]::Ceiling($Item.Length/$SectorSize)*$SectorSize
		}
		#Write-Verbose "This file has $DataBlockCount block(s)"
		$SectorsPerBlock=$BlockSize/$SectorSize
		$Parity=[Math]::Ceiling($SectorsPerBlock/($StripeWidth-$RAIDZLevel))*$RAIDZLevel
		$BloatedSectorCount=[Math]::Ceiling(($SectorsPerBlock+$Parity)/$MinStripeSize)*$MinStripeSize
		#Write-Verbose "Each block has $Parity parity sectors, occupies $BloatedSectorCount sectors in total"
		$Theoretical=$SectorsPerBlock*$StripeWidth/($StripeWidth-$RAIDZLevel)
		#Write-Verbose "Each block ideally occupies $Theoretical sectors"
		$ActualSize+=[Math]::Ceiling($DataBlockCount*($BlockSize*$BloatedSectorCount/$Theoretical+$AvgMetadataPerBlock))
	}
	$Overhead=$ActualSize/$DataSize-1
	New-Object psobject -Property ([ordered]@{'Record Size'=$CurrentRecordSize;'Actual Size'=$ActualSize;'Overhead %'=[String]::Format('{0:P2}', $Overhead)})
}