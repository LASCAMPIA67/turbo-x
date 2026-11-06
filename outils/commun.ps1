# Fonctions partagées par les outils de Turbo X (verifier.ps1, compiler.ps1).

function Get-OutilFige {
    <#
    .SYNOPSIS
        Renvoie le dossier d'un outil officiel figé dans versions.psd1 (AutoHotkey ou Ahk2Exe).
    .DESCRIPTION
        La première fois, l'outil est téléchargé dans outils\.cache, puis son empreinte SHA-256
        est vérifiée avant de le décompresser. Une empreinte différente arrête tout.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AutoHotkey', 'Ahk2Exe')]
        [string] $Nom
    )

    $outil = (Import-PowerShellDataFile -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'versions.psd1'))[$Nom]
    $dossier = Join-Path -Path $PSScriptRoot -ChildPath ".cache\$Nom-$($outil.Version)"
    if (Test-Path -LiteralPath $dossier) {
        return $dossier
    }

    $archive = "$dossier.zip"
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Path $archive -Parent)
    $ProgressPreference = 'SilentlyContinue'   # la barre de progression ralentit beaucoup le téléchargement
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $outil.Url -OutFile $archive -UseBasicParsing
    $empreinte = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($empreinte -ne $outil.Sha256) {
        Remove-Item -LiteralPath $archive -Force
        throw "Empreinte inattendue pour $Nom : $empreinte au lieu de $($outil.Sha256)."
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $dossier -Force
    Remove-Item -LiteralPath $archive -Force
    return $dossier
}

function Get-AutoHotkey {
    <#
    .SYNOPSIS
        Chemin de AutoHotkey64.exe : celui demandé, sinon celui installé sur le PC, sinon la version figée.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string] $Chemin
    )

    if ($Chemin) {
        return $Chemin
    }
    $installe = Join-Path -Path $env:ProgramFiles -ChildPath 'AutoHotkey\v2\AutoHotkey64.exe'
    if (Test-Path -LiteralPath $installe) {
        return $installe
    }
    return Join-Path -Path (Get-OutilFige -Nom 'AutoHotkey') -ChildPath 'AutoHotkey64.exe'
}

function Get-VersionScript {
    <#
    .SYNOPSIS
        Version de Turbo X écrite dans le script ; vérifie qu'elle est la même pour l'exe (;@Ahk2Exe-SetVersion).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Chemin
    )

    $texte = [System.IO.File]::ReadAllText($Chemin, [System.Text.Encoding]::UTF8)
    $version = [regex]::Match($texte, '(?m)^VERSION\s*:=\s*"(\d+\.\d+\.\d+)"').Groups[1].Value
    $versionExe = [regex]::Match($texte, '(?m)^;@Ahk2Exe-SetVersion\s+(\S+)').Groups[1].Value
    if (-not $version) {
        throw "VERSION introuvable dans $Chemin."
    }
    if ($versionExe -ne $version) {
        throw "Versions différentes dans $Chemin : VERSION = $version, ;@Ahk2Exe-SetVersion = $versionExe."
    }
    return $version
}
