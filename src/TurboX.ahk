; ══════════════════════════════════════════════════════════════════════
;    TURBO X
;    Appuie sur X en boucle sur ta PS5, à travers chiaki-ng
;    https://github.com/LASCAMPIA67/turbo-x  ·  licence MIT
; ══════════════════════════════════════════════════════════════════════
;
;    F1          assistant de démarrage (liste qui se coche toute seule)
;    F8          démarrer / arrêter
;    F9 / F10    plus lent / plus rapide
;    F7          afficher / masquer le panneau
;    F6          changer le panneau de coin
;    F5          changer le panneau d'écran
;    Ctrl + F8   quitter
;
;    Menu : bouton ☰ du panneau, clic droit sur le panneau,
;    ou icône près de l'horloge.
;
;    Au lancement, l'assistant s'ouvre sur l'écran du jeu et Turbo X
;    ouvre chiaki-ng (connecté directement à la PS5 si elle est allumée).
;
;    Sécurité : rien n'est envoyé tant que la fenêtre chiaki-ng
;    n'est pas au premier plan et connectée à la PS5.
;    Mémoire : la cadence, le coin, l'écran du panneau et les sons
;    sont retenus d'une fois sur l'autre.
; ══════════════════════════════════════════════════════════════════════

#Requires AutoHotkey v2.0
#SingleInstance Force
DetectHiddenWindows(true)
SetWinDelay(-1)

; Bibliothèques réseau de Windows gardées chargées : sinon AutoHotkey les recharge
; à chaque appel et la recherche de la PS5 perdrait sa connexion en route
for dll in ["ws2_32", "iphlpapi"]
    DllCall("LoadLibrary", "Str", dll, "Ptr")

;@Ahk2Exe-SetName Turbo X
;@Ahk2Exe-SetDescription Turbo X
;@Ahk2Exe-SetVersion 0.2.0
;@Ahk2Exe-SetCopyright Licence MIT
;@Ahk2Exe-SetOrigFilename TurboX.exe
VERSION := "0.2.0"   ; à changer en même temps que la ligne « SetVersion » juste au-dessus

; ─────────────────────────────── RÉGLAGES ───────────────────────────────
TOUCHE         := "Enter"   ; touche du clavier qui fait X dans chiaki-ng
CADENCE_MS     := 200       ; un appui toutes les 200 ms (0,2 seconde)
CADENCE_MIN    := 100       ; le plus rapide autorisé (10 appuis par seconde)
CADENCE_MAX    := 1000      ; le plus lent autorisé (1 appui par seconde)
PAS_MS         := 50        ; ce que change chaque appui sur F9 / F10
APPUI_MS       := 60        ; durée de chaque appui
CIBLE          := "chiaki"  ; nom du programme dans lequel appuyer
VERIF_PS5      := true      ; n'appuyer que si chiaki-ng est connecté à la PS5 (false si tu joues par Internet)
SONS           := true      ; petits bips au démarrage et à l'arrêt (false = muet)
COIN           := 1         ; panneau : 1 haut-gauche, 2 haut-droite, 3 bas-droite, 4 bas-gauche
ECRAN          := 0         ; panneau : 0 = sur l'écran de chiaki-ng, 1 = écran le plus à gauche, 2 = le suivant…
OUVRIR_CHIAKI  := true      ; ouvrir chiaki-ng tout seul au lancement de Turbo X
CONNEXION_AUTO := true      ; si la PS5 est allumée, connecter chiaki-ng tout seul (false = tu cliques toi-même)

; ─────────────────────────────── THÈME ───────────────────────────────
; Graphite chaud et ivoire. La couleur ne sert qu'à dire l'état :
; vert = actif ou validé, ambre = en pause ou en cours, rouge = arrêté ou pas encore validé.
C_FOND    := "131211"   ; fond des fenêtres
C_SURFACE := "1F1D1B"   ; touches, badge, bouton secondaire
C_SURVOL  := "2C2926"   ; bouton secondaire sous la souris
C_LIGNE   := "2B2926"   ; traits de séparation, bordure, fond de la jauge
C_TEXTE   := "EEE9E2"   ; texte principal (ivoire), bouton principal
C_BLANC   := "FFFFFF"   ; bouton principal sous la souris
C_DOUX    := "A39D94"   ; texte secondaire
C_SOMBRE  := "6B665F"   ; texte discret
C_VERT    := "78BA8E"
C_AMBRE   := "CFA359"
C_ROUGE   := "D16C61"

; Polices de Windows 11 si elles sont là, sinon celles de Windows 10.
; (Windows raccourcit certains noms de police à 31 lettres : « …Display Semib » est normal.)
W11          := FileExist(A_WinDir "\Fonts\SegUIVar.ttf") != ""
POLICE       := W11 ? "Segoe UI Variable Text" : "Segoe UI"
POLICE_SB    := W11 ? "Segoe UI Variable Text Semibold" : "Segoe UI Semibold"
POLICE_TITRE := W11 ? "Segoe UI Variable Display Semib" : "Segoe UI Semibold"
POLICE_GRAND := W11 ? "Segoe UI Variable Display" : "Segoe UI"
ICONES       := FileExist(A_WinDir "\Fonts\SegoeIcons.ttf") ? "Segoe Fluent Icons" : "Segoe MDL2 Assets"

I_MANETTE  := Chr(0xE7FC)
I_PLAY     := Chr(0xE768)
I_PAUSE    := Chr(0xE769)
I_STOP     := Chr(0xE71A)
I_CHRONO   := Chr(0xE916)
I_SON      := Chr(0xE767)
I_MUET     := Chr(0xE74F)
I_ORIGINE  := Chr(0xE72C)
I_ECRAN    := Chr(0xE7F4)
I_MENU     := Chr(0xE700)
I_AIDE     := Chr(0xE897)
I_FERMER   := Chr(0xE711)
I_VALIDE   := Chr(0xEC61)   ; rond plein avec une coche
I_INVALIDE := Chr(0xEB90)   ; rond plein avec une croix
I_ENCOURS  := Chr(0xEA3B)   ; rond plein

LARGEUR  := 284   ; largeur du contenu du panneau
L_ASSIST := 400   ; largeur du contenu de l'assistant

; ─────────────────────────────── ÉTAT ───────────────────────────────
actif          := false
nbAppuis       := 0
debut          := 0
cumul          := 0
visible        := true
nomChiaki      := ""
dernierEtat    := ""
dernierChiaki  := -1
dernierPS5     := -1
cause          := ""      ; pourquoi Turbo X est en pause
conseil        := ""      ; ce qu'il faut faire pour qu'il reprenne
derniereCause  := ""
ecranPan       := 0       ; écran où se trouve le panneau
rangJeu        := 0       ; écran du jeu retenu (1 = le plus à gauche)
silence        := 0       ; pas de notification de pause / reprise avant ce moment (menu ouvert)
asstVisible    := false   ; l'assistant de démarrage est-il affiché ?
asstEcran      := 0       ; écran au milieu duquel il a été placé
asstDeplace    := false   ; l'a-t-on déplacé à la main ? (il ne suit alors plus l'écran du jeu)
asstFini       := 0       ; depuis quand tout est coché
actions        := []      ; ce que font les boutons de l'assistant
lancement      := ""      ; ouverture de chiaki-ng au lancement : "attente", "connexion" puis "fait"
lancementDebut := 0
chiakiLance    := 0       ; quand Turbo X a ouvert chiaki-ng
streamLance    := 0       ; quand Turbo X a demandé à chiaki-ng de se connecter tout seul
ps5            := {socket: -1, etat: "", nom: "", ip: "", vue: 0, envoi: 0, debut: 0}   ; ce que la PS5 répond sur le réseau

; ─────────────────────────────── MÉMOIRE ───────────────────────────────
; La cadence, le coin, l'écran et les sons sont retenus d'une fois sur l'autre.
; Si tu modifies un de ces réglages en haut du fichier, c'est ta modification qui gagne.
MEMOIRE := A_AppData "\Turbo X\memoire.ini"
ReprendreAncienneMemoire()
ORIGINE    := Map("cadence", CADENCE_MS, "coin", COIN, "ecran", ECRAN, "sons", SONS)
CADENCE_MS := Souvenir("cadence", CADENCE_MIN, CADENCE_MAX)
COIN       := Souvenir("coin", 1, 4)
ECRAN      := Souvenir("ecran", 0, 9)
SONS       := Souvenir("sons", 0, 1)
try ps5.ip := IniRead(MEMOIRE, "memoire", "ip_ps5")                     ; dernière adresse connue de la PS5
try rangJeu := Integer(IniRead(MEMOIRE, "memoire", "ecran_jeu"))         ; écran où était chiaki-ng la dernière fois

; Ferme toute autre copie de Turbo X (ou de Spam X, son ancien nom ; version .ahk ou .exe)
; pour ne jamais avoir deux copies qui appuient en même temps
for fenetre in WinGetList("ahk_class AutoHotkey") {
    if (fenetre = A_ScriptHwnd)
        continue
    try {
        if RegExMatch(WinGetTitle(fenetre), "i)\\(spam|turbo)[ -]?x[^\\]*\.(ahk|exe)\b")
            WinClose(fenetre)
    }
}

; ─────────────────────────────── PANNEAU ───────────────────────────────
pan := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "Turbo X")
pan.BackColor := C_FOND
pan.MarginX := 24
pan.MarginY := 20

; Liseré de couleur à gauche (vert / ambre / rouge selon l'état)
barre := pan.AddText("x0 y0 w3 h1 Background" C_ROUGE)

; En-tête : nom, version, voyant qui clignote à chaque appui et bouton menu
pan.SetFont("s11 c" C_TEXTE, POLICE_TITRE)
pan.AddText("xm ym h22 +0x200", "TURBO X")
pan.SetFont("s7 c" C_DOUX, POLICE_SB)
pan.AddText("x+10 yp+4 h14 +0x200 Center Background" C_SURFACE, "  v" VERSION "  ")
pan.SetFont("s9 c" C_SOMBRE, POLICE)
voyant := pan.AddText("x" (pan.MarginX + LARGEUR - 46) " ym w16 h22 +0x200 Right", "●")
pan.SetFont("s11 c" C_DOUX, ICONES)
btMenu := pan.AddText("x" (pan.MarginX + LARGEUR - 22) " ym w22 h22 +0x200 Center", I_MENU)
btMenu.OnEvent("Click", OuvrirMenu)
pan.OnEvent("ContextMenu", OuvrirMenu)   ; clic droit n'importe où sur le panneau

; Grand état : ACTIF / EN PAUSE / ARRÊTÉ
pan.SetFont("s20 c" C_ROUGE, ICONES)
icEtat := pan.AddText("xm y+18 w32 h46 +0x200", I_STOP)
pan.SetFont("s22 w700 c" C_ROUGE, POLICE_GRAND)
txEtat := pan.AddText("x+10 yp w" (LARGEUR - 42) " h46 +0x200", "ARRÊTÉ")
pan.SetFont("norm s9 c" C_DOUX, POLICE)   ; « norm » : la suite n'est plus en gras
txAide := pan.AddText("xm y+0 w" LARGEUR, "Appuie sur F8 pour démarrer")

; Statistiques
Separateur()
txAppuis  := Ligne("Appuis")
txTemps   := Ligne("Temps actif")
txCadence := Ligne("Cadence")
txChiaki  := Ligne("chiaki-ng")
txPS5     := Ligne("PS5")
Separateur()

; Raccourcis
col2 := "x" (pan.MarginX + 146) " yp"
AjouterTouche("F8", "marche / arrêt", "xm y+14")
AjouterTouche("F7", "masquer", col2)
AjouterTouche("F9 · F10", "cadence", "xm y+6")
AjouterTouche("F6", "coin", col2)
AjouterTouche("Ctrl + F8", "quitter", "xm y+6")
AjouterTouche("F5", "écran", col2)
AjouterTouche("F1", "assistant de démarrage", "xm y+6")

pan.Show("Hide AutoSize")
WinGetPos(,,, &panH, pan)
barre.Move(0, 0, 3, panH)
DwmArrondi(pan)
PlacerPanneau()
pan.Show("NoActivate")

; ─────────────────────────────── NOTIFICATION ───────────────────────────────
notif := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "Turbo X · notification")
notif.BackColor := C_FOND
notif.MarginX := 22
notif.MarginY := 16
notif.SetFont("s20 c" C_VERT, ICONES)
nIcone := notif.AddText("xm ym w36 h56 +0x200 Center", I_PLAY)
notif.SetFont("s14 c" C_VERT, POLICE_TITRE)
nTitre := notif.AddText("x+14 ym+2 w330 h30 +0x200", "")
notif.SetFont("s9 c" C_DOUX, POLICE)
nSous := notif.AddText("xp y+0 w330 h22 +0x200", "")
notif.Show("Hide AutoSize")
DwmArrondi(notif)

; ─────────────────────────────── ASSISTANT DE DÉMARRAGE ───────────────────────────────
; Une liste qui se coche toute seule. Comme le panneau, elle ne prend jamais le clavier
; à chiaki-ng, même quand on clique sur ses boutons. On la déplace en la tenant par le fond.
asst := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "Turbo X · assistant")
asst.BackColor := C_FOND
asst.MarginX := 28
asst.MarginY := 24

asst.SetFont("s13 c" C_TEXTE, POLICE_TITRE)
asst.AddText("xm ym w" (L_ASSIST - 30) " h30 +0x200", "Assistant de démarrage")
asst.SetFont("s10 c" C_SOMBRE, ICONES)
aFermer := asst.AddText("x" (asst.MarginX + L_ASSIST - 24) " ym w24 h30 +0x200 Center", I_FERMER)
aFermer.OnEvent("Click", (*) => AssistantMasquer(true))
asst.AddText("xm y+16 w" L_ASSIST " h1 Background" C_LIGNE)

; Les 7 étapes : un rond (vert = validée, ambre = en cours, rouge = pas encore), le titre, et où on en est
ETAPES := ["chiaki-ng est installé", "Ta PS5 est jumelée avec chiaki-ng", "Ta PS5 est allumée"
         , "chiaki-ng est ouvert", "chiaki-ng est connecté à ta PS5"
         , "La fenêtre chiaki-ng est au premier plan", "Turbo X est démarré (F8)"]
aLignes := []
for nomEtape in ETAPES {
    asst.SetFont("s12 c" C_ROUGE, ICONES)
    aIcone := asst.AddText("xm y+" (A_Index = 1 ? 12 : 2) " w24 h34 +0x200 Center", I_INVALIDE)
    asst.SetFont("s10 c" C_DOUX, POLICE)
    aTitre := asst.AddText("x+12 yp w254 h34 +0x200", nomEtape)
    asst.SetFont("s9 c" C_ROUGE, POLICE)
    aStatut := asst.AddText("x+0 yp w" (L_ASSIST - 290) " h34 +0x200 Right", "")
    aLignes.Push({icone: aIcone, titre: aTitre, statut: aStatut})
}

; En bas : ce qu'il faut faire maintenant, avec un ou deux boutons
asst.AddText("xm y+14 w" L_ASSIST " h1 Background" C_LIGNE)
asst.SetFont("s8 c" C_DOUX, POLICE_SB)
aEtiquette := asst.AddText("xm y+16 w" L_ASSIST, "À FAIRE MAINTENANT")
asst.SetFont("s10 c" C_TEXTE, POLICE)
aConseil := asst.AddText("xm y+8 w" L_ASSIST " h64", "")
asst.SetFont("s9 c" C_FOND, POLICE_SB)
aBouton1 := asst.AddText("xm y+8 w196 h36 +0x200 Center Background" C_TEXTE, "")
asst.SetFont("s9 c" C_TEXTE, POLICE_SB)
aBouton2 := asst.AddText("x+8 yp w196 h36 +0x200 Center Background" C_SURFACE, "")
aBouton1.OnEvent("Click", (*) => AssistantAction(1))
aBouton2.OnEvent("Click", (*) => AssistantAction(2))

; Avancement
aJauge := asst.AddText("xm y+20 w0 h3 Background" C_VERT)
aPiste := asst.AddText("x+0 yp w" L_ASSIST " h3 Background" C_LIGNE)
asst.SetFont("s8 c" C_DOUX, POLICE)
aCompte := asst.AddText("xm y+10 w180", "")
asst.SetFont("s8 c" C_SOMBRE, POLICE)
asst.AddText("x+0 yp w" (L_ASSIST - 180) " Right", "F1 : afficher / masquer cette liste")

; Petit trait devant l'étape en cours. Créé en dernier : placé en haut (y0),
; il décalerait sinon tous les éléments ajoutés après lui.
aRepere := asst.AddText("x14 y0 w3 h34 Background" C_TEXTE)

asst.Show("Hide AutoSize")
DwmArrondi(asst)
DwmBordure(asst, C_LIGNE)
aPiste.GetPos(&jaugeX,, &jaugeL)

; ─────────────────────────────── ICÔNE PRÈS DE L'HORLOGE ───────────────────────────────
A_TrayMenu.Delete()
A_TrayMenu.Add("Démarrer / arrêter`tF8", Basculer)
A_TrayMenu.Add("Assistant de démarrage`tF1", BasculerAssistant)
A_TrayMenu.Add("Afficher / masquer le panneau`tF7", BasculerPanneau)
A_TrayMenu.Add("Changer de coin`tF6", ChangerCoin)
A_TrayMenu.Add("Changer d'écran`tF5", ChangerEcran)
A_TrayMenu.Add()
A_TrayMenu.Add("Sons", BasculerSons)
A_TrayMenu.Add("Remettre les réglages d'origine", RemettreOrigine)
A_TrayMenu.Add()
A_TrayMenu.Add("Quitter`tCtrl+F8", Quitter)
A_TrayMenu.Default := "Démarrer / arrêter`tF8"
A_IconTip := "Turbo X"
CocherSons()

OnExit(Fermeture)
OnMessage(0x201, Glisser)   ; clic gauche : permet de déplacer l'assistant
lancement      := OUVRIR_CHIAKI ? "attente" : "fait"
lancementDebut := A_TickCount
SetTimer(Rafraichir, 250)
AssistantAfficher()
Notifier(I_MANETTE, C_TEXTE, "TURBO X EST PRÊT", "Suis l'assistant : il te guide pas à pas")

; ─────────────────────────────── RACCOURCIS ───────────────────────────────
F1::BasculerAssistant()
F8::Basculer()
F9::ChangerCadence(PAS_MS)
F10::ChangerCadence(-PAS_MS)
F7::BasculerPanneau()
F6::ChangerCoin()
F5::ChangerEcran()
^F8::Quitter()

; ─────────────────────────────── ACTIONS ───────────────────────────────
Basculer(*) {
    global actif, debut, cumul
    actif := !actif
    if actif {
        debut := A_TickCount
        SetTimer(Appuyer, CADENCE_MS)
    } else {
        SetTimer(Appuyer, 0)
        cumul += A_TickCount - debut
        AllumerVoyant(false)
    }
    Rafraichir()
    if !actif {
        Notifier(I_STOP, C_ROUGE, "TURBO ARRÊTÉ", "Appuie sur F8 pour relancer")
        Bips(990, 550)
        return
    }
    if (dernierEtat = "actif")
        Notifier(I_PLAY, C_VERT, "TURBO ACTIVÉ", "X toutes les " Secondes(CADENCE_MS) "  ·  F8 pour arrêter")
    else
        Notifier(I_PAUSE, C_AMBRE, "ACTIVÉ, MAIS EN PAUSE", conseil)
    Bips(660, 990)
}

Appuyer() {
    global nbAppuis
    if !PeutAppuyer()
        return
    AllumerVoyant(true)
    Send("{" TOUCHE " down}")
    Sleep(APPUI_MS)
    Send("{" TOUCHE " up}")
    AllumerVoyant(false)
    nbAppuis += 1
}

ChangerCadence(delta) {
    global CADENCE_MS
    CADENCE_MS := Max(CADENCE_MIN, Min(CADENCE_MAX, CADENCE_MS + delta))
    if actif
        SetTimer(Appuyer, CADENCE_MS)
    Retenir()
    limite := ""
    if (CADENCE_MS = CADENCE_MIN)
        limite := "  ·  vitesse maximale"
    else if (CADENCE_MS = CADENCE_MAX)
        limite := "  ·  vitesse minimale"
    Rafraichir()
    Notifier(I_CHRONO, C_TEXTE, "CADENCE : " ParSeconde(CADENCE_MS) " PAR SECONDE", "Un appui toutes les " Secondes(CADENCE_MS) limite)
}

BasculerPanneau(*) {
    global visible
    visible := !visible
    if visible
        pan.Show("NoActivate")
    else
        pan.Hide()
}

ChangerCoin(*) {
    global COIN
    COIN := Mod(COIN, 4) + 1
    PlacerPanneau()
    Retenir()
}

ChangerEcran(*) {
    ; écran du jeu (automatique) → écran de gauche → écran de droite → écran du jeu…
    global ECRAN
    nb := MonitorGetCount()
    if (nb < 2) {
        Notifier(I_ECRAN, C_TEXTE, "UN SEUL ÉCRAN", "F5 sert quand un deuxième écran est branché")
        return
    }
    ECRAN := ECRAN >= nb ? 0 : ECRAN + 1
    PlacerPanneau()
    Retenir()
    if (ECRAN = 0)
        Notifier(I_ECRAN, C_TEXTE, "PANNEAU : ÉCRAN DU JEU", "Il suit la fenêtre chiaki-ng  ·  F5 pour changer")
    else
        Notifier(I_ECRAN, C_TEXTE, "PANNEAU : " StrUpper(NomEcran(ECRAN)), "Il reste sur cet écran  ·  F5 pour changer")
}

BasculerSons(*) {
    global SONS
    SONS := !SONS
    CocherSons()
    Retenir()
    if SONS
        Notifier(I_SON, C_TEXTE, "SONS ACTIVÉS", "Petits bips au démarrage et à l'arrêt")
    else
        Notifier(I_MUET, C_TEXTE, "SONS COUPÉS", "Plus aucun bip")
    Bips(660, 990)
}

RemettreOrigine(*) {
    global CADENCE_MS, COIN, ECRAN, SONS
    CADENCE_MS := ORIGINE["cadence"]
    COIN       := ORIGINE["coin"]
    ECRAN      := ORIGINE["ecran"]
    SONS       := ORIGINE["sons"]
    if actif
        SetTimer(Appuyer, CADENCE_MS)
    CocherSons()
    PlacerPanneau()
    Retenir()
    Rafraichir()
    Notifier(I_ORIGINE, C_TEXTE, "RÉGLAGES D'ORIGINE", "Cadence, coin, écran et sons remis comme au départ")
}

OuvrirMenu(*) {
    ; même menu que l'icône près de l'horloge, puis la main revient à la fenêtre d'avant (chiaki-ng)
    global silence
    avant := WinExist("A")
    silence := A_TickCount + 60000   ; pas de notification « en pause » pendant que le menu est ouvert…
    A_TrayMenu.Show()
    silence := A_TickCount + 1000    ; …ni le temps que chiaki-ng reprenne la main
    SetTimer(() => RendreLaMain(avant), -150)
}

RendreLaMain(avant) {
    ; seulement si personne n'a cliqué ailleurs entre-temps
    if (avant && avant != A_ScriptHwnd && WinExist("A") = A_ScriptHwnd)
        try WinActivate(avant)
}

Quitter(*) {
    ExitApp()
}

Fermeture(*) {
    try Send("{" TOUCHE " up}")   ; ne jamais laisser la touche enfoncée
}

; ─────────────────────────────── AFFICHAGE ───────────────────────────────
Rafraichir(*) {
    global dernierEtat, dernierChiaki, dernierPS5, derniereCause, cause, conseil
    devant   := ChiakiDevant()
    ouvert   := devant || ChiakiPid()
    connecte := ouvert && ChiakiConnecte()
    pret     := devant && (connecte || !VERIF_PS5)
    etat     := !actif ? "arret" : (pret ? "actif" : "pause")

    ; pourquoi Turbo X est en pause, et ce qu'il faut faire pour qu'il reprenne
    cause := conseil := ""
    if (etat = "pause") {
        if !ouvert
            cause := "chiaki-ng est fermé", conseil := "Ouvre chiaki-ng pour continuer"
        else if (VERIF_PS5 && !connecte)
            cause := "chiaki-ng n'est pas connecté à la PS5", conseil := "Connecte chiaki-ng à ta PS5"
        else
            cause := "chiaki-ng n'est plus au premier plan", conseil := "Clique dans la fenêtre chiaki-ng"
    }

    ; prévient quand Turbo X se met en pause ou reprend tout seul (sauf autour du menu)
    if (A_TickCount > silence && (dernierEtat = "actif" || dernierEtat = "pause") && (etat != dernierEtat || cause != derniereCause)) {
        if (etat = "pause")
            Notifier(I_PAUSE, C_AMBRE, "EN PAUSE", cause)
        else if (etat = "actif")
            Notifier(I_PLAY, C_VERT, "ÇA REPREND", "X toutes les " Secondes(CADENCE_MS) "  ·  F8 pour arrêter")
    }
    derniereCause := cause

    if (etat != dernierEtat) {
        dernierEtat := etat
        switch etat {
            case "actif": AfficherEtat(C_VERT, I_PLAY, "ACTIF")
            case "pause": AfficherEtat(C_AMBRE, I_PAUSE, "EN PAUSE")
            default:      AfficherEtat(C_ROUGE, I_STOP, "ARRÊTÉ")
        }
    }

    if (etat = "actif")
        aide := "X est appuyé toutes les " Secondes(CADENCE_MS)
    else if (etat = "pause")
        aide := conseil
    else
        aide := "Appuie sur F8 pour démarrer"
    Maj(txAide, aide)

    chiaki := devant ? 2 : (ouvert ? 1 : 0)
    if (chiaki != dernierChiaki) {
        dernierChiaki := chiaki
        txChiaki.SetFont("c" . (chiaki = 2 ? C_VERT : chiaki = 1 ? C_AMBRE : C_ROUGE))
        txChiaki.Value := chiaki = 2 ? "au premier plan" : chiaki = 1 ? "en arrière-plan" : "fermé"
    }

    codePs5 := connecte ? 2 : !VERIF_PS5 ? 3 : ouvert ? 1 : 0
    if (codePs5 != dernierPS5) {
        dernierPS5 := codePs5
        txPS5.SetFont("c" . (codePs5 = 2 ? C_VERT : codePs5 = 3 ? C_DOUX : codePs5 = 1 ? C_AMBRE : C_ROUGE))
        txPS5.Value := codePs5 = 2 ? "connectée" : codePs5 = 3 ? "non vérifiée" : "pas connectée"
    }

    Maj(txAppuis, Milliers(nbAppuis))
    Maj(txTemps, Chrono(TempsActif()))
    Maj(txCadence, ParSeconde(CADENCE_MS) " par seconde  ·  " Secondes(CADENCE_MS))

    ; ouverture automatique de chiaki-ng au lancement
    LancementAuto(connecte)

    ; le panneau va sur l'écran choisi avec F5, sinon sur l'écran du jeu ; l'assistant suit l'écran du jeu
    jeu := EcranJeu()
    ecran := EcranPanneau(jeu)
    if (ecran != ecranPan)
        PlacerPanneau(ecran)
    if (asstVisible && !asstDeplace && jeu != asstEcran)
        CentrerAssistant(jeu)

    ; le bouton menu s'éclaire quand la souris passe dessus, puis l'assistant se met à jour
    MouseGetPos(,,, &sous, 2)
    Peindre(btMenu, sous = btMenu.Hwnd ? C_TEXTE : C_DOUX)
    if asstVisible
        AssistantMaj(devant, ouvert, connecte, etat, sous)

    ; garde le panneau et l'assistant au-dessus de tout, sans voler le clavier à chiaki-ng
    if visible
        AuDessus(pan)
    if asstVisible
        AuDessus(asst)
}

AfficherEtat(couleur, icone, titre) {
    icEtat.SetFont("c" couleur)
    icEtat.Value := icone
    txEtat.SetFont("c" couleur)
    txEtat.Value := titre
    barre.Opt("Background" couleur)
    barre.Redraw()
    DwmBordure(pan, couleur)
    A_IconTip := "Turbo X  ·  " titre
}

AllumerVoyant(allume) {
    voyant.SetFont("c" . (allume ? C_VERT : C_SOMBRE))
}

Notifier(icone, couleur, titre, sousTitre) {
    nIcone.SetFont("c" couleur)
    nIcone.Value := icone
    nTitre.SetFont("c" couleur)
    nTitre.Value := titre
    nSous.Value := sousTitre
    DwmBordure(notif, couleur)
    ZoneEcran(&zG, &zH, &zD, &zB)   ; sur le même écran que le panneau
    WinGetPos(,, &nL,, notif)
    WinMove(zG + (zD - zG - nL) // 2, zH + 36,,, notif)
    notif.Show("NoActivate")
    SetTimer(CacherNotif, -1800)
}

CacherNotif() {
    notif.Hide()
}

PlacerPanneau(ecran := 0) {
    global ecranPan
    ecranPan := ecran ? ecran : EcranPanneau(EcranJeu())
    ZoneEcran(&zG, &zH, &zD, &zB)
    WinGetPos(,, &pL, &pH, pan)
    x := (COIN = 2 || COIN = 3) ? zD - pL - 18 : zG + 18
    y := (COIN >= 3) ? zB - pH - 18 : zH + 18
    WinMove(x, y,,, pan)
}

AuDessus(fenetre) {
    ; remet la fenêtre au-dessus de tout, sans l'activer
    DllCall("SetWindowPos", "Ptr", fenetre.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)
}

CocherSons() {
    if SONS
        A_TrayMenu.Check("Sons")
    else
        A_TrayMenu.Uncheck("Sons")
}

Ligne(nom) {
    pan.SetFont("norm s9 c" C_DOUX, POLICE)
    pan.AddText("xm y+6 w104 h22 +0x200", nom)
    pan.SetFont("norm s10 c" C_TEXTE, POLICE_SB)
    return pan.AddText("x+0 yp w" (LARGEUR - 104) " h22 +0x200", "")
}

Separateur() {
    pan.AddText("xm y+14 w" LARGEUR " h1 Background" C_LIGNE)
}

AjouterTouche(cle, texte, position) {
    pan.SetFont("norm s8 c" C_TEXTE, POLICE_SB)
    pan.AddText(position " h20 +0x200 Center Background" C_SURFACE, "  " cle "  ")
    pan.SetFont("norm s8 c" C_DOUX, POLICE)
    pan.AddText("x+8 yp h20 +0x200", texte)
}

Maj(ctrl, texte) {
    if (ctrl.Value != texte)
        ctrl.Value := texte
}

Peindre(ctrl, couleur) {
    ; change la couleur d'un texte, seulement si elle a changé (évite le clignotement)
    static couleurs := Map()
    if (couleurs.Get(ctrl.Hwnd, "") != couleur) {
        couleurs[ctrl.Hwnd] := couleur
        ctrl.SetFont("c" couleur)
    }
}

Fond(ctrl, couleur) {
    ; change la couleur de fond d'un texte ou d'un bouton, seulement si elle a changé
    static fonds := Map()
    if (fonds.Get(ctrl.Hwnd, "") != couleur) {
        fonds[ctrl.Hwnd] := couleur
        ctrl.Opt("Background" couleur)
        ctrl.Redraw()
    }
}

Montrer(ctrl, oui) {
    if (ctrl.Visible != !!oui)
        ctrl.Visible := !!oui
}

; ─────────────────────────────── ASSISTANT ───────────────────────────────
BasculerAssistant(*) {
    if asstVisible
        AssistantMasquer(true)
    else
        AssistantAfficher()
}

AssistantAfficher() {
    global asstVisible, asstFini
    asstVisible := true
    asstFini := 0
    if !asstDeplace
        CentrerAssistant(EcranJeu())   ; sur l'écran du jeu, sauf si on l'a déplacé à la main
    Rafraichir()
    asst.Show("NoActivate")
}

CentrerAssistant(ecran) {
    ; place l'assistant au milieu d'un écran
    global asstEcran
    asstEcran := ecran
    try
        MonitorGetWorkArea(ecran, &zG, &zH, &zD, &zB)
    catch
        MonitorGetWorkArea(, &zG, &zH, &zD, &zB)
    WinGetPos(,, &aL, &aH, asst)
    WinMove(zG + (zD - zG - aL) // 2, zH + Max(0, (zB - zH - aH) // 2),,, asst)
}

AssistantMasquer(parLUtilisateur := false) {
    global asstVisible
    asstVisible := false
    asst.Hide()
    if parLUtilisateur
        Notifier(I_AIDE, C_TEXTE, "ASSISTANT MASQUÉ", "Appuie sur F1 pour le rouvrir")
}

AssistantAction(n) {
    ; un bouton de l'assistant a été cliqué
    if (n <= actions.Length)
        actions[n]()
}

AssistantMaj(devant, ouvert, connecte, etat, sous) {
    ; chaque ligne se coche toute seule ; en bas, ce qu'il faut faire maintenant
    global actions, asstFini
    static derniereCourante := -1, dernierPlein := -1
    if !connecte
        Ps5Suivre()
    noms      := Ps5Jumelees()
    nom       := ps5.nom != "" ? ps5.nom : noms.Length ? noms[1] : ""
    taPs5     := nom != "" ? "ta PS5 « " nom " »" : "ta PS5"
    installe  := ouvert || CheminChiaki() != ""
    jumelee   := noms.Length > 0 || connecte
    allumee   := connecte || ps5.etat != ""
    cherche   := !allumee && ps5.debut && A_TickCount - ps5.debut < 3500
    ouverture := !ouvert && (lancement = "attente" || A_TickCount - chiakiLance < 15000)
    connexion := !connecte && A_TickCount - streamLance < 25000
    relie     := connecte || (!VERIF_PS5 && ouvert)   ; sans vérification (jeu par Internet), on fait confiance
    demarre   := etat = "actif"
    btChiaki  := ouvert ? ["Mettre chiaki-ng devant", MettreChiakiDevant] : ["Ouvrir chiaki-ng", OuvrirChiaki]

    etapes := []
    etapes.Push(Etape(installe, false, installe ? "installé" : "introuvable"
        , "chiaki-ng est le logiciel gratuit qui affiche ta PS5 sur ce PC. Installe-le, puis reviens ici : la suite se cochera toute seule."
        , [["Télécharger chiaki-ng", TelechargerChiaki], ["Il est déjà installé…", ChoisirChiaki]]))
    etapes.Push(Etape(jumelee, false, jumelee ? (nom != "" ? nom : "oui") : "pas encore"
        , "À faire une seule fois. Sur ta PS5 : Paramètres › Système › Lecture à distance › Associer un appareil. Dans chiaki-ng, clique sur ta PS5 et tape le code affiché."
        , [btChiaki]))
    etapes.Push(Etape(allumee, cherche
        , (connecte || ps5.etat = "allumee") ? "allumée" : ps5.etat = "repos" ? "en mode repos" : cherche ? "recherche…" : "introuvable"
        , cherche ? "Turbo X cherche ta PS5 sur ton réseau…" : "Allume ta PS5, ou mets-la en mode repos. Elle doit être reliée à la même box Internet que ce PC (en Wi-Fi ou par câble)."
        , cherche ? [] : [["Chercher encore", Ps5Relancer]]))
    etapes.Push(Etape(ouvert, ouverture, ouvert ? "ouvert" : ouverture ? "ouverture…" : "fermé"
        , ouverture ? "Turbo X ouvre chiaki-ng pour toi, patiente quelques secondes…" : "Ouvre chiaki-ng avec le bouton ci-dessous."
        , ouverture ? [] : [["Ouvrir chiaki-ng", OuvrirChiaki]]))
    etapes.Push(Etape(relie, connexion, connecte ? "connecté" : relie ? "non vérifié" : connexion ? "connexion…" : "pas connecté"
        , connexion ? "chiaki-ng se connecte tout seul à " taPs5 ", patiente quelques secondes…"
            : ps5.etat = "repos" ? "Dans chiaki-ng, clique sur " taPs5 " : chiaki-ng va la réveiller. Patiente quelques secondes."
            : "Dans chiaki-ng, clique sur " taPs5 ". L'écran de ta PS5 va s'afficher dans la fenêtre."
        , (ouvert && !devant) ? [["Mettre chiaki-ng devant", MettreChiakiDevant]] : []))
    etapes.Push(Etape(devant, false, devant ? "oui" : "non"
        , "Clique une fois au milieu de la fenêtre chiaki-ng, sur l'image de ta PS5."
        , [["Mettre chiaki-ng devant", MettreChiakiDevant]]))
    etapes.Push(Etape(demarre, false, demarre ? "actif" : actif ? "en pause" : "pas encore"
        , "Dans le jeu, place-toi là où il faut appuyer sur X, puis appuie sur F8 (ou sur le bouton)."
        , [["Démarrer (F8)", Basculer]]))

    ; si Turbo X appuie déjà, c'est que tout marche
    courante := 0, faites := 0
    for i, e in etapes {
        if demarre
            e.fait := true
        if e.fait
            faites += 1
        else if !courante
            courante := i
    }

    ; vert = validée, ambre = en cours, rouge = pas encore validée ; l'étape en cours est en clair
    for i, e in etapes {
        titre := (i = courante) ? C_TEXTE : C_DOUX
        if e.fait
            MajLigne(aLignes[i], I_VALIDE, C_VERT, C_DOUX, e.statut, C_VERT)
        else if e.attente
            MajLigne(aLignes[i], I_ENCOURS, C_AMBRE, titre, e.statut, C_AMBRE)
        else
            MajLigne(aLignes[i], I_INVALIDE, C_ROUGE, titre, e.statut, C_ROUGE)
    }

    ; en bas : l'étape en cours, expliquée simplement, avec ses boutons
    actions := []
    if courante {
        e := etapes[courante]
        Maj(aEtiquette, "ÉTAPE " courante " SUR " etapes.Length "  ·  À FAIRE MAINTENANT")
        Peindre(aEtiquette, C_DOUX)
        Maj(aConseil, e.conseil)
        for j, bouton in [aBouton1, aBouton2] {
            Montrer(bouton, j <= e.boutons.Length)
            if (j <= e.boutons.Length) {
                Maj(bouton, e.boutons[j][1])
                actions.Push(e.boutons[j][2])
            }
        }
        if (courante != derniereCourante) {
            aLignes[courante].icone.GetPos(, &y,, &h)
            aRepere.Move(, y,, h)
        }
        Montrer(aRepere, true)
        asstFini := 0
    } else {
        Maj(aEtiquette, "C'EST PARTI !")
        Peindre(aEtiquette, C_VERT)
        Maj(aConseil, "Tout est prêt : Turbo X appuie sur X pour toi. F8 pour arrêter, F1 pour revoir cette liste.")
        Montrer(aBouton1, false), Montrer(aBouton2, false), Montrer(aRepere, false)
        if !asstFini
            asstFini := A_TickCount
    }
    derniereCourante := courante

    plein := Round(jaugeL * faites / etapes.Length)
    if (plein != dernierPlein) {
        dernierPlein := plein
        aJauge.Move(jaugeX,, plein)
        aPiste.Move(jaugeX + plein,, jaugeL - plein)
    }
    Maj(aCompte, faites " étape" (faites > 1 ? "s" : "") " sur " etapes.Length)

    ; les boutons s'éclairent quand la souris passe dessus
    Fond(aBouton1, sous = aBouton1.Hwnd ? C_BLANC : C_TEXTE)
    Fond(aBouton2, sous = aBouton2.Hwnd ? C_SURVOL : C_SURFACE)
    Peindre(aFermer, sous = aFermer.Hwnd ? C_TEXTE : C_SOMBRE)

    ; tout est coché depuis 4 secondes : l'assistant se range tout seul
    if (asstFini && A_TickCount - asstFini > 4000)
        AssistantMasquer()
}

Etape(fait, attente, statut, conseil, boutons) {
    return {fait: fait, attente: attente, statut: statut, conseil: conseil, boutons: boutons}
}

MajLigne(ligne, icone, couleurIcone, couleurTitre, statut, couleurStatut) {
    Maj(ligne.icone, icone)
    Peindre(ligne.icone, couleurIcone)
    Peindre(ligne.titre, couleurTitre)
    Maj(ligne.statut, statut)
    Peindre(ligne.statut, couleurStatut)
}

Glisser(wParam, lParam, msg, hwnd) {
    ; l'assistant se déplace en le tenant par le fond ou par un texte (pas par un bouton)
    global asstDeplace
    if (hwnd = asst.Hwnd) {
        asstDeplace := true            ; il ne suivra plus l'écran du jeu tout seul
        PostMessage(0xA1, 2,,, asst)   ; comme si on tenait une barre de titre
    }
}

; ─────────────────────────────── CHIAKI-NG ───────────────────────────────
LancementAuto(connecte) {
    ; au lancement : ouvre chiaki-ng (connecté directement à la PS5 si elle est allumée),
    ; puis le met devant dès qu'il est connecté
    global lancement
    if (lancement = "attente") {
        if (ChiakiPid() || CheminChiaki() = "") {
            lancement := "fait"
            return
        }
        Ps5Suivre()
        if (ps5.etat = "" && A_TickCount - lancementDebut < 1500)   ; on laisse 1,5 s à la PS5 pour répondre
            return
        if (CONNEXION_AUTO && ps5.etat = "allumee" && Ps5EstJumelee(ps5.nom))
            OuvrirChiaki(ps5.nom, ps5.ip)
        else
            OuvrirChiaki()
        lancement := "connexion"
    } else if (lancement = "connexion") {
        if connecte {
            MettreChiakiDevant()
            lancement := "fait"
        } else if (A_TickCount - chiakiLance > 60000)
            lancement := "fait"
    }
}

OuvrirChiaki(nom := "", ip := "") {
    ; ouvre chiaki-ng ; avec le nom et l'adresse de la PS5, il s'y connecte directement
    global chiakiLance, streamLance
    if ChiakiPid()
        return MettreChiakiDevant()
    if (A_TickCount - chiakiLance < 10000)   ; il est déjà en train de s'ouvrir
        return
    chemin := CheminChiaki(true)
    if (chemin = "")
        return
    SplitPath(chemin,, &dossier)
    try {
        if (nom != "" && ip != "") {
            Run('"' chemin '" stream "' nom '" ' ip, dossier)
            streamLance := A_TickCount
        } else
            Run('"' chemin '"', dossier)
        chiakiLance := A_TickCount
    }
}

MettreChiakiDevant(*) {
    if (fenetre := FenetreChiaki())
        try WinActivate(fenetre)
}

TelechargerChiaki(*) {
    try Run("https://github.com/streetpea/chiaki-ng/releases/latest")
}

ChoisirChiaki(*) {
    ; chiaki-ng est installé dans un dossier inhabituel : on le montre une fois à Turbo X
    asst.Opt("+OwnDialogs")
    chemin := FileSelect(3, A_ProgramFiles, "Où est chiaki-ng ? Choisis le fichier chiaki.exe", "Programme (*.exe)")
    if (chemin = "")
        return
    Noter("chemin_chiaki", chemin)
    CheminChiaki(true)
}

CheminChiaki(force := false) {
    ; où est installé chiaki-ng (« » s'il est introuvable) ; cherche au plus toutes les 2 secondes
    static memo := "", essai := 0
    if (memo != "" && FileExist(memo))
        return memo
    if (!force && A_TickCount - essai < 2000)
        return ""
    essai := A_TickCount
    candidats := []
    if (pid := ChiakiPid())
        try candidats.Push(ProcessGetPath(pid))
    try candidats.Push(IniRead(MEMOIRE, "memoire", "chemin_chiaki"))
    candidats.Push(A_ProgramFiles "\chiaki-ng\chiaki.exe", EnvGet("LOCALAPPDATA") "\Programs\chiaki-ng\chiaki.exe")
    ; la liste des programmes installés de Windows
    for racine in ["HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
                 , "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                 , "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"] {
        loop reg racine, "K" {
            try {
                if InStr(RegRead(A_LoopRegKey "\" A_LoopRegName, "DisplayName"), "chiaki")
                    candidats.Push(RTrim(RegRead(A_LoopRegKey "\" A_LoopRegName, "InstallLocation"), "\") "\chiaki.exe")
            }
        }
    }
    for chemin in candidats
        if (chemin != "" && FileExist(chemin))
            return memo := chemin
    return ""
}

Ps5Jumelees() {
    ; noms des consoles jumelées : chiaki-ng les garde dans le registre de Windows
    static noms := [], essai := 0
    if (noms.Length || A_TickCount - essai < 2000)
        return noms
    essai := A_TickCount
    groupes := ["Chiaki"]
    try {
        profil := RegRead("HKCU\Software\Chiaki\Chiaki\settings", "current_profile")
        if (profil != "")
            groupes.InsertAt(1, "Chiaki-" profil)
    }
    for groupe in groupes {
        loop reg "HKCU\Software\Chiaki\" groupe "\registered_hosts", "K"
            try noms.Push(RegRead(A_LoopRegKey "\" A_LoopRegName, "server_nickname"))
    }
    return noms
}

Ps5EstJumelee(nom) {
    for n in Ps5Jumelees()
        if (n = nom)
            return true
    return false
}

; ─────────────────────────────── PS5 SUR LE RÉSEAU ───────────────────────────────
; Comme chiaki-ng, Turbo X demande « y a-t-il une PS5 ? » sur le réseau (port 9302).
; La PS5 répond « 200 Ok » si elle est allumée, « 620 Server Standby » en mode repos.
Ps5Suivre() {
    ; lit les réponses, redemande toutes les 2 secondes, oublie la PS5 si elle ne répond plus
    Ps5Ecouter()
    if (A_TickCount - ps5.envoi > 2000)
        Ps5Chercher()
    if (ps5.etat != "" && A_TickCount - ps5.vue > 6000)
        ps5.etat := ""
}

Ps5Relancer(*) {
    ; « Chercher encore » : la recherche recommence tout de suite
    ps5.debut := 0, ps5.envoi := 0
}

Ps5Chercher() {
    static message := "SRCH * HTTP/1.1`ndevice-discovery-protocol-version:00030010`n"
    ps5.envoi := A_TickCount
    if !ps5.debut
        ps5.debut := A_TickCount
    if !Ps5Prise()
        return
    paquet := Buffer(StrPut(message, "UTF-8"))
    longueur := StrPut(message, paquet, "UTF-8") - 1
    adresse := Buffer(16, 0)
    NumPut("UShort", 2, adresse, 0)                                              ; IPv4
    NumPut("UShort", DllCall("ws2_32\htons", "UShort", 9302, "UShort"), adresse, 2)
    for ip in Ps5Adresses() {
        NumPut("UInt", DllCall("ws2_32\inet_addr", "AStr", ip, "UInt"), adresse, 4)
        DllCall("ws2_32\sendto", "Ptr", ps5.socket, "Ptr", paquet, "Int", longueur, "Int", 0, "Ptr", adresse, "Int", 16)
    }
}

Ps5Ecouter() {
    ; lit les réponses arrivées, sans jamais attendre
    if (ps5.socket = -1)
        return
    recu := Buffer(2048), de := Buffer(16, 0)
    loop {
        tailleDe := 16
        n := DllCall("ws2_32\recvfrom", "Ptr", ps5.socket, "Ptr", recu, "Int", recu.Size, "Int", 0, "Ptr", de, "Int*", &tailleDe, "Int")
        if (n <= 0)
            break
        reponse := StrGet(recu, n, "UTF-8")
        if !RegExMatch(reponse, "^HTTP/1\.1 (\d+)", &code) || !InStr(reponse, "host-type:PS5")
            continue
        ps5.etat := code[1] = "200" ? "allumee" : "repos"
        if RegExMatch(reponse, "m)^host-name:(.+?)\r?$", &trouve)
            ps5.nom := trouve[1]
        ip := DllCall("ws2_32\inet_ntoa", "UInt", NumGet(de, 4, "UInt"), "AStr")
        if (ip != ps5.ip)
            Noter("ip_ps5", ip)
        ps5.ip := ip
        ps5.vue := A_TickCount
    }
}

Ps5Prise() {
    ; ouvre une seule fois la « prise » réseau qui sert à parler à la PS5
    if (ps5.socket != -1)
        return true
    DllCall("ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", Buffer(408, 0))
    prise := DllCall("ws2_32\socket", "Int", 2, "Int", 2, "Int", 17, "Ptr")   ; IPv4, UDP
    if (prise = -1)
        return false
    DllCall("ws2_32\setsockopt", "Ptr", prise, "Int", 0xFFFF, "Int", 0x20, "Int*", 1, "Int", 4)   ; envoi à tout le réseau permis
    DllCall("ws2_32\ioctlsocket", "Ptr", prise, "UInt", 0x8004667E, "UInt*", 1)                ; ne jamais attendre
    octets := 0                                                                                 ; ignorer les « adresse injoignable »
    DllCall("ws2_32\WSAIoctl", "Ptr", prise, "UInt", 0x9800000C, "UInt*", 0, "UInt", 4, "Ptr", 0, "UInt", 0, "UInt*", &octets, "Ptr", 0, "Ptr", 0)
    ps5.socket := prise
    return true
}

Ps5Adresses() {
    ; où envoyer la question : la dernière adresse connue de la PS5,
    ; puis « tout le réseau » de chaque connexion du PC (Wi-Fi, câble…)
    adresses := []
    if (ps5.ip != "")
        adresses.Push(ps5.ip)
    taille := 0
    DllCall("iphlpapi\GetIpAddrTable", "Ptr", 0, "UInt*", &taille, "Int", false)
    table := Buffer(taille + 256)
    taille := table.Size
    if !DllCall("iphlpapi\GetIpAddrTable", "Ptr", table, "UInt*", &taille, "Int", false) {
        loop NumGet(table, 0, "UInt") {
            base := 4 + (A_Index - 1) * 24
            ip := NumGet(table, base, "UInt"), masque := NumGet(table, base + 8, "UInt")
            if (masque = 0xFFFFFFFF || (ip & 0xFF) = 127)   ; ni les liaisons à une seule adresse, ni le PC lui-même
                continue
            adresses.Push(DllCall("ws2_32\inet_ntoa", "UInt", (ip & masque) | (~masque & 0xFFFFFFFF), "AStr"))
        }
    }
    adresses.Push("255.255.255.255")
    return adresses
}

; ─────────────────────────────── ÉCRANS ───────────────────────────────
EcranPanneau(jeu) {
    ; l'écran choisi avec F5, sinon l'écran du jeu
    if (ECRAN >= 1) {
        ecrans := EcransTries()
        if (ECRAN <= ecrans.Length)
            return ecrans[ECRAN]
    }
    return jeu
}

EcranJeu() {
    ; l'écran de chiaki-ng ; s'il n'est pas visible, celui où il était la dernière fois (retenu)
    global rangJeu
    ecrans := EcransTries()
    if (n := EcranDeChiaki()) {
        for rang, num in ecrans {
            if (num = n && rang != rangJeu) {
                rangJeu := rang
                Noter("ecran_jeu", rang)
            }
        }
        return n
    }
    if (rangJeu >= 1 && rangJeu <= ecrans.Length)
        return ecrans[rangJeu]
    return MonitorGetPrimary()
}

EcranDeChiaki() {
    ; écran où se trouve le milieu de la fenêtre chiaki-ng (0 si elle n'est pas visible)
    fenetre := FenetreChiaki()
    if !fenetre
        return 0
    try
        WinGetPos(&fX, &fY, &fL, &fH, fenetre)
    catch                                       ; la fenêtre vient de se fermer
        return 0
    return EcranDuPoint(fX + fL // 2, fY + fH // 2)
}

EcranDuPoint(x, y) {
    ; numéro de l'écran qui contient ce point (0 si aucun)
    loop MonitorGetCount() {
        MonitorGet(A_Index, &eG, &eH, &eD, &eB)
        if (x >= eG && x < eD && y >= eH && y < eB)
            return A_Index
    }
    return 0
}

FenetreChiaki() {
    ; la fenêtre visible de chiaki-ng (la plus grande s'il y en a plusieurs)
    pid := ChiakiPid()
    if !pid
        return 0
    meilleure := 0, plusGrande := 0
    for fenetre in WinGetList("ahk_pid " pid) {
        if !DllCall("IsWindowVisible", "Ptr", fenetre) || DllCall("IsIconic", "Ptr", fenetre)
            continue
        try WinGetPos(,, &l, &h, fenetre)
        catch
            continue
        if (l * h > plusGrande)
            plusGrande := l * h, meilleure := fenetre
    }
    return meilleure
}

EcransTries() {
    ; numéros des écrans, rangés de gauche à droite (puis de haut en bas)
    ecrans := []
    loop MonitorGetCount() {
        num := A_Index
        MonitorGet(num, &g, &h)
        i := ecrans.Length + 1
        while (i > 1) {
            MonitorGet(ecrans[i - 1], &gAvant, &hAvant)
            if (gAvant < g || (gAvant = g && hAvant <= h))
                break
            i -= 1
        }
        ecrans.InsertAt(i, num)
    }
    return ecrans
}

NomEcran(rang) {
    ; nom d'un écran d'après sa place (rang 1 = le plus à gauche)
    ecrans := EcransTries()
    if (ecrans.Length = 2) {
        MonitorGet(ecrans[1],,, &d1)
        MonitorGet(ecrans[2], &g2)
        if (g2 >= d1)   ; côte à côte
            return rang = 1 ? "écran de gauche" : "écran de droite"
        MonitorGet(ecrans[rang],, &h)
        MonitorGet(ecrans[3 - rang],, &hAutre)
        return h < hAutre ? "écran du haut" : "écran du bas"
    }
    if (ecrans.Length = 3)
        return ["écran de gauche", "écran du milieu", "écran de droite"][rang]
    return "écran n°" rang
}

ZoneEcran(&zG, &zH, &zD, &zB) {
    ; zone utile (sans la barre des tâches) de l'écran du panneau
    try
        MonitorGetWorkArea(ecranPan, &zG, &zH, &zD, &zB)
    catch
        MonitorGetWorkArea(, &zG, &zH, &zD, &zB)
}

; ─────────────────────────────── OUTILS ───────────────────────────────
ChiakiDevant() {
    global nomChiaki
    try {
        nom := WinGetProcessName("A")
    } catch {
        return false
    }
    if !InStr(nom, CIBLE)
        return false
    nomChiaki := nom
    return true
}

ChiakiPid() {
    ; numéro du programme chiaki-ng s'il est ouvert, sinon 0
    for nom in [nomChiaki, "chiaki.exe", "chiaki-ng.exe"]
        if (nom != "" && (pid := ProcessExist(nom)))
            return pid
    return 0
}

ChiakiConnecte() {
    ; Pendant la partie, chiaki-ng garde une connexion ouverte vers le port 9295 de la PS5.
    ; On la cherche dans la liste des connexions de Windows.
    static PORT := ((9295 & 0xFF) << 8) | (9295 >> 8)   ; Windows range les octets du port à l'envers
    for famille in [2, 23] {                             ; 2 = adresses IPv4, 23 = adresses IPv6
        taille := 0
        DllCall("iphlpapi\GetExtendedTcpTable", "Ptr", 0, "UInt*", &taille, "Int", false, "UInt", famille, "Int", 4, "UInt", 0)
        table := Buffer(taille + 4096)
        taille := table.Size
        if DllCall("iphlpapi\GetExtendedTcpTable", "Ptr", table, "UInt*", &taille, "Int", false, "UInt", famille, "Int", 4, "UInt", 0)
            continue
        ; dans chaque ligne : l'état, le port distant et le numéro du programme
        ligne := famille = 2 ? 24 : 56
        pEtat := famille = 2 ? 0 : 48
        pPort := famille = 2 ? 16 : 44
        pProg := famille = 2 ? 20 : 52
        loop NumGet(table, 0, "UInt") {
            base := 4 + (A_Index - 1) * ligne
            if (NumGet(table, base + pEtat, "UInt") != 5)        ; 5 = connexion établie
                continue
            if ((NumGet(table, base + pPort, "UInt") & 0xFFFF) != PORT)
                continue
            try {
                if InStr(ProcessGetName(NumGet(table, base + pProg, "UInt")), CIBLE)
                    return true
            }
        }
    }
    return false
}

PeutAppuyer() => ChiakiDevant() && (!VERIF_PS5 || ChiakiConnecte())

ReprendreAncienneMemoire() {
    ; Turbo X s'appelait « Spam X » : on reprend ses réglages, une seule fois
    ancienne := A_AppData "\Spam X\memoire.ini"
    if (FileExist(MEMOIRE) || !FileExist(ancienne))
        return
    try {
        SplitPath(MEMOIRE,, &dossier)
        DirCreate(dossier)
        FileMove(ancienne, MEMOIRE)
        DirDelete(A_AppData "\Spam X")   ; seulement s'il est vide
    }
}

Souvenir(cle, mini, maxi) {
    ; valeur retenue la dernière fois, sauf si le réglage du haut du fichier a changé depuis
    try {
        if (IniRead(MEMOIRE, "memoire", cle "_origine") = ORIGINE[cle]) {
            valeur := IniRead(MEMOIRE, "memoire", cle)
            if (IsInteger(valeur) && valeur >= mini && valeur <= maxi)
                return Integer(valeur)
        }
    }
    return ORIGINE[cle]
}

Retenir() {
    for cle, valeur in Map("cadence", CADENCE_MS, "coin", COIN, "ecran", ECRAN, "sons", SONS) {
        Noter(cle, valeur)
        Noter(cle "_origine", ORIGINE[cle])
    }
}

Noter(cle, valeur) {
    ; écrit une information dans le fichier mémoire de Turbo X
    try {
        SplitPath(MEMOIRE,, &dossier)
        DirCreate(dossier)
        IniWrite(valeur, MEMOIRE, "memoire", cle)
    }
}

TempsActif() => cumul + (actif ? A_TickCount - debut : 0)

Chrono(ms) {
    s := ms // 1000
    return Format("{:02d}:{:02d}:{:02d}", s // 3600, Mod(s // 60, 60), Mod(s, 60))
}

Milliers(n) => RegExReplace(n, "\G\d+?(?=(\d{3})+$)", "$0 ")

Secondes(ms) => StrReplace(RTrim(RTrim(Format("{:.2f}", ms / 1000), "0"), "."), ".", ",") " s"

ParSeconde(ms) => StrReplace(RTrim(RTrim(Format("{:.1f}", 1000 / ms), "0"), "."), ".", ",")

Bips(f1, f2) {
    if !SONS
        return
    SoundBeep(f1, 70)
    SoundBeep(f2, 90)
}

DwmArrondi(fenetre) {
    ; coins arrondis (Windows 11)
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", fenetre.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
}

DwmBordure(fenetre, couleur) {
    ; bordure de la couleur choisie (Windows 11)
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", fenetre.Hwnd, "UInt", 34, "UInt*", BGR(couleur), "UInt", 4)
}

BGR(hex) {
    n := Integer("0x" hex)
    return ((n & 0xFF) << 16) | (n & 0xFF00) | ((n >> 16) & 0xFF)
}
