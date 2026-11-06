<#
.SYNOPSIS
    Vérifie le projet Turbo X avant chaque envoi.

.DESCRIPTION
    1. Encodage et fins de ligne de chaque fichier du dépôt :
       .ahk, .ps1 et .psd1 en UTF-8 avec BOM et fins de ligne Windows (CRLF) ;
       les autres fichiers texte en UTF-8 sans BOM, avec fins de ligne LF.
    2. Version : VERSION et ;@Ahk2Exe-SetVersion identiques dans src\TurboX.ahk ;
       pour une publication, l'étiquette et le journal des modifications doivent suivre.
    3. AutoHotkey vérifie src\TurboX.ahk sans le lancer (/Validate).

.PARAMETER AutoHotkey
    Chemin de AutoHotkey64.exe. Par défaut : celui installé sur le PC,
    sinon la version officielle figée dans outils\versions.psd1.

.PARAMETER Etiquette
    Étiquette Git d'une publication (ex. v1.2.0) : doit correspondre à la version du script.

.EXAMPLE
    .\outils\verifier.ps1
#>
[CmdletBinding()]
param(
    [string] $AutoHotkey,
    [string] $Etiquette
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path -Path $PSScriptRoot -ChildPath 'commun.ps1')

$racine = Split-Path -Path $PSScriptRoot -Parent
$script = Join-Path -Path $racine -ChildPath 'src\TurboX.ahk'
$erreurs = [System.Collections.Generic.List[string]]::new()

# 1. Encodage et fins de ligne
$avecBom = '.ahk', '.ps1', '.psd1'
$binaires = '.png', '.ico', '.exe', '.zip'
$utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
$fichiers = @(git -C $racine -c core.quotepath=off ls-files --cached --others --exclude-standard)
foreach ($relatif in $fichiers) {
    $chemin = Join-Path -Path $racine -ChildPath $relatif
    $extension = [System.IO.Path]::GetExtension($chemin).ToLowerInvariant()
    if (-not (Test-Path -LiteralPath $chemin -PathType Leaf) -or $binaires -contains $extension) {
        continue
    }
    $octets = [System.IO.File]::ReadAllBytes($chemin)
    $bom = $octets.Length -ge 3 -and $octets[0] -eq 0xEF -and $octets[1] -eq 0xBB -and $octets[2] -eq 0xBF
    try {
        $texte = $utf8Strict.GetString($octets)
    }
    catch {
        $erreurs.Add("$relatif : ce n'est pas de l'UTF-8 valide")
        continue
    }
    $crlf = [regex]::Matches($texte, "`r`n").Count
    $lf = [regex]::Matches($texte, "(?<!`r)`n").Count
    if ($avecBom -contains $extension) {
        if (-not $bom) { $erreurs.Add("$relatif : il manque le BOM UTF-8") }
        if ($lf) { $erreurs.Add("$relatif : $lf fin(s) de ligne LF au lieu de CRLF") }
    }
    else {
        if ($bom) { $erreurs.Add("$relatif : BOM UTF-8 en trop") }
        if ($crlf) { $erreurs.Add("$relatif : $crlf fin(s) de ligne CRLF au lieu de LF") }
    }
    if ($texte.Length -and -not $texte.EndsWith("`n")) {
        $erreurs.Add("$relatif : il manque le saut de ligne final")
    }
}

# 2. Version
$version = Get-VersionScript -Chemin $script
if ($Etiquette) {
    if ($Etiquette -ne "v$version") {
        $erreurs.Add("l'étiquette $Etiquette ne correspond pas à la version du script ($version)")
    }
    $journal = [System.IO.File]::ReadAllText((Join-Path -Path $racine -ChildPath 'CHANGELOG.md'), [System.Text.Encoding]::UTF8)
    if ($journal -notmatch "(?m)^## \[$([regex]::Escape($version))\] - \d{4}-\d{2}-\d{2}") {
        $erreurs.Add("CHANGELOG.md : il manque la partie « [$version] - date »")
    }
}

# 3. AutoHotkey vérifie le script sans le lancer
$ahk = Get-AutoHotkey -Chemin $AutoHotkey
$sortie = [System.IO.Path]::GetTempFileName()
$sortieErreur = [System.IO.Path]::GetTempFileName()
$parametres = @{
    FilePath               = $ahk
    ArgumentList           = '/ErrorStdOut', '/Validate', "`"$script`""
    NoNewWindow            = $true
    Wait                   = $true
    PassThru               = $true
    RedirectStandardOutput = $sortie
    RedirectStandardError  = $sortieErreur
}
$processus = Start-Process @parametres
$message = ((Get-Content -LiteralPath $sortie, $sortieErreur -Raw -Encoding UTF8) -join '').Trim()
Remove-Item -LiteralPath $sortie, $sortieErreur -Force
if ($processus.ExitCode -ne 0) {
    $erreurs.Add("src/TurboX.ahk : AutoHotkey signale une erreur (code $($processus.ExitCode)) $message")
}

if ($erreurs.Count) {
    $prefixe = if ($env:GITHUB_ACTIONS) { '::error::' } else { 'ERREUR : ' }
    foreach ($erreur in $erreurs) {
        Write-Output "$prefixe$erreur"
    }
    exit 1
}
Write-Output "Tout est bon : Turbo X $version, $($fichiers.Count) fichiers vérifiés, script validé par AutoHotkey."
