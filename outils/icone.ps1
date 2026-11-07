<#
.SYNOPSIS
    Dessine l'icône de Turbo X : src\TurboX.ico (le programme) et docs\images\icone.png (la présentation).

.DESCRIPTION
    Un carré graphite, un X ivoire et deux échos du X, comme des appuis en rafale.
    Chaque taille est dessinée à part, de 16 à 256 pixels. Jusqu'à 32 pixels, les mesures
    sont ajustées à la main et il ne reste que les chevrons des échos : tout reste net.
    Dans le .ico, les tailles jusqu'à 96 pixels sont rangées en BMP (lu partout),
    la 256 en PNG (bien plus léger), comme le recommande Microsoft.
    Près de l'horloge, Turbo X entoure lui-même ce logo de la couleur de son état.

.PARAMETER Dossier
    Où écrire TurboX.ico et icone.png. Par défaut : src\ et docs\images\ dans le projet.
    (outils\verifier.ps1 s'en sert pour vérifier que l'icône du dépôt est à jour.)

.EXAMPLE
    .\outils\icone.ps1
#>
[CmdletBinding()]
param(
    [string] $Dossier
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Get-Couleur {
    <#
    .SYNOPSIS
        Couleur de GDI+ d'après un code RRVVBB, avec une opacité de 0 (invisible) à 255.
    #>
    [CmdletBinding()]
    [OutputType('System.Drawing.Color')]
    param(
        [Parameter(Mandatory)]
        [string] $Code,
        [int] $Opacite = 255
    )

    $valeur = [Convert]::ToInt32($Code, 16)
    [System.Drawing.Color]::FromArgb($Opacite, ($valeur -shr 16) -band 0xFF, ($valeur -shr 8) -band 0xFF, $valeur -band 0xFF)
}

function Get-CheminArrondi {
    <#
    .SYNOPSIS
        Chemin d'un carré aux coins arrondis, de (Debut, Debut) à (Debut + Cote, Debut + Cote).
    #>
    [CmdletBinding()]
    [OutputType('System.Drawing.Drawing2D.GraphicsPath')]
    param(
        [Parameter(Mandatory)]
        [double] $Debut,
        [Parameter(Mandatory)]
        [double] $Cote,
        [Parameter(Mandatory)]
        [double] $Rayon
    )

    $chemin = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diametre = [float] (2 * $Rayon)
    $fin = [float] ($Debut + $Cote - 2 * $Rayon)
    $chemin.AddArc([float] $Debut, [float] $Debut, $diametre, $diametre, 180, 90)
    $chemin.AddArc($fin, [float] $Debut, $diametre, $diametre, 270, 90)
    $chemin.AddArc($fin, $fin, $diametre, $diametre, 0, 90)
    $chemin.AddArc([float] $Debut, $fin, $diametre, $diametre, 90, 90)
    $chemin.CloseFigure()
    $chemin
}

function Get-Mesure {
    <#
    .SYNOPSIS
        Mesures du logo pour une taille : marge et rayon de la plaque, centre (X, Y), demi-taille,
        inclinaison et épaisseur du X, distance et espace entre les échos, couleurs des échos.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [int] $Taille
    )

    # En petit, des mesures choisies à la main pour que chaque trait tombe juste sur les pixels,
    # et des échos plus clairs pour qu'ils restent visibles
    switch ($Taille) {
        16 { return @{ Marge = 1; Rayon = 3; X = 10; Y = 8; Demi = 3; Penche = 0; Trait = 2; Pas = 3.5; Espace = 1; Echos = @('A39D94') } }
        20 { return @{ Marge = 1; Rayon = 4; X = 12.5; Y = 10; Demi = 3.5; Penche = 0.1; Trait = 2.5; Pas = 3.2; Espace = 1; Echos = @('A39D94', '6E6962') } }
        24 { return @{ Marge = 1; Rayon = 5; X = 15; Y = 12; Demi = 4; Penche = 0.12; Trait = 3; Pas = 3.5; Espace = 1; Echos = @('A39D94', '6E6962') } }
        32 { return @{ Marge = 2; Rayon = 6.5; X = 20; Y = 16; Demi = 5.2; Penche = 0.15; Trait = 4; Pas = 4.4; Espace = 1.2; Echos = @('9A948B', '66615B') } }
    }
    # À partir de 40 pixels : les proportions du grand logo
    $marge = [math]::Round($Taille / 16)
    $cote = $Taille - 2 * $marge
    @{
        Marge = $marge; Rayon = 0.23 * $cote; X = $marge + 0.6 * $cote; Y = $marge + 0.5 * $cote; Demi = 0.2 * $cote; Penche = 0.18
        Trait = 0.13 * $cote; Pas = 0.12 * $cote; Espace = 0.035 * $cote; Echos = @('8E887F', '57524C')
    }
}

function Add-X {
    <#
    .SYNOPSIS
        Trace le X du logo, décalé vers la gauche pour un écho ; avec -Chevron, seulement sa moitié gauche.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Dessin,
        [Parameter(Mandatory)]
        [hashtable] $Mesure,
        [double] $Decalage = 0,
        [Parameter(Mandatory)]
        $Remplissage,
        [Parameter(Mandatory)]
        [double] $Epaisseur,
        [switch] $Chevron
    )

    $x = $Mesure.X - $Decalage
    $y = $Mesure.Y
    $demi = $Mesure.Demi
    $penche = $Mesure.Penche * $demi   # le haut du X part vers la droite : il avance
    $hautGauche = [System.Drawing.PointF]::new($x - $demi + $penche, $y - $demi)
    $basDroite = [System.Drawing.PointF]::new($x + $demi - $penche, $y + $demi)
    $hautDroite = [System.Drawing.PointF]::new($x + $demi + $penche, $y - $demi)
    $basGauche = [System.Drawing.PointF]::new($x - $demi - $penche, $y + $demi)
    $stylo = [System.Drawing.Pen]::new($Remplissage, $Epaisseur)
    $stylo.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $stylo.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $stylo.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    if ($Chevron) {
        $Dessin.DrawLines($stylo, [System.Drawing.PointF[]] @($hautGauche, [System.Drawing.PointF]::new($x, $y), $basGauche))
    }
    else {
        $Dessin.DrawLine($stylo, $hautGauche, $basDroite)
        $Dessin.DrawLine($stylo, $hautDroite, $basGauche)
    }
    $stylo.Dispose()
}

function Get-Logo {
    <#
    .SYNOPSIS
        Dessine le logo à une taille donnée, en pixels, et renvoie l'image.
    #>
    [CmdletBinding()]
    [OutputType('System.Drawing.Bitmap')]
    param(
        [Parameter(Mandatory)]
        [int] $Taille
    )

    $mesure = Get-Mesure -Taille $Taille
    $marge = $mesure.Marge
    $cote = $Taille - 2 * $marge
    $image = [System.Drawing.Bitmap]::new($Taille, $Taille, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $dessin = [System.Drawing.Graphics]::FromImage($image)
    $dessin.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $dessin.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half   # le pixel n va de n à n + 1
    $dessin.Clear([System.Drawing.Color]::Transparent)

    # La plaque : un carré aux coins arrondis, graphite en léger dégradé, avec un liseré clair en haut
    $plaque = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.PointF]::new(0, $marge - 1), [System.Drawing.PointF]::new(0, $marge + $cote + 1),
        (Get-Couleur -Code '36322E'), (Get-Couleur -Code '131211'))
    $plaque.WrapMode = [System.Drawing.Drawing2D.WrapMode]::TileFlipXY
    $forme = Get-CheminArrondi -Debut $marge -Cote $cote -Rayon $mesure.Rayon
    $dessin.FillPath($plaque, $forme)
    $trait = [math]::Max(1, $Taille / 128)
    $reflet = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.PointF]::new(0, $marge), [System.Drawing.PointF]::new(0, $marge + $cote),
        (Get-Couleur -Code 'FFFFFF' -Opacite 50), (Get-Couleur -Code 'FFFFFF' -Opacite 6))
    $reflet.WrapMode = [System.Drawing.Drawing2D.WrapMode]::TileFlipXY
    $styloReflet = [System.Drawing.Pen]::new($reflet, $trait)
    $bord = Get-CheminArrondi -Debut ($marge + $trait / 2) -Cote ($cote - $trait) -Rayon ($mesure.Rayon - $trait / 2)
    $dessin.DrawPath($styloReflet, $bord)

    # Les échos, du plus lointain au plus proche, puis le X : chacun creuse un petit espace
    # (de la couleur de la plaque) dans ce qu'il recouvre. En petit, seuls les chevrons des échos restent.
    $chevron = $Taille -le 32
    $creux = $mesure.Trait + 2 * $mesure.Espace
    for ($rang = $mesure.Echos.Count; $rang -ge 1; $rang--) {
        $decalage = $rang * $mesure.Pas
        if ($rang -lt $mesure.Echos.Count) {
            Add-X -Dessin $dessin -Mesure $mesure -Decalage $decalage -Remplissage $plaque -Epaisseur $creux -Chevron:$chevron
        }
        $echo = [System.Drawing.SolidBrush]::new((Get-Couleur -Code $mesure.Echos[$rang - 1]))
        Add-X -Dessin $dessin -Mesure $mesure -Decalage $decalage -Remplissage $echo -Epaisseur $mesure.Trait -Chevron:$chevron
        $echo.Dispose()
    }
    Add-X -Dessin $dessin -Mesure $mesure -Remplissage $plaque -Epaisseur $creux
    $ivoire = [System.Drawing.SolidBrush]::new((Get-Couleur -Code 'EEE9E2'))
    Add-X -Dessin $dessin -Mesure $mesure -Remplissage $ivoire -Epaisseur $mesure.Trait

    foreach ($objet in $ivoire, $styloReflet, $bord, $reflet, $forme, $plaque, $dessin) {
        $objet.Dispose()
    }
    $image
}

function ConvertTo-EntreeIco {
    <#
    .SYNOPSIS
        Octets d'une image pour un fichier .ico : PNG à partir de 256 pixels, sinon BMP 32 bits
        (couleurs et transparence de bas en haut, puis le masque, un bit par pixel).
    #>
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        $Image
    )

    $flux = [System.IO.MemoryStream]::new()
    $taille = $Image.Width
    if ($taille -ge 256) {
        $Image.Save($flux, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    else {
        $zone = [System.Drawing.Rectangle]::new(0, 0, $taille, $taille)
        $donnees = $Image.LockBits($zone, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $pixels = [byte[]]::new(4 * $taille * $taille)   # bleu, vert, rouge, opacité ; ligne par ligne, de haut en bas
        [System.Runtime.InteropServices.Marshal]::Copy($donnees.Scan0, $pixels, 0, $pixels.Length)
        $Image.UnlockBits($donnees)
        $octetsMasque = [math]::Ceiling($taille / 32) * 4   # chaque ligne du masque fait un multiple de 4 octets

        $ecrivain = [System.IO.BinaryWriter]::new($flux)
        $ecrivain.Write([uint32] 40)                 # en-tête BITMAPINFOHEADER
        $ecrivain.Write([int32] $taille)
        $ecrivain.Write([int32] (2 * $taille))       # hauteur comptée deux fois : couleurs, puis masque
        $ecrivain.Write([uint16] 1)
        $ecrivain.Write([uint16] 32)
        $ecrivain.Write([uint32] 0)                  # sans compression
        $ecrivain.Write([uint32] ($pixels.Length + $octetsMasque * $taille))
        $ecrivain.Write([byte[]]::new(16))           # résolution et palette : inutiles
        for ($ligne = $taille - 1; $ligne -ge 0; $ligne--) {
            $ecrivain.Write($pixels, 4 * $taille * $ligne, 4 * $taille)
        }
        for ($ligne = $taille - 1; $ligne -ge 0; $ligne--) {
            $masque = [byte[]]::new($octetsMasque)
            for ($colonne = 0; $colonne -lt $taille; $colonne++) {
                if ($pixels[4 * ($taille * $ligne + $colonne) + 3] -eq 0) {   # pixel tout à fait transparent
                    $masque[$colonne -shr 3] = $masque[$colonne -shr 3] -bor (0x80 -shr ($colonne -band 7))
                }
            }
            $ecrivain.Write($masque)
        }
        $ecrivain.Flush()
    }
    , $flux.ToArray()
}

$racine = Split-Path -Path $PSScriptRoot -Parent
if ($Dossier) {
    $null = New-Item -ItemType Directory -Force -Path $Dossier
    $cheminIco = Join-Path -Path $Dossier -ChildPath 'TurboX.ico'
    $cheminPng = Join-Path -Path $Dossier -ChildPath 'icone.png'
}
else {
    $cheminIco = Join-Path -Path $racine -ChildPath 'src\TurboX.ico'
    $cheminPng = Join-Path -Path $racine -ChildPath 'docs\images\icone.png'
}

# Les tailles dont Windows se sert : 16 à 32 pixels pour les petites icônes (de 100 à 200 %),
# 32 à 96 pour les grandes, 256 pour les très grandes de l'Explorateur
$tailles = 16, 20, 24, 32, 40, 48, 64, 96, 256
$images = foreach ($taille in $tailles) { Get-Logo -Taille $taille }
$entrees = foreach ($image in $images) { , (ConvertTo-EntreeIco -Image $image) }

# Le fichier .ico : un en-tête, une ligne par taille (dimensions, poids, position), puis les images
$flux = [System.IO.MemoryStream]::new()
$ecrivain = [System.IO.BinaryWriter]::new($flux)
$ecrivain.Write([uint16] 0)
$ecrivain.Write([uint16] 1)                          # 1 = icône
$ecrivain.Write([uint16] $tailles.Count)
$position = 6 + 16 * $tailles.Count
for ($rang = 0; $rang -lt $tailles.Count; $rang++) {
    $ecrivain.Write([byte] ($tailles[$rang] % 256))  # largeur, puis hauteur (0 veut dire 256)
    $ecrivain.Write([byte] ($tailles[$rang] % 256))
    $ecrivain.Write([uint16] 0)                      # pas de palette
    $ecrivain.Write([uint16] 1)                      # un plan
    $ecrivain.Write([uint16] 32)                     # 32 bits par pixel
    $ecrivain.Write([uint32] $entrees[$rang].Length)
    $ecrivain.Write([uint32] $position)
    $position += $entrees[$rang].Length
}
foreach ($entree in $entrees) {
    $ecrivain.Write($entree)
}
$ecrivain.Flush()
[System.IO.File]::WriteAllBytes($cheminIco, $flux.ToArray())
$images[-1].Save($cheminPng, [System.Drawing.Imaging.ImageFormat]::Png)
foreach ($image in $images) {
    $image.Dispose()
}

Write-Output "Icône de Turbo X dessinée en $($tailles.Count) tailles, de 16 à 256 pixels : $cheminIco et $cheminPng"
