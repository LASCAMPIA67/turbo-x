<#
.SYNOPSIS
    Écrit les notes d'une publication : la partie de CHANGELOG.md pour cette version,
    puis le mode d'emploi du téléchargement.

.PARAMETER Version
    Numéro de version, par exemple 1.2.0.

.EXAMPLE
    .\outils\notes-version.ps1 -Version 0.2.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string] $Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$racine = Split-Path -Path $PSScriptRoot -Parent
$journal = [System.IO.File]::ReadAllText((Join-Path -Path $racine -ChildPath 'CHANGELOG.md'), [System.Text.Encoding]::UTF8)
$partie = [regex]::Match($journal, "(?ms)^## \[$([regex]::Escape($Version))\][^\n]*\n(.*?)(?=^## |^\[)")
if (-not $partie.Success) {
    throw "CHANGELOG.md : pas de partie pour la version $Version."
}
$depot = if ($env:GITHUB_REPOSITORY) { $env:GITHUB_REPOSITORY } else { 'LASCAMPIA67/turbo-x' }

@"
$($partie.Groups[1].Value.Trim())

## Installation

1. Télécharge **TurboX-$Version.zip** ci-dessous, puis décompresse-le où tu veux (clic droit sur le fichier, **Extraire tout**).
2. Double-clique sur **TurboX.exe** : la visite guidée, puis l'assistant de démarrage, te guident pas à pas.
3. Le guide complet, **LISEZ-MOI.html**, est rangé juste à côté : il se lit même sans Internet.

Si Windows affiche « Windows a protégé votre ordinateur », clique sur **Informations complémentaires**, puis sur **Exécuter quand même** : Turbo X n'est pas signé (un certificat de signature est payant).

## Vérifier le téléchargement

Ces fichiers ont été fabriqués par GitHub à partir du code de ce dépôt. Pour le vérifier avec [GitHub CLI](https://cli.github.com/) :

``````shell
gh attestation verify TurboX.exe --repo $depot
``````

Les empreintes SHA-256 sont aussi dans **SHA256SUMS.txt**.
"@
