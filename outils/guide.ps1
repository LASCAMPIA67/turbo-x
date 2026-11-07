<#
.SYNOPSIS
    Fabrique le guide LISEZ-MOI.html à partir de README.md : une seule page, lisible sans Internet.

.DESCRIPTION
    Le guide reprend la présentation du projet (README.md), sans ce qui ne sert que sur GitHub :
    le titre, et les parties entre <!-- hors-guide --> et <!-- /hors-guide -->.
    Les images sont rangées dans la page elle-même et les liens vers les autres fichiers du dépôt
    mènent à GitHub : le fichier se suffit à lui-même et s'ouvre d'un double-clic.
    Mise en page aux couleurs de Turbo X, claire ou sombre comme Windows, prête à imprimer.
    Un lien interne qui ne mène à aucun titre arrête la fabrication.

.PARAMETER Sortie
    Chemin du guide à écrire. Par défaut : dist\LISEZ-MOI.html.

.EXAMPLE
    .\outils\guide.ps1
#>
#Requires -Version 7.2
[CmdletBinding()]
param(
    [string] $Sortie
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path -Path $PSScriptRoot -ChildPath 'commun.ps1')

$racine = Split-Path -Path $PSScriptRoot -Parent
$depot = 'https://github.com/LASCAMPIA67/turbo-x'
$version = Get-VersionScript -Chemin (Join-Path -Path $racine -ChildPath 'src\TurboX.ahk')
if (-not $Sortie) {
    $Sortie = Join-Path -Path $racine -ChildPath 'dist\LISEZ-MOI.html'
}

function ConvertTo-Ancre {
    <#
    .SYNOPSIS
        Ancre d'un titre, calculée comme sur GitHub : en minuscules, sans ponctuation, espaces changés
        en tirets, accents gardés. Les liens de README.md marchent ainsi aussi dans le guide.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Titre
    )

    $texte = [System.Net.WebUtility]::HtmlDecode(($Titre -replace '<[^>]+>', '')).Trim().ToLowerInvariant()
    ($texte -replace '[^\p{L}\p{M}\p{N}\p{Pc} -]', '') -replace ' ', '-'
}

function ConvertTo-ImageIntegree {
    <#
    .SYNOPSIS
        Une image du dépôt, écrite dans la page elle-même (adresse « data: » en base 64).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Chemin
    )

    'data:image/png;base64,' + [Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Join-Path -Path $racine -ChildPath $Chemin)))
}

# 1. Le texte : README.md sans son titre (le guide a le sien) ni les parties réservées à GitHub
$texte = [System.IO.File]::ReadAllText((Join-Path -Path $racine -ChildPath 'README.md'), [System.Text.Encoding]::UTF8)
$texte = $texte -replace '\A# [^\n]*\n', ''
$texte = $texte -replace '(?s)<!-- hors-guide -->.*?<!-- /hors-guide -->[ \t]*\n?', ''
$html = (ConvertFrom-Markdown -InputObject $texte).Html

# 2. Les titres : ancres calculées comme sur GitHub (un même titre deux fois : -1, -2…),
#    que le convertisseur leur en ait donné une ou non
$ancres = [System.Collections.Generic.Dictionary[string, int]]::new()   # combien de fois chaque titre
$ids = [System.Collections.Generic.HashSet[string]]::new()                 # toutes les ancres du guide
$sommaire = [System.Collections.Generic.List[string]]::new()
$html = [regex]::Replace($html, '<h([2-6])(?: id="[^"]*")?>(.*?)</h\1>', {
        param($titre)
        $ancre = ConvertTo-Ancre -Titre $titre.Groups[2].Value
        if ($ancres.ContainsKey($ancre)) {
            $ancres[$ancre]++
            $ancre = "$ancre-$($ancres[$ancre])"
        }
        else {
            $ancres[$ancre] = 0
        }
        $null = $ids.Add($ancre)
        if ($titre.Groups[1].Value -eq '2') {
            $sommaire.Add("<li><a href=`"#$ancre`">$($titre.Groups[2].Value)</a></li>")
        }
        "<h$($titre.Groups[1].Value) id=`"$ancre`">$($titre.Groups[2].Value)</h$($titre.Groups[1].Value)>"
    })

# 3. Les liens : vers un titre du guide (vérifié), vers un fichier du dépôt (sur GitHub), vers le Web (nouvel onglet)
$casses = [System.Collections.Generic.List[string]]::new()
$html = [regex]::Replace($html, 'href="#([^"]+)"', {
        param($lien)
        $ancre = [System.Uri]::UnescapeDataString($lien.Groups[1].Value)
        if (-not $ids.Contains($ancre)) {
            $casses.Add($ancre)
        }
        "href=`"#$ancre`""
    })
if ($casses.Count) {
    throw "README.md : lien vers un titre absent du guide : #$($casses -join ', #')"
}
$html = $html -replace 'href="(?!https?:|#|mailto:)([^"]+)"', "href=`"$depot/blob/main/`$1`""
$html = $html -replace '<a href="(https?:[^"]+)"', '<a href="$1" target="_blank" rel="noopener"'

# 4. Les images, rangées dans la page
$html = [regex]::Replace($html, 'src="(docs/images/[^"]+\.png)"', {
        param($image)
        "src=`"$(ConvertTo-ImageIntegree -Chemin $image.Groups[1].Value)`""
    })

# 5. Les encadrés « > [!NOTE] » de GitHub (écrits en encadrés par les versions récentes du
#    convertisseur, en simples citations par les plus anciennes) : le même encadré dans les deux cas
$titresEncadres = @{ NOTE = 'À savoir'; TIP = 'Astuce'; IMPORTANT = 'Important'; WARNING = 'Attention'; CAUTION = 'Prudence' }
$html = [regex]::Replace($html, '(?s)<div class="markdown-alert markdown-alert-(\w+)">\s*<p class="markdown-alert-title">.*?</p>', {
        param($encadre)
        "<div class=`"encadre`"><p class=`"encadre-titre`">$($titresEncadres[$encadre.Groups[1].Value.ToUpperInvariant()])</p>"
    })
$html = [regex]::Replace($html, '(?s)<blockquote>\s*<p>\[!(\w+)\]\s*(.*?)</blockquote>', {
        param($encadre)
        "<div class=`"encadre`"><p class=`"encadre-titre`">$($titresEncadres[$encadre.Groups[1].Value])</p><p>$($encadre.Groups[2].Value)</div>"
    })

# 6. La page : en-tête avec le logo, sommaire, guide, pied de page
$page = @'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>Turbo X : guide d'utilisation</title>
<style>
:root {
  color-scheme: light dark;
  --fond: #f6f3ee; --surface: #ece7df; --ligne: #dcd5ca; --texte: #1f1d1a; --doux: #5e5850;
  --lien: #8a5a12; --encadre: #cfa359;
}
@media (prefers-color-scheme: dark) {
  :root { --fond: #131211; --surface: #1f1d1b; --ligne: #2f2c29; --texte: #eee9e2; --doux: #a39d94; --lien: #e2c08d; }
}
@media (prefers-reduced-motion: no-preference) { html { scroll-behavior: smooth; } }
* { box-sizing: border-box; }
body {
  margin: 0 auto; max-width: 48rem; padding: 2.5rem 1.25rem 4rem;
  background: var(--fond); color: var(--texte);
  font: 17px/1.6 "Segoe UI Variable Text", "Segoe UI", system-ui, sans-serif;
}
h1, h2, h3 { font-family: "Segoe UI Variable Display", "Segoe UI", system-ui, sans-serif; font-weight: 600; line-height: 1.25; }
h2 { margin: 3rem 0 1rem; padding-top: 1.5rem; border-top: 1px solid var(--ligne); font-size: 1.6rem; }
h3 { margin: 2rem 0 .75rem; font-size: 1.25rem; }
a { color: var(--lien); text-underline-offset: .15em; }
img { max-width: 100%; height: auto; }
p > img:only-child { display: block; margin: 1.5rem auto; }
ul, ol { padding-left: 1.5rem; }
li { margin: .3rem 0; }
code, kbd, pre { font-family: "Cascadia Mono", Consolas, monospace; font-size: .88em; }
code { padding: .1em .35em; border-radius: 4px; background: var(--surface); }
pre { padding: .9rem 1rem; overflow-x: auto; border-radius: 8px; background: var(--surface); }
pre code { padding: 0; background: none; }
kbd {
  padding: .1em .45em; border: 1px solid var(--ligne); border-bottom-width: 3px; border-radius: 6px;
  background: var(--surface); font-family: "Segoe UI", system-ui, sans-serif; font-weight: 600; white-space: nowrap;
}
table { width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: .95em; }
th, td { padding: .5rem .75rem; border: 1px solid var(--ligne); text-align: left; vertical-align: top; }
th { background: var(--surface); }
.encadre { margin: 1.5rem 0; padding: .8rem 1.1rem; border-left: 4px solid var(--encadre); border-radius: 6px; background: var(--surface); }
.encadre p { margin: .4rem 0; }
.encadre-titre { font-weight: 600; }
header { display: flex; align-items: center; gap: 1.25rem; margin-bottom: 2rem; }
header h1 { margin: 0; font-size: 2.6rem; }
header p { margin: .2rem 0 0; color: var(--doux); }
nav { padding: 1rem 1.5rem; border-radius: 12px; background: var(--surface); }
nav p { margin: 0 0 .5rem; font-weight: 600; }
nav ol { margin: 0; columns: 2 14rem; column-gap: 2rem; }
nav li { margin: .2rem 0; break-inside: avoid; }
footer { margin-top: 4rem; padding-top: 1.5rem; border-top: 1px solid var(--ligne); color: var(--doux); font-size: .9em; }
@media print {
  :root { --fond: #fff; --surface: #f1f1f1; --texte: #000; --doux: #444; --lien: #000; }
  body { max-width: none; padding: 0; font-size: 11pt; }
  h2, h3 { break-after: avoid; }
  img, table, pre, .encadre { break-inside: avoid; }
}
</style>
</head>
<body>
<header>
<img src="{{LOGO}}" alt="" width="88" height="88">
<div>
<h1>Turbo X</h1>
<p>Guide d'utilisation · version {{VERSION}}</p>
</div>
</header>
<nav aria-label="Sommaire">
<p>Sommaire</p>
<ol>
{{SOMMAIRE}}
</ol>
</nav>
<main>
{{CONTENU}}
</main>
<footer>
<p>Ce guide est aussi en ligne, toujours à jour : <a href="{{DEPOT}}#readme" target="_blank" rel="noopener">la page de Turbo X sur GitHub</a>.</p>
<p>Turbo X {{VERSION}} · licence MIT</p>
</footer>
</body>
</html>
'@
$page = $page.Replace('{{LOGO}}', (ConvertTo-ImageIntegree -Chemin 'docs/images/icone.png')).Replace('{{VERSION}}', $version)
$page = $page.Replace('{{SOMMAIRE}}', ($sommaire -join "`n")).Replace('{{DEPOT}}', $depot).Replace('{{CONTENU}}', $html.Trim())

$null = New-Item -ItemType Directory -Force -Path (Split-Path -Path $Sortie -Parent)
[System.IO.File]::WriteAllText($Sortie, $page.ReplaceLineEndings("`n"), [System.Text.UTF8Encoding]::new($false))
Write-Output "Guide de Turbo X $version fabriqué : $Sortie ($([math]::Round((Get-Item -LiteralPath $Sortie).Length / 1KB)) Ko)"
