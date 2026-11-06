<#
.SYNOPSIS
    Fabrique TurboX.exe et l'archive à publier, à partir de src\TurboX.ahk.

.DESCRIPTION
    Utilise les versions officielles figées d'AutoHotkey (base de l'exe) et d'Ahk2Exe,
    décrites dans outils\versions.psd1 et vérifiées par empreinte SHA-256.
    Résultat dans dist\ : TurboX.exe, TurboX-<version>.zip et SHA256SUMS.txt.

.EXAMPLE
    .\outils\compiler.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path -Path $PSScriptRoot -ChildPath 'commun.ps1')

$racine = Split-Path -Path $PSScriptRoot -Parent
$script = Join-Path -Path $racine -ChildPath 'src\TurboX.ahk'
$version = Get-VersionScript -Chemin $script
$dist = Join-Path -Path $racine -ChildPath 'dist'
if (Test-Path -LiteralPath $dist) {
    Remove-Item -LiteralPath $dist -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $dist

# L'exe : le script et l'interpréteur AutoHotkey v2 réunis en un seul fichier
$base = Join-Path -Path (Get-OutilFige -Nom 'AutoHotkey') -ChildPath 'AutoHotkey64.exe'
$ahk2exe = Join-Path -Path (Get-OutilFige -Nom 'Ahk2Exe') -ChildPath 'Ahk2Exe.exe'
$exe = Join-Path -Path $dist -ChildPath 'TurboX.exe'
$sortie = [System.IO.Path]::GetTempFileName()
$sortieErreur = [System.IO.Path]::GetTempFileName()
$parametres = @{
    FilePath               = $ahk2exe
    ArgumentList           = '/in', "`"$script`"", '/out', "`"$exe`"", '/base', "`"$base`"", '/silent', 'verbose'
    NoNewWindow            = $true
    Wait                   = $true
    PassThru               = $true
    RedirectStandardOutput = $sortie
    RedirectStandardError  = $sortieErreur
}
$processus = Start-Process @parametres
$message = ((Get-Content -LiteralPath $sortie, $sortieErreur -Raw -Encoding UTF8) -join '').Trim()
Remove-Item -LiteralPath $sortie, $sortieErreur -Force
if ($processus.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $exe)) {
    throw "Ahk2Exe n'a pas pu fabriquer TurboX.exe (code $($processus.ExitCode)). $message"
}

# L'archive à télécharger : l'exe et la licence
$licence = Join-Path -Path $dist -ChildPath 'LICENSE.txt'
Copy-Item -LiteralPath (Join-Path -Path $racine -ChildPath 'LICENSE') -Destination $licence
$archive = Join-Path -Path $dist -ChildPath "TurboX-$version.zip"
Compress-Archive -LiteralPath $exe, $licence -DestinationPath $archive
Remove-Item -LiteralPath $licence

# Les empreintes, pour vérifier un téléchargement
$lignes = foreach ($fichier in Get-Item -LiteralPath $exe, $archive) {
    '{0}  {1}' -f (Get-FileHash -LiteralPath $fichier.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $fichier.Name
}
[System.IO.File]::WriteAllText((Join-Path -Path $dist -ChildPath 'SHA256SUMS.txt'), ($lignes -join "`n") + "`n")

Write-Output "Turbo X $version fabriqué dans dist\ : TurboX.exe, TurboX-$version.zip, SHA256SUMS.txt"
