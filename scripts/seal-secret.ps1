# Converts a Kubernetes Secret manifest into a SealedSecret using kubeseal.
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$SecretFile,

	[Parameter(Position = 1)]
	[string]$OutFile,

	[Parameter()]
	[ValidateSet('yaml', 'json')]
	[string]$Format = 'yaml',

	[Parameter()]
	[string]$ControllerNamespace = 'kube-system',

	[Parameter()]
	[string]$ControllerName = 'sealed-secrets',

	[Parameter()]
	[string]$CertFile,

	[Parameter()]
	[switch]$Force,

	[Parameter()]
    [ValidateSet('strict','namespace-wide','cluster-wide')]
    [string]$Scope = 'strict'
)

function Resolve-OutFile {
	param(
		[string]$SecretPath,
		[string]$ProvidedOutFile
	)

	if ($ProvidedOutFile) {
		return [System.IO.Path]::GetFullPath($ProvidedOutFile)
	}

	$secretFullPath = [System.IO.Path]::GetFullPath($SecretPath)
	$directory = [System.IO.Path]::GetDirectoryName($secretFullPath)
	$baseName = [System.IO.Path]::GetFileNameWithoutExtension($secretFullPath)
	$extension = [System.IO.Path]::GetExtension($secretFullPath)

	if (-not $extension) {
		$extension = '.yaml'
	}

	return [System.IO.Path]::Combine($directory, "$baseName.sealed$extension")
}

if (-not (Test-Path -Path $SecretFile -PathType Leaf)) {
	throw "Secret file '$SecretFile' not found."
}

$kubeseal = Get-Command -Name 'kubeseal' -ErrorAction SilentlyContinue
if (-not $kubeseal) {
	throw "kubeseal CLI not found in PATH. Install kubeseal before running this script."
}

$outputPath = Resolve-OutFile -SecretPath $SecretFile -ProvidedOutFile $OutFile

if ((Test-Path -Path $outputPath -PathType Leaf) -and -not $Force) {
	throw "Output file '$outputPath' already exists. Use -Force to overwrite."
}

$kubesealArgs = @('--format', $Format)

if ($CertFile) {
	if (-not (Test-Path -Path $CertFile -PathType Leaf)) {
		throw "Certificate file '$CertFile' not found."
	}
	$kubesealArgs += @('--cert', $CertFile)
} else {
	$kubesealArgs += @('--controller-namespace', $ControllerNamespace, '--controller-name', $ControllerName)
}

$kubesealArgs += @('--scope', $Scope)

$secretContent = Get-Content -Path $SecretFile -Raw
$sealedContent = $secretContent | & $kubeseal @kubesealArgs 2>&1

if ($LASTEXITCODE -ne 0) {
	throw "kubeseal failed with exit code ${LASTEXITCODE}:`n$sealedContent"
}

Set-Content -Path $outputPath -Value $sealedContent -Encoding UTF8

Write-Host "Sealed secret written to '$outputPath'."
