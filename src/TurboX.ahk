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
;    Couleurs : bouton palette du panneau, juste à gauche de ☰.
;
;    Au tout premier lancement, une visite guidée présente Turbo X en une minute
;    (elle reste dans le menu). Ensuite, l'assistant s'ouvre sur l'écran du jeu
;    et Turbo X ouvre chiaki-ng (connecté directement à la PS5 si elle est allumée).
;
;    Sécurité : rien n'est envoyé tant que la fenêtre chiaki-ng
;    n'est pas au premier plan et connectée à la PS5.
;    Mémoire : la cadence, le coin, l'écran du panneau, les sons
;    et les couleurs sont retenus d'une fois sur l'autre.
; ══════════════════════════════════════════════════════════════════════

#Requires AutoHotkey v2.0
#SingleInstance Force
DetectHiddenWindows(true)
SetWinDelay(-1)
CoordMode("Mouse", "Screen")

; Bibliothèques de Windows gardées chargées : le réseau (sinon AutoHotkey les recharge à chaque
; appel et la recherche de la PS5 perdrait sa connexion en route) et GDI+, qui dessine les couleurs
for dll in ["ws2_32", "iphlpapi", "gdiplus"]
    DllCall("LoadLibrary", "Str", dll, "Ptr")
jetonGdip := 0, entreeGdip := Buffer(24, 0)
NumPut("UInt", 1, entreeGdip)
DllCall("gdiplus\GdiplusStartup", "Ptr*", &jetonGdip, "Ptr", entreeGdip, "Ptr", 0)

;@Ahk2Exe-SetName Turbo X
;@Ahk2Exe-SetDescription Turbo X
;@Ahk2Exe-SetVersion 0.3.0
;@Ahk2Exe-SetCopyright Licence MIT
;@Ahk2Exe-SetOrigFilename TurboX.exe
VERSION := "0.3.0"   ; à changer en même temps que la ligne « SetVersion » juste au-dessus

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
; Couleurs de départ (la palette du panneau les change, et Turbo X s'en souvient) :
AMBIANCE       := "graphite"    ; fond et texte : graphite, ardoise, nuit, clair, ou un code couleur ("1B2430")
ACCENT         := "ivoire"      ; titres et boutons : ivoire, glacier, cobalt, rose, ou un code couleur
ETATS          := "classique"   ; actif, en pause, arrêté : classique, daltonisme, ou trois codes ("78BA8E,CFA359,D16C61")

; ─────────────────────────────── THÈME ───────────────────────────────
; La couleur sert d'abord à dire l'état : vert = actif ou validé, ambre = en pause ou en cours,
; rouge = arrêté ou pas encore validé. Voici les choix proposés par la palette du panneau.
; Pour une ambiance, les tons intermédiaires (surfaces, traits, textes secondaires) sont
; calculés à partir du fond et du texte, sauf s'ils sont donnés.
AMBIANCES := [{id: "graphite", nom: "Graphite", fond: "131211", texte: "EEE9E2"
                , surface: "1F1D1B", survol: "2C2926", ligne: "2B2926", doux: "A39D94", sombre: "6B665F"}
            , {id: "ardoise", nom: "Ardoise", fond: "172030", texte: "E6EBF2"}
            , {id: "nuit", nom: "Nuit", fond: "000000", texte: "EDEDED"}
            , {id: "clair", nom: "Clair", fond: "F3F0EA", texte: "1F1D1A"}]
; Pour un accent, « couleur » vide veut dire : la couleur du texte
ACCENTS := [{id: "ivoire", nom: "Ivoire", couleur: ""}
          , {id: "glacier", nom: "Glacier", couleur: "9DC2E5"}
          , {id: "cobalt", nom: "Cobalt", couleur: "7C9CE0"}
          , {id: "rose", nom: "Rose poudré", couleur: "E2A6B8"}]
; « Daltonisme » : bleu, jaune et orange, qui restent bien distincts quand on voit mal le rouge et le vert
JEUX_ETATS := [{id: "classique", nom: "Classique", actif: "78BA8E", pause: "CFA359", arret: "D16C61"}
             , {id: "daltonisme", nom: "Daltonisme", actif: "6FA8E3", pause: "E3C463", arret: "E0804F"}]

; Les couleurs utilisées partout, calculées d'après les choix (voir CalculerCouleurs)
C_FOND := C_SURFACE := C_SURVOL := C_LIGNE := C_TEXTE := C_DOUX := C_SOMBRE := ""
C_ACCENT := C_SUR_ACCENT := C_ACCENT_SURVOL := C_VERT := C_AMBRE := C_ROUGE := ""

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
I_COULEURS := Chr(0xE790)   ; palette de peintre
I_AIDE     := Chr(0xE897)
I_FERMER   := Chr(0xE711)
I_VALIDE   := Chr(0xEC61)   ; rond plein avec une coche
I_INVALIDE := Chr(0xEB90)   ; rond plein avec une croix
I_ENCOURS  := Chr(0xEA3B)   ; rond plein

LARGEUR  := 284   ; largeur du contenu du panneau
L_ASSIST := 400   ; largeur du contenu de l'assistant
L_COUL   := 292   ; largeur du contenu de la fenêtre des couleurs
L_VISITE := 300   ; largeur du contenu de la bulle de la visite guidée

; Style des fenêtres de Turbo X : toujours au-dessus, sans barre de titre ; jamais activées
; (+E0x08000000 : elles ne prennent jamais le clavier à chiaki-ng) ; dessinées d'abord en
; coulisse puis affichées d'un coup (+E0x02000000 : rien ne scintille quand elles changent)
FENETRE := "+AlwaysOnTop -Caption +ToolWindow +E0x08000000 +E0x02000000"

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
teintes        := []      ; les éléments à repeindre quand on change de couleurs (voir Teinter)
peints         := Map()   ; dernière couleur de texte donnée à chaque élément (voir Peindre)
fonds          := Map()   ; dernière couleur de fond donnée à chaque élément (voir Fond)
cliquables     := Map()   ; les éléments qui se cliquent : la souris y prend la forme d'une main
coulVisible    := false   ; la fenêtre des couleurs est-elle affichée ?
coulDeplace    := false   ; l'a-t-on déplacée à la main ? (elle ne suit alors plus le panneau)
pastilleSurvol := 0       ; numéro de la pastille sous la souris (0 = aucune)
derniereTeinte := 0       ; quand les couleurs ont été repeintes pour la dernière fois
palette        := {cible: "", t: 0, s: 0, l: 0, avant: [], tenu: 0}   ; la palette complète : ce qu'elle change, sa couleur (teinte, intensité, lumière), le curseur tenu
visiteVisible  := false   ; la visite guidée est-elle affichée ?
vEtapes        := []      ; ses étapes (celle des deux écrans seulement s'il y en a deux)
vEtape         := 1       ; l'étape affichée
vDepart        := {}      ; les réglages au début de l'étape (pour voir si la tâche est faite)
vFait          := false   ; la tâche de l'étape est-elle faite ?
vVuMasque      := false   ; le panneau a-t-il été masqué pendant l'étape « F7 » ?
vAssistant     := false   ; rouvrir l'assistant de démarrage à la fin de la visite ?
cadreZone      := ""      ; zone entourée par le cadre lumineux de la visite (et sa couleur)
cadreActuel    := ""      ; où le cadre est dessiné en ce moment (pendant son glissement aussi)
cadreAnim      := {}      ; son animation : d'où, vers où, depuis quand, en fondu ou non

; ─────────────────────────────── MÉMOIRE ───────────────────────────────
; La cadence, le coin, l'écran, les sons et les couleurs sont retenus d'une fois sur l'autre.
; Si tu modifies un de ces réglages en haut du fichier, c'est ta modification qui gagne.
MEMOIRE := A_AppData "\Turbo X\memoire.ini"
ReprendreAncienneMemoire()
ORIGINE    := Map("cadence", CADENCE_MS, "coin", COIN, "ecran", ECRAN, "sons", SONS
                , "ambiance", AMBIANCE, "accent", ACCENT, "etats", ETATS)
CADENCE_MS := Souvenir("cadence", CADENCE_MIN, CADENCE_MAX)
COIN       := Souvenir("coin", 1, 4)
ECRAN      := Souvenir("ecran", 0, 9)
SONS       := Souvenir("sons", 0, 1)
AMBIANCE   := SouvenirCouleur("ambiance", AMBIANCES)
ACCENT     := SouvenirCouleur("accent", ACCENTS)
ETATS      := SouvenirCouleur("etats", JEUX_ETATS)
try ps5.ip := IniRead(MEMOIRE, "memoire", "ip_ps5")                     ; dernière adresse connue de la PS5
try rangJeu := Integer(IniRead(MEMOIRE, "memoire", "ecran_jeu"))         ; écran où était chiaki-ng la dernière fois
CalculerCouleurs()

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
pan := Gui(FENETRE, "Turbo X")
pan.BackColor := C_FOND
pan.MarginX := 24
pan.MarginY := 20

; Liseré de couleur à gauche (vert / ambre / rouge selon l'état)
barre := pan.AddText("x0 y0 w3 h1 Background" C_ROUGE)

; En-tête : nom, version, voyant qui clignote à chaque appui, boutons des couleurs et du menu
pan.SetFont("s11 c" C_ACCENT, POLICE_TITRE)
Teinter(pan.AddText("xm ym h22 +0x200", "TURBO X"), "ACCENT")
pan.SetFont("s7 c" C_DOUX, POLICE_SB)
Teinter(pan.AddText("x+10 yp+4 h14 +0x200 Center", "  v" VERSION "  "), "DOUX", "SURFACE")
pan.SetFont("s9 c" C_SOMBRE, POLICE)
voyant := pan.AddText("x" (pan.MarginX + LARGEUR - 70) " ym w16 h22 +0x200 Right", "●")
pan.SetFont("s11 c" C_DOUX, ICONES)
btCouleurs := Cliquable(pan.AddText("x" (pan.MarginX + LARGEUR - 48) " ym w22 h22 +0x200 Center", I_COULEURS), BasculerCouleurs)
btMenu := Cliquable(pan.AddText("x" (pan.MarginX + LARGEUR - 22) " ym w22 h22 +0x200 Center", I_MENU), OuvrirMenu)
pan.OnEvent("ContextMenu", OuvrirMenu)   ; clic droit n'importe où sur le panneau

; Grand état : ACTIF / EN PAUSE / ARRÊTÉ
pan.SetFont("s20 c" C_ROUGE, ICONES)
icEtat := pan.AddText("xm y+18 w32 h46 +0x200", I_STOP)
pan.SetFont("s22 w700 c" C_ROUGE, POLICE_GRAND)
txEtat := pan.AddText("x+10 yp w" (LARGEUR - 42) " h46 +0x200", "ARRÊTÉ")
pan.SetFont("norm s9 c" C_DOUX, POLICE)   ; « norm » : la suite n'est plus en gras
txAide := Teinter(pan.AddText("xm y+0 w" LARGEUR, "Appuie sur F8 pour démarrer"), "DOUX")

; Statistiques
sep1      := Separateur()
txAppuis  := Teinter(Ligne("Appuis"), "TEXTE")
txTemps   := Teinter(Ligne("Temps actif"), "TEXTE")
txCadence := Teinter(Ligne("Cadence"), "TEXTE")
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
notif := Gui(FENETRE, "Turbo X · notification")
notif.BackColor := C_FOND
notif.MarginX := 22
notif.MarginY := 16
notif.SetFont("s20 c" C_VERT, ICONES)
nIcone := notif.AddText("xm ym w36 h56 +0x200 Center", I_PLAY)
notif.SetFont("s14 c" C_VERT, POLICE_TITRE)
nTitre := notif.AddText("x+14 ym+2 w330 h30 +0x200", "")
notif.SetFont("s9 c" C_DOUX, POLICE)
nSous := Teinter(notif.AddText("xp y+0 w330 h22 +0x200", ""), "DOUX")
notif.Show("Hide AutoSize")
DwmArrondi(notif)

; ─────────────────────────────── ASSISTANT DE DÉMARRAGE ───────────────────────────────
; Une liste qui se coche toute seule. Comme le panneau, elle ne prend jamais le clavier
; à chiaki-ng, même quand on clique sur ses boutons. On la déplace en la tenant par le fond.
asst := Gui(FENETRE, "Turbo X · assistant")
asst.BackColor := C_FOND
asst.MarginX := 28
asst.MarginY := 24

asst.SetFont("s13 c" C_ACCENT, POLICE_TITRE)
Teinter(asst.AddText("xm ym w" (L_ASSIST - 30) " h30 +0x200", "Assistant de démarrage"), "ACCENT")
asst.SetFont("s10 c" C_SOMBRE, ICONES)
aFermer := Cliquable(asst.AddText("x" (asst.MarginX + L_ASSIST - 24) " ym w24 h30 +0x200 Center", I_FERMER), (*) => AssistantMasquer(true))
Teinter(asst.AddText("xm y+16 w" L_ASSIST " h1"), , "LIGNE")

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
Teinter(asst.AddText("xm y+14 w" L_ASSIST " h1"), , "LIGNE")
asst.SetFont("s8 c" C_DOUX, POLICE_SB)
aEtiquette := asst.AddText("xm y+16 w" L_ASSIST, "À FAIRE MAINTENANT")
asst.SetFont("s10 c" C_TEXTE, POLICE)
aConseil := Teinter(asst.AddText("xm y+8 w" L_ASSIST " h64", ""), "TEXTE")
asst.SetFont("s9 c" C_SUR_ACCENT, POLICE_SB)
aBouton1 := Cliquable(Teinter(asst.AddText("xm y+8 w196 h36 +0x200 Center Background" C_ACCENT, ""), "SUR_ACCENT"), (*) => AssistantAction(1))
asst.SetFont("s9 c" C_TEXTE, POLICE_SB)
aBouton2 := Cliquable(Teinter(asst.AddText("x+8 yp w196 h36 +0x200 Center Background" C_SURFACE, ""), "TEXTE"), (*) => AssistantAction(2))

; Avancement
aJauge := Teinter(asst.AddText("xm y+20 w0 h3"), , "VERT")
aPiste := Teinter(asst.AddText("x+0 yp w" L_ASSIST " h3"), , "LIGNE")
asst.SetFont("s8 c" C_DOUX, POLICE)
aCompte := Teinter(asst.AddText("xm y+10 w180", ""), "DOUX")
asst.SetFont("s8 c" C_SOMBRE, POLICE)
Teinter(asst.AddText("x+0 yp w" (L_ASSIST - 180) " Right", "F1 : afficher / masquer cette liste"), "SOMBRE")

; Petit trait devant l'étape en cours. Créé en dernier : placé en haut (y0),
; il décalerait sinon tous les éléments ajoutés après lui.
aRepere := Teinter(asst.AddText("x14 y0 w3 h34"), , "ACCENT")

asst.Show("Hide AutoSize")
DwmArrondi(asst)
DwmBordure(asst, C_LIGNE)
aPiste.GetPos(&jaugeX,, &jaugeL)

; ─────────────────────────────── FENÊTRE DES COULEURS ───────────────────────────────
; Le bouton palette du panneau l'ouvre, à côté du panneau. Un clic sur une pastille change les
; couleurs tout de suite ; la dernière pastille d'une ligne ouvre la palette complète, où trois
; curseurs donnent n'importe quelle couleur. Comme le panneau, elle ne prend jamais le clavier.
coul := Gui(FENETRE, "Turbo X · couleurs")
coul.BackColor := C_FOND
coul.MarginX := 24
coul.MarginY := 20
coul.SetFont("s13 c" C_ACCENT, POLICE_TITRE)
Teinter(coul.AddText("xm ym w" (L_COUL - 30) " h30 +0x200", "Couleurs"), "ACCENT")
coul.SetFont("s10 c" C_SOMBRE, ICONES)
cFermer := Cliquable(coul.AddText("x" (coul.MarginX + L_COUL - 24) " ym w24 h30 +0x200 Center", I_FERMER), (*) => CouleursFermer())
Teinter(coul.AddText("xm y+14 w" L_COUL " h1"), , "LIGNE")

; Trois lignes de pastilles, avec à droite le nom du choix (ou de la pastille sous la souris)
pastilles  := []      ; chaque pastille : sa ligne, son type, ce qu'elle choisit, son nom
pastilleDe := Map()   ; numéro de la pastille d'après son contrôle
cNoms      := Map()
for rangee in [{id: "ambiance", titre: "AMBIANCE", liste: AMBIANCES}
             , {id: "accent", titre: "ACCENT", liste: ACCENTS}
             , {id: "etats", titre: "ÉTATS", liste: JEUX_ETATS}] {
    coul.SetFont("s8 c" C_DOUX, POLICE_SB)
    Teinter(coul.AddText("xm y+" (A_Index = 1 ? 16 : 14) " w110 h18 +0x200", rangee.titre), "DOUX")
    coul.SetFont("s8 c" C_SOMBRE, POLICE)
    cNoms[rangee.id] := Teinter(coul.AddText("x+0 yp w" (L_COUL - 110) " h18 +0x200 Right", ""), "SOMBRE")
    position := "xm y+6"
    for item in rangee.liste {
        AjouterPastille(position, {ligne: rangee.id, type: rangee.id, valeur: item.id})
        position := "x+6 yp"
    }
    if (rangee.id != "etats") {
        AjouterPastille(position, {ligne: rangee.id, type: "autre", cible: rangee.id})
        continue
    }
    ; pour les états : après les deux jeux, une pastille par état, pour choisir sa couleur
    Teinter(coul.AddText("x+10 yp+7 w1 h16"), , "LIGNE")
    for cible in ["actif", "pause", "arret"]
        AjouterPastille(A_Index = 1 ? "x+10 yp-7" : "x+6 yp", {ligne: "etats", type: "etat", cible: cible})
}

; La palette complète, cachée tant qu'on n'a pas choisi « autre couleur »
pSep := Teinter(coul.AddText("xm y+18 w" L_COUL " h1"), , "LIGNE")
coul.SetFont("s8 c" C_DOUX, POLICE_SB)
pEtiquette := Teinter(coul.AddText("xm y+14 w200 h18 +0x200", ""), "DOUX")
coul.SetFont("s9 c" C_TEXTE, POLICE_SB)
pCode := Cliquable(coul.AddText("x+0 yp w" (L_COUL - 200) " h18 +0x200 Right", ""), PaletteCode)
elementsPalette := [pSep, pEtiquette, pCode]
pCurseurs := []
for nomCurseur in ["Teinte", "Intensité", "Lumière"] {
    coul.SetFont("s9 c" C_DOUX, POLICE)
    elementsPalette.Push(Teinter(coul.AddText("xm y+" (A_Index = 1 ? 10 : 2) " w76 h26 +0x200", nomCurseur), "DOUX"))
    glissiere := Cliquable(coul.AddPicture("x+0 yp w" (L_COUL - 76) " h26"), (*) => 0)   ; le glissement est suivi par Glisser
    pCurseurs.Push(glissiere), elementsPalette.Push(glissiere)
}
coul.SetFont("s9 c" C_SUR_ACCENT, POLICE_SB)
pValider := Cliquable(Teinter(coul.AddText("xm y+14 w" ((L_COUL - 8) // 2) " h32 +0x200 Center Background" C_ACCENT, "Valider"), "SUR_ACCENT"), (*) => PaletteFermer(true))
coul.SetFont("s9 c" C_TEXTE, POLICE_SB)
pAnnuler := Cliquable(Teinter(coul.AddText("x+8 yp w" ((L_COUL - 8) // 2) " h32 +0x200 Center Background" C_SURFACE, "Annuler"), "TEXTE"), (*) => PaletteFermer(false))
elementsPalette.Push(pValider, pAnnuler)

; En bas : revenir aux couleurs de départ
cSepBas := Teinter(coul.AddText("xm y+18 w" L_COUL " h1"), , "LIGNE")
coul.SetFont("s8 c" C_DOUX, POLICE)
cOrigine := Cliquable(coul.AddText("xm y+12 h18 +0x200", "Remettre les couleurs d'origine"), CouleursOrigine)

; Palette cachée : le bas de la fenêtre remonte d'autant
pSep.GetPos(, &yPalette)
cSepBas.GetPos(, &yBas)
cOrigine.GetPos(, &yOrigine)
MontrerPalette(false)
DwmArrondi(coul)
DwmBordure(coul, C_LIGNE)
for p in pastilles
    DessinerPastille(p)

; ─────────────────────────────── VISITE GUIDÉE ───────────────────────────────
; Au tout premier lancement (puis depuis le menu), une bulle présente Turbo X pas à pas,
; et un cadre lumineux entoure ce dont elle parle. Certaines étapes se font en appuyant sur la touche.
ETAPES_VISITE := [{titre: "Bienvenue dans Turbo X", cible: ""
        , texte: "Turbo X appuie sur X à ta place, dans chiaki-ng. Cette visite te montre comment t'en servir, en une minute."}
    , {titre: "Le panneau", cible: "panneau"
        , texte: "Il reste au-dessus du jeu, sur l'écran de chiaki-ng, sans jamais prendre le clavier à chiaki-ng : tu joues normalement."}
    , {titre: "L'état, en grand", cible: "etat"
        , texte: "ACTIF : Turbo X appuie sur X. EN PAUSE : il attend, et la phrase juste dessous dit pourquoi. ARRÊTÉ : il ne fait rien."}
    , {titre: "Démarrer et arrêter", cible: "etat"
        , texte: "Dans le jeu, place-toi là où il faut appuyer sur X, puis appuie sur F8. Encore F8 pour arrêter. Par sécurité, Turbo X n'appuie que dans chiaki-ng, connecté à ta PS5."}
    , {titre: "La cadence", cible: "cadence", tache: "cadence", consigne: "Appuie sur F10, ou sur F9"
        , texte: "Turbo X appuie de 1 à 10 fois par seconde : F10 va plus vite, F9 plus lentement."}
    , {titre: "Le coin du panneau", cible: "panneau", tache: "coin", consigne: "Appuie sur F6"
        , texte: "Le panneau se range dans le coin de l'écran que tu préfères."}
    , {titre: "Masquer le panneau", cible: "panneau", tache: "masquer", consigne: "Appuie sur F7, puis encore sur F7"
        , texte: "Pour voir tout le jeu, masque le panneau : Turbo X continue de marcher."}
    , {titre: "Deux écrans", cible: "panneau", tache: "ecran", consigne: "Appuie sur F5", ecrans: 2
        , texte: "Le panneau suit l'écran de chiaki-ng. Tu peux aussi le mettre sur l'écran de ton choix."}
    , {titre: "Le menu et les couleurs", cible: "menu", tache: "couleurs", consigne: "Clique sur la palette"
        , texte: "Le bouton aux trois traits, ou un clic droit sur le panneau, ouvre le menu : sons, réglages, cette visite… Juste à côté, la palette change les couleurs."}
    , {titre: "Tout est prêt", cible: ""
        , texte: "Pour connecter ta PS5, l'assistant de démarrage te guide : F1 l'ouvre à tout moment. Bon jeu !"}]

visite := Gui(FENETRE, "Turbo X · visite guidée")
visite.BackColor := C_FOND
visite.MarginX := 26
visite.MarginY := 22
visite.SetFont("s8 c" C_DOUX, POLICE_SB)
vEtiquette := Teinter(visite.AddText("xm ym w" (L_VISITE - 30) " h22 +0x200", ""), "DOUX")
visite.SetFont("s10 c" C_SOMBRE, ICONES)
vFermer := Cliquable(visite.AddText("x" (visite.MarginX + L_VISITE - 24) " ym w24 h22 +0x200 Center", I_FERMER), (*) => VisiteFermer())
visite.SetFont("s14 c" C_ACCENT, POLICE_TITRE)
vTitre := Teinter(visite.AddText("xm y+10 w" L_VISITE " h32 +0x200", ""), "ACCENT")
visite.SetFont("s10 c" C_DOUX, POLICE)
vTexte := Teinter(visite.AddText("xm y+4 w" L_VISITE " h40", ""), "DOUX")
visite.SetFont("s12 c" C_AMBRE, ICONES)
vTacheIcone := visite.AddText("xm y+12 w24 h30 +0x200 Center", I_ENCOURS)
visite.SetFont("s10 c" C_TEXTE, POLICE_SB)
vTache := visite.AddText("x+10 yp w" (L_VISITE - 34) " h30 +0x200", "")
visite.SetFont("s9 c" C_SUR_ACCENT, POLICE_SB)
vBouton1 := Cliquable(Teinter(visite.AddText("xm y+18 w" ((L_VISITE - 8) // 2) " h34 +0x200 Center Background" C_ACCENT, ""), "SUR_ACCENT"), (*) => VisiteBouton(1))
visite.SetFont("s9 c" C_TEXTE, POLICE_SB)
vBouton2 := Cliquable(Teinter(visite.AddText("x+8 yp w" ((L_VISITE - 8) // 2) " h34 +0x200 Center Background" C_SURFACE, ""), "TEXTE"), (*) => VisiteBouton(2))
vJauge := Teinter(visite.AddText("xm y+18 w0 h3"), , "ACCENT")
vPiste := Teinter(visite.AddText("x+0 yp w" L_VISITE " h3"), , "LIGNE")
visite.Show("Hide AutoSize")
DwmArrondi(visite)
DwmBordure(visite, C_LIGNE)
vPiste.GetPos(&vJaugeX,, &vJaugeL)

; Le cadre lumineux : une fenêtre transparente, que les clics traversent
cadre := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000 +E0x80000 +E0x20", "Turbo X · cadre")

; ─────────────────────────────── ICÔNE PRÈS DE L'HORLOGE ───────────────────────────────
A_TrayMenu.Delete()
A_TrayMenu.Add("Démarrer / arrêter`tF8", Basculer)
A_TrayMenu.Add("Assistant de démarrage`tF1", BasculerAssistant)
A_TrayMenu.Add("Visite guidée", (*) => VisiteOuvrir())
A_TrayMenu.Add()
A_TrayMenu.Add("Afficher / masquer le panneau`tF7", BasculerPanneau)
A_TrayMenu.Add("Changer de coin`tF6", ChangerCoin)
A_TrayMenu.Add("Changer d'écran`tF5", ChangerEcran)
A_TrayMenu.Add("Couleurs…", BasculerCouleurs)
A_TrayMenu.Add()
A_TrayMenu.Add("Sons", BasculerSons)
A_TrayMenu.Add("Remettre les réglages d'origine", RemettreOrigine)
A_TrayMenu.Add()
A_TrayMenu.Add("Quitter`tCtrl+F8", Quitter)
A_TrayMenu.Default := "Démarrer / arrêter`tF8"
A_IconTip := "Turbo X"
CocherSons()

OnExit(Fermeture)
OnMessage(0x201, Glisser)   ; clic gauche : déplacer l'assistant ou les couleurs, tenir un curseur de la palette
OnMessage(0x20, Curseur)    ; la souris prend la forme d'une main au-dessus de ce qui se clique
lancement      := OUVRIR_CHIAKI ? "attente" : "fait"
lancementDebut := A_TickCount
SetTimer(Rafraichir, 250)
SetTimer(Survol, 50)
; la toute première fois, la visite guidée ; ensuite, directement l'assistant
premiereFois := !IniRead(MEMOIRE, "memoire", "visite_vue", 0)
if premiereFois
    VisiteOuvrir(true)
else
    AssistantAfficher()
Notifier(I_MANETTE, C_ACCENT, "TURBO X EST PRÊT", premiereFois ? "Suis la visite guidée : une minute suffit" : "Suis l'assistant : il te guide pas à pas")

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
    Notifier(I_CHRONO, C_ACCENT, "CADENCE : " ParSeconde(CADENCE_MS) " PAR SECONDE", "Un appui toutes les " Secondes(CADENCE_MS) limite)
}

BasculerPanneau(*) {
    global visible
    visible := !visible
    if visible
        pan.Show("NoActivate")
    else
        pan.Hide()
    Recaler()
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
        Notifier(I_ECRAN, C_ACCENT, "UN SEUL ÉCRAN", "F5 sert quand un deuxième écran est branché")
        return
    }
    ECRAN := ECRAN >= nb ? 0 : ECRAN + 1
    PlacerPanneau()
    Retenir()
    if (ECRAN = 0)
        Notifier(I_ECRAN, C_ACCENT, "PANNEAU : ÉCRAN DU JEU", "Il suit la fenêtre chiaki-ng  ·  F5 pour changer")
    else
        Notifier(I_ECRAN, C_ACCENT, "PANNEAU : " StrUpper(NomEcran(ECRAN)), "Il reste sur cet écran  ·  F5 pour changer")
}

BasculerSons(*) {
    global SONS
    SONS := !SONS
    CocherSons()
    Retenir()
    if SONS
        Notifier(I_SON, C_ACCENT, "SONS ACTIVÉS", "Petits bips au démarrage et à l'arrêt")
    else
        Notifier(I_MUET, C_ACCENT, "SONS COUPÉS", "Plus aucun bip")
    Bips(660, 990)
}

RemettreOrigine(*) {
    global CADENCE_MS, COIN, ECRAN, SONS, AMBIANCE, ACCENT, ETATS
    if (palette.cible != "")
        PaletteFermer(true)
    CADENCE_MS := ORIGINE["cadence"]
    COIN       := ORIGINE["coin"]
    ECRAN      := ORIGINE["ecran"]
    SONS       := ORIGINE["sons"]
    AMBIANCE   := CouleurDepart("ambiance", AMBIANCES)
    ACCENT     := CouleurDepart("accent", ACCENTS)
    ETATS      := CouleurDepart("etats", JEUX_ETATS)
    if actif
        SetTimer(Appuyer, CADENCE_MS)
    CocherSons()
    AppliquerCouleurs()
    PlacerPanneau()
    Retenir()
    Rafraichir()
    Notifier(I_ORIGINE, C_ACCENT, "RÉGLAGES D'ORIGINE", "Tout est remis comme au départ")
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
    actuelle := WinExist("A")
    if (avant && avant != A_ScriptHwnd && (!actuelle || actuelle = A_ScriptHwnd))
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
        PeindreEtat()
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
        Peindre(txChiaki, CouleurChiaki())
        txChiaki.Value := chiaki = 2 ? "au premier plan" : chiaki = 1 ? "en arrière-plan" : "fermé"
    }

    codePs5 := connecte ? 2 : !VERIF_PS5 ? 3 : ouvert ? 1 : 0
    if (codePs5 != dernierPS5) {
        dernierPS5 := codePs5
        Peindre(txPS5, CouleurPs5())
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

    ; l'assistant et la visite guidée se mettent à jour
    if asstVisible
        AssistantMaj(devant, ouvert, connecte, etat)
    if visiteVisible
        VisiteMaj()

    ; garde les fenêtres de Turbo X au-dessus de tout, sans voler le clavier à chiaki-ng.
    ; Chacune est glissée juste sous la précédente : leur ordre ne change jamais, rien ne clignote.
    dessus := -1
    for f in [[visiteVisible && cadreZone != "", cadre], [visiteVisible, visite], [coulVisible, coul]
            , [asstVisible, asst], [visible, pan]]
        if f[1]
            dessus := AuDessus(f[2], dessus)
}

Survol() {
    ; toutes les 50 ms : ce qui se clique s'éclaire quand la souris passe dessus
    MouseGetPos(,,, &sous, 2)
    Peindre(btMenu, sous = btMenu.Hwnd ? C_TEXTE : C_DOUX)
    Peindre(btCouleurs, sous = btCouleurs.Hwnd || coulVisible ? C_TEXTE : C_DOUX)
    if asstVisible {
        Fond(aBouton1, sous = aBouton1.Hwnd ? C_ACCENT_SURVOL : C_ACCENT)
        Fond(aBouton2, sous = aBouton2.Hwnd ? C_SURVOL : C_SURFACE)
        Peindre(aFermer, sous = aFermer.Hwnd ? C_TEXTE : C_SOMBRE)
    }
    if coulVisible
        CouleursSurvol(sous)
    if visiteVisible {
        Fond(vBouton1, sous = vBouton1.Hwnd ? C_ACCENT_SURVOL : C_ACCENT)
        Fond(vBouton2, sous = vBouton2.Hwnd ? C_SURVOL : C_SURFACE)
        Peindre(vFermer, sous = vFermer.Hwnd ? C_TEXTE : C_SOMBRE)
    }
}

PeindreEtat() {
    switch dernierEtat {
        case "actif": AfficherEtat(C_VERT, I_PLAY, "ACTIF")
        case "pause": AfficherEtat(C_AMBRE, I_PAUSE, "EN PAUSE")
        default:      AfficherEtat(C_ROUGE, I_STOP, "ARRÊTÉ")
    }
}

; couleur des lignes « chiaki-ng » (2 = au premier plan, 1 = en arrière-plan, 0 = fermé)
; et « PS5 » (2 = connectée, 3 = non vérifiée, 1 ou 0 = pas connectée)
CouleurChiaki() => dernierChiaki = 2 ? C_VERT : dernierChiaki = 1 ? C_AMBRE : C_ROUGE
CouleurPs5() => dernierPS5 = 2 ? C_VERT : dernierPS5 = 3 ? C_DOUX : dernierPS5 = 1 ? C_AMBRE : C_ROUGE

AfficherEtat(couleur, icone, titre) {
    ; (chaque élément n'est redessiné que s'il change : pas de clignotement)
    Peindre(icEtat, couleur)
    Maj(icEtat, icone)
    Peindre(txEtat, couleur)
    Maj(txEtat, titre)
    Fond(barre, couleur)
    DwmBordure(pan, couleur)
    if (A_IconTip != "Turbo X  ·  " titre)
        A_IconTip := "Turbo X  ·  " titre
}

AllumerVoyant(allume) {
    Peindre(voyant, allume ? C_VERT : C_SOMBRE)
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
    Recaler()
}

Recaler() {
    ; la fenêtre des couleurs et la visite guidée suivent le panneau
    if (coulVisible && !coulDeplace)
        CouleursPlacer()
    if visiteVisible
        VisiteMaj()
}

AuDessus(fenetre, sous := -1) {
    ; place la fenêtre juste sous une autre (-1 : au-dessus de tout), sans l'activer ; renvoie sa poignée
    DllCall("SetWindowPos", "Ptr", fenetre.Hwnd, "Ptr", sous, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)
    return fenetre.Hwnd
}

CocherSons() {
    if SONS
        A_TrayMenu.Check("Sons")
    else
        A_TrayMenu.Uncheck("Sons")
}

Ligne(nom) {
    pan.SetFont("norm s9 c" C_DOUX, POLICE)
    Teinter(pan.AddText("xm y+6 w104 h22 +0x200", nom), "DOUX")
    pan.SetFont("norm s10 c" C_TEXTE, POLICE_SB)
    return pan.AddText("x+0 yp w" (LARGEUR - 104) " h22 +0x200", "")
}

Separateur() {
    return Teinter(pan.AddText("xm y+14 w" LARGEUR " h1"), , "LIGNE")
}

AjouterTouche(cle, texte, position) {
    pan.SetFont("norm s8 c" C_TEXTE, POLICE_SB)
    Teinter(pan.AddText(position " h20 +0x200 Center", "  " cle "  "), "TEXTE", "SURFACE")
    pan.SetFont("norm s8 c" C_DOUX, POLICE)
    Teinter(pan.AddText("x+8 yp h20 +0x200", texte), "DOUX")
}

Maj(ctrl, texte) {
    if (ctrl.Value != texte)
        ctrl.Value := texte
}

Peindre(ctrl, couleur) {
    ; change la couleur d'un texte, seulement si elle a changé (évite le clignotement)
    if (peints.Get(ctrl.Hwnd, "") != couleur) {
        peints[ctrl.Hwnd] := couleur
        ctrl.SetFont("c" couleur)
    }
}

Fond(ctrl, couleur) {
    ; change la couleur de fond d'un texte ou d'un bouton, seulement si elle a changé
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

Teinter(ctrl, texte := "", fond := "") {
    ; donne à un élément les couleurs de son rôle (« TEXTE », « LIGNE »…) et le retient,
    ; pour pouvoir tout repeindre quand on change de couleurs
    teintes.Push(e := {ctrl: ctrl, texte: texte, fond: fond, peint: ""})
    Repeindre(e)
    return ctrl
}

Repeindre(e) {
    ; redonne à un élément retenu par Teinter les couleurs de son rôle, si elles ont changé
    texte := e.texte != "" ? Ton(e.texte) : "", fond := e.fond != "" ? Ton(e.fond) : ""
    if (e.peint = texte "/" fond)
        return
    e.peint := texte "/" fond
    if (texte != "")
        e.ctrl.SetFont("c" texte)
    if (fond != "") {
        e.ctrl.Opt("Background" fond)
        e.ctrl.Redraw()
    }
}

Ton(role) {
    ; la couleur actuelle d'un rôle
    switch role {
        case "FOND":       return C_FOND
        case "SURFACE":    return C_SURFACE
        case "LIGNE":      return C_LIGNE
        case "TEXTE":      return C_TEXTE
        case "DOUX":       return C_DOUX
        case "SOMBRE":     return C_SOMBRE
        case "ACCENT":     return C_ACCENT
        case "SUR_ACCENT": return C_SUR_ACCENT
        case "VERT":       return C_VERT
    }
}

Cliquable(ctrl, action) {
    ; un élément qui se clique : il réagit au clic, et la souris y prend la forme d'une main
    ctrl.OnEvent("Click", action)
    cliquables[ctrl.Hwnd] := true
    return ctrl
}

Curseur(wParam, *) {
    ; au-dessus de ce qui se clique, la souris prend la forme d'une main
    if cliquables.Has(wParam) {
        DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
        return true
    }
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
        Notifier(I_AIDE, C_ACCENT, "ASSISTANT MASQUÉ", "Appuie sur F1 pour le rouvrir")
}

AssistantAction(n) {
    ; un bouton de l'assistant a été cliqué
    if (n <= actions.Length)
        actions[n]()
}

AssistantMaj(devant, ouvert, connecte, etat) {
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
    ; l'assistant et la fenêtre des couleurs se déplacent en les tenant par le fond ou par un texte
    ; (pas par un bouton) ; un curseur de la palette suit la souris tant qu'on le tient
    global asstDeplace, coulDeplace
    if (hwnd = asst.Hwnd) {
        asstDeplace := true            ; il ne suivra plus l'écran du jeu tout seul
        PostMessage(0xA1, 2,,, asst)   ; comme si on tenait une barre de titre
    } else if (hwnd = coul.Hwnd) {
        coulDeplace := true            ; elle ne suivra plus le panneau tout seule
        PostMessage(0xA1, 2,,, coul)
    } else {
        for i, glissiere in pCurseurs
            if (hwnd = glissiere.Hwnd)
                return PaletteTenir(i)
    }
}

; ─────────────────────────────── COULEURS ───────────────────────────────
BasculerCouleurs(*) {
    if coulVisible
        CouleursFermer()
    else
        CouleursOuvrir()
}

CouleursOuvrir() {
    global coulVisible, coulDeplace
    coulVisible := true
    coulDeplace := false
    CouleursNoms()
    CouleursPlacer()
    coul.Show("NoActivate")
    if visiteVisible
        VisiteMaj()
}

CouleursFermer() {
    global coulVisible
    if (palette.cible != "")
        PaletteFermer(true)
    coulVisible := false
    coul.Hide()
    if visiteVisible
        VisiteMaj()
}

CouleursPlacer() {
    ; à côté du panneau, du côté du milieu de l'écran, alignée sur son haut (ou sur son bas en bas d'écran)
    WinGetPos(&pX, &pY, &pL, &pH, pan)
    WinGetPos(&cX, &cY, &cL, &cH, coul)
    ZoneEcran(&zG, &zH, &zD, &zB)
    ecart := Round(12 * A_ScreenDPI / 96)
    x := (COIN = 2 || COIN = 3) ? pX - cL - ecart : pX + pL + ecart
    y := Max(zH + ecart, Min(COIN >= 3 ? pY + pH - cH : pY, zB - cH - ecart))
    if (x != cX || y != cY)
        WinMove(x, y,,, coul)
}

CouleursOrigine(*) {
    ; « Remettre les couleurs d'origine »
    global AMBIANCE, ACCENT, ETATS
    if (palette.cible != "")
        PaletteFermer(true)
    AMBIANCE := CouleurDepart("ambiance", AMBIANCES)
    ACCENT   := CouleurDepart("accent", ACCENTS)
    ETATS    := CouleurDepart("etats", JEUX_ETATS)
    AppliquerCouleurs()
    Retenir()
    Notifier(I_ORIGINE, C_ACCENT, "COULEURS D'ORIGINE", "Turbo X a retrouvé ses couleurs de départ")
}

AjouterPastille(position, p) {
    ; une pastille ronde de la fenêtre des couleurs (dessinée par DessinerPastille)
    p.ctrl := Cliquable(coul.AddPicture(position " w30 h30"), PastilleClic.Bind(pastilles.Length + 1))
    pastilles.Push(p)
    pastilleDe[p.ctrl.Hwnd] := pastilles.Length
}

PastilleClic(i, *) {
    ; un clic sur une pastille : la couleur change tout de suite, ou la palette complète s'ouvre
    global AMBIANCE, ACCENT, ETATS
    p := pastilles[i]
    switch p.type {
        case "ambiance": AMBIANCE := p.valeur
        case "accent":   ACCENT := p.valeur
        case "etats":    ETATS := p.valeur
        default:         return PaletteOuvrir(p.cible)
    }
    ; la palette ouverte sur cette ligne n'a plus lieu d'être
    if (palette.cible != "" && LigneDeCible(palette.cible) = p.ligne)
        PaletteFermer(true)
    AppliquerCouleurs()
    Retenir()
}

CouleursSurvol(sous) {
    ; sous la souris, la pastille s'entoure d'un anneau et son nom s'affiche ; les boutons s'éclairent
    global pastilleSurvol
    i := pastilleDe.Get(sous, 0)
    if (i != pastilleSurvol) {
        avant := pastilleSurvol, pastilleSurvol := i
        if avant
            DessinerPastille(pastilles[avant])
        if i
            DessinerPastille(pastilles[i], true)
        CouleursNoms()
    }
    Peindre(cFermer, sous = cFermer.Hwnd ? C_TEXTE : C_SOMBRE)
    Peindre(cOrigine, sous = cOrigine.Hwnd ? C_TEXTE : C_DOUX)
    Peindre(pCode, sous = pCode.Hwnd ? C_ACCENT : C_TEXTE)
    Fond(pValider, sous = pValider.Hwnd ? C_ACCENT_SURVOL : C_ACCENT)
    Fond(pAnnuler, sous = pAnnuler.Hwnd ? C_SURVOL : C_SURFACE)
}

CouleursNoms() {
    ; à droite de chaque ligne : le nom de la pastille sous la souris, sinon celui du choix actuel
    for ligne, ctrl in cNoms {
        if (pastilleSurvol && pastilles[pastilleSurvol].ligne = ligne)
            Maj(ctrl, NomPastille(pastilles[pastilleSurvol]))
        else
            Maj(ctrl, NomChoix(ligne))
    }
}

NomChoix(ligne) {
    switch ligne {
        case "ambiance": return (a := Choix(AMBIANCES, AMBIANCE)) ? a.nom : "Sur mesure  ·  #" AMBIANCE
        case "accent":   return (a := Choix(ACCENTS, ACCENT)) ? NomAccent(a) : "Sur mesure  ·  #" ACCENT
        default:         return (e := Choix(JEUX_ETATS, ETATS)) ? e.nom : "Sur mesure"
    }
}

NomPastille(p) {
    switch p.type {
        case "ambiance": return Choix(AMBIANCES, p.valeur).nom
        case "accent":   return NomAccent(Choix(ACCENTS, p.valeur))
        case "etats":    return Choix(JEUX_ETATS, p.valeur).nom
        case "autre":    return "Autre couleur…"
        default:         return NomCible(p.cible) " : autre couleur…"
    }
}

NomAccent(a) {
    ; l'accent « couleur du texte » est ivoire sur un fond sombre, encre sur un fond clair
    return (a.couleur = "" && Luminance(C_FOND) > 0.5) ? "Encre" : a.nom
}

PastilleChoisie(p) {
    switch p.type {
        case "ambiance": return AMBIANCE = p.valeur
        case "accent":   return ACCENT = p.valeur
        case "etats":    return ETATS = p.valeur
        case "autre":    return EstCode(p.cible = "ambiance" ? AMBIANCE : ACCENT)
        default:         return !Choix(JEUX_ETATS, ETATS)   ; les trois, quand les états sont sur mesure
    }
}

DessinerPastille(p, sousLaSouris := false) {
    ; une pastille ronde ; un anneau autour quand elle est choisie, plus discret sous la souris.
    ; Elle n'est redessinée que si son apparence a changé.
    switch p.type {
        case "ambiance":              ; le fond, avec au milieu un point de la couleur du texte
            a := TonsAmbiance(p.valeur), couleurs := [a.fond, a.texte]
        case "accent":
            couleurs := [CouleurAccent(Choix(ACCENTS, p.valeur))]
        case "etats":                 ; les trois couleurs du jeu
            e := Choix(JEUX_ETATS, p.valeur)
            couleurs := [Lisible(e.actif, C_FOND), Lisible(e.pause, C_FOND), Lisible(e.arret, C_FOND)]
        case "etat":
            couleurs := [CouleurCible(p.cible)]
        default:                      ; « autre couleur » : au milieu, la couleur sur mesure s'il y en a une
            couleurs := [EstCode(p.cible = "ambiance" ? AMBIANCE : ACCENT) ? CouleurCible(p.cible) : C_FOND]
    }
    anneau := PastilleChoisie(p) ? C_TEXTE : sousLaSouris ? C_SOMBRE : ""
    apparence := C_FOND " " C_TEXTE " " anneau
    for c in couleurs
        apparence .= " " c
    if (p.HasOwnProp("apparence") && p.apparence = apparence)
        return
    p.apparence := apparence

    ControlGetPos(,, &l,, p.ctrl)
    k := l / 30                       ; la pastille fait 30 unités de côté
    d := 20 * k, x := (l - d) / 2
    t := Toile(l, l)
    t.Effacer(Argb(C_FOND))
    switch p.type {
        case "ambiance":
            t.Disque(x, x, d, Argb(couleurs[1]))
            t.Disque(x + d * 0.34, x + d * 0.34, d * 0.32, Argb(couleurs[2]))
        case "etats":
            for i, c in couleurs
                t.Part(x, x, d, -90 + 120 * (i - 1), 121, Argb(c))
        case "autre":                 ; un cercle arc-en-ciel
            loop 36
                t.Part(x, x, d, (A_Index - 1) * 10 - 90, 11, Argb(TslVersHexa((A_Index - 1) * 10, 0.55, 0.62)))
            t.Disque(x + d * 0.22, x + d * 0.22, d * 0.56, Argb(couleurs[1]))
        default:
            t.Disque(x, x, d, Argb(couleurs[1]))
    }
    t.Cercle(x, x, d, k, Argb(C_TEXTE, 0x2A))   ; fin liseré : la pastille se voit même sur un fond de sa couleur
    if (anneau != "")
        t.Cercle(2 * k, 2 * k, l - 4 * k, 1.6 * k, Argb(anneau))
    t.Poser(p.ctrl)
}

CouleurAccent(a) => a.couleur = "" ? C_TEXTE : Lisible(a.couleur, C_FOND)

CouleurCible(cible) {
    ; la couleur actuelle de ce que la palette peut changer
    switch cible {
        case "ambiance": return C_FOND
        case "accent":   return C_ACCENT
        case "actif":    return C_VERT
        case "pause":    return C_AMBRE
        default:         return C_ROUGE
    }
}

NomCible(cible) {
    switch cible {
        case "ambiance": return "Fond"
        case "accent":   return "Accent"
        case "actif":    return "Actif"
        case "pause":    return "En pause"
        default:         return "Arrêté"
    }
}

LigneDeCible(cible) => (cible = "ambiance" || cible = "accent") ? cible : "etats"

; ─────────────────────────────── PALETTE COMPLÈTE ───────────────────────────────
; Trois curseurs : la teinte (le tour de l'arc-en-ciel), l'intensité (du gris à la couleur pure)
; et la lumière (du noir au blanc). Tout se repeint pendant qu'on les fait glisser.
PaletteOuvrir(cible) {
    if (palette.cible = "")
        palette.avant := [AMBIANCE, ACCENT, ETATS]   ; pour « Annuler »
    palette.cible := cible
    tsl := HexaVersTsl(CouleurCible(cible))
    palette.t := tsl.t, palette.s := tsl.s, palette.l := tsl.l
    Maj(pEtiquette, "AUTRE COULEUR  ·  " StrUpper(NomCible(cible)))
    PaletteDessiner()
    if !pSep.Visible
        MontrerPalette(true)
}

PaletteFermer(garder) {
    ; « Valider » garde la nouvelle couleur, « Annuler » remet les couleurs d'avant
    global AMBIANCE, ACCENT, ETATS
    if !garder
        AMBIANCE := palette.avant[1], ACCENT := palette.avant[2], ETATS := palette.avant[3]
    palette.cible := ""
    palette.tenu := 0
    SetTimer(PaletteSuivre, 0)
    MontrerPalette(false)
    AppliquerCouleurs()
    Retenir()
}

MontrerPalette(oui) {
    ; montre ou cache la palette ; le bas de la fenêtre descend ou remonte d'autant
    for ctrl in elementsPalette
        ctrl.Visible := oui
    decalage := oui ? 0 : yBas - yPalette
    cSepBas.Move(, yBas - decalage)
    cOrigine.Move(, yOrigine - decalage)
    coul.Show("AutoSize " (coulVisible ? "NoActivate" : "Hide"))
    if (coulVisible && !coulDeplace)
        CouleursPlacer()
}

PaletteTenir(i) {
    ; on vient d'appuyer sur un curseur : il suit la souris jusqu'à ce qu'on relâche
    palette.tenu := i
    PaletteSuivre()
    SetTimer(PaletteSuivre, 15)
}

PaletteSuivre() {
    if (!GetKeyState("LButton", "P") || palette.cible = "") {
        SetTimer(PaletteSuivre, 0)
        palette.tenu := 0
        AppliquerCouleurs()           ; la dernière position, sans attendre
        return
    }
    r := RectEcran(pCurseurs[palette.tenu])
    MouseGetPos(&mX)
    marge := (r.b - r.y) / 2
    v := Max(0, Min(1, (mX - r.x - marge) / (r.d - r.x - 2 * marge)))
    switch palette.tenu {
        case 1: nouveau := v * 360, ancien := palette.t, palette.t := nouveau
        case 2: nouveau := v, ancien := palette.s, palette.s := nouveau
        default: nouveau := v, ancien := palette.l, palette.l := nouveau
    }
    if (nouveau != ancien)
        PaletteChanger()
}

PaletteChanger() {
    ; la couleur de la palette remplace celle qu'elle change ; tout se repeint, 12 fois par seconde au plus
    global AMBIANCE, ACCENT, ETATS
    code := TslVersHexa(palette.t, palette.s, palette.l)
    switch palette.cible {
        case "ambiance": AMBIANCE := code
        case "accent":   ACCENT := code
        default:
            trois := [C_VERT, C_AMBRE, C_ROUGE]
            trois[palette.cible = "actif" ? 1 : palette.cible = "pause" ? 2 : 3] := code
            ETATS := trois[1] "," trois[2] "," trois[3]
    }
    PaletteDessiner()
    attente := 80 - (A_TickCount - derniereTeinte)
    if (attente <= 0)
        AppliquerCouleurs()
    else
        SetTimer(AppliquerCouleurs, -attente)
}

PaletteDessiner() {
    code := TslVersHexa(palette.t, palette.s, palette.l)
    arcEnCiel := []
    loop 7
        arcEnCiel.Push(TslVersHexa((A_Index - 1) * 60, 1, 0.5))
    DessinerCurseur(pCurseurs[1], arcEnCiel, palette.t / 360, TslVersHexa(palette.t, 1, 0.5))
    DessinerCurseur(pCurseurs[2], [TslVersHexa(palette.t, 0, palette.l), TslVersHexa(palette.t, 1, palette.l)], palette.s, code)
    DessinerCurseur(pCurseurs[3], ["000000", TslVersHexa(palette.t, palette.s, 0.5), "FFFFFF"], palette.l, code)
    Maj(pCode, "#" code)
}

DessinerCurseur(ctrl, couleurs, valeur, couleurBouton) {
    ; une bande en dégradé, avec un bouton rond à la position de la valeur (de 0 à 1)
    ControlGetPos(,, &l, &h, ctrl)
    t := Toile(l, h)
    t.Effacer(Argb(C_FOND))
    marge := h / 2, bande := h * 0.32
    t.Gelule(marge - bande / 2, (h - bande) / 2, l - 2 * marge + bande, bande, couleurs, marge, l - marge)
    d := h * 0.72
    x := marge + valeur * (l - 2 * marge) - d / 2, y := (h - d) / 2
    t.Disque(x - 1, y - 1, d + 2, Argb("000000", 0x55))   ; fin contour, visible sur les couleurs claires
    t.Disque(x, y, d, Argb("FFFFFF"))
    t.Disque(x + d * 0.2, y + d * 0.2, d * 0.6, Argb(couleurBouton))
    t.Poser(ctrl)
}

PaletteCode(*) {
    ; taper le code d'une couleur (6 caractères, comme 9DC2E5)
    global silence
    avant := WinExist("A")
    silence := A_TickCount + 600000
    coul.Opt("+OwnDialogs")
    WinGetPos(&cX, &cY,,, coul)
    reponse := InputBox("Code de la couleur, en 6 caractères (par exemple 9DC2E5) :", "Turbo X · couleur"
        , "w340 h130 x" cX " y" cY, SubStr(pCode.Value, 2))
    silence := A_TickCount + 1000
    SetTimer(() => RendreLaMain(avant), -150)
    code := StrUpper(StrReplace(Trim(reponse.Value), "#"))
    if (reponse.Result != "OK" || !EstCode(code))
        return
    tsl := HexaVersTsl(code)
    palette.t := tsl.t, palette.s := tsl.s, palette.l := tsl.l
    PaletteChanger()
    AppliquerCouleurs()
}

AppliquerCouleurs(*) {
    ; repeint les fenêtres avec les couleurs choisies. Seul ce qui a changé est redessiné :
    ; pendant qu'on fait glisser un curseur de la palette, rien d'autre ne bouge.
    global derniereTeinte
    static fondAvant := ""
    derniereTeinte := A_TickCount
    CalculerCouleurs()
    nouveauFond := C_FOND != fondAvant
    fondAvant := C_FOND
    if nouveauFond
        for fenetre in [pan, notif, asst, coul, visite]
            fenetre.BackColor := C_FOND
    for e in teintes
        Repeindre(e)
    ; ce qui change de couleur selon l'état ou la souris
    PeindreEtat()
    Peindre(txChiaki, CouleurChiaki())
    Peindre(txPS5, CouleurPs5())
    AllumerVoyant(false)
    for fenetre in [asst, coul, visite]
        DwmBordure(fenetre, C_LIGNE)
    for i, p in pastilles
        DessinerPastille(p, i = pastilleSurvol)
    if (palette.cible != "" && nouveauFond)   ; le fond des curseurs
        PaletteDessiner()
    CouleursNoms()
    Survol()
    if visiteVisible
        VisiteMaj()
    if nouveauFond
        for fenetre in [pan, notif, asst, coul, visite]
            DllCall("RedrawWindow", "Ptr", fenetre.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x85)   ; tout redessiner, avec le nouveau fond
}

; ─────────────────────────────── CALCUL DES COULEURS ───────────────────────────────
CalculerCouleurs() {
    ; toutes les couleurs, d'après l'ambiance, l'accent et les états choisis
    global C_FOND, C_SURFACE, C_SURVOL, C_LIGNE, C_TEXTE, C_DOUX, C_SOMBRE
    global C_ACCENT, C_SUR_ACCENT, C_ACCENT_SURVOL, C_VERT, C_AMBRE, C_ROUGE
    a := TonsAmbiance(AMBIANCE)
    C_FOND := a.fond, C_TEXTE := a.texte, C_SURFACE := a.surface, C_SURVOL := a.survol
    C_LIGNE := a.ligne, C_DOUX := a.doux, C_SOMBRE := a.sombre

    ; un accent proposé est ajusté pour rester lisible ; un accent sur mesure est pris tel quel
    C_ACCENT := (choisi := Choix(ACCENTS, ACCENT)) ? CouleurAccent(choisi) : ACCENT
    C_SUR_ACCENT := Contraste(C_ACCENT, C_FOND) >= Contraste(C_ACCENT, "FFFFFF") ? C_FOND : "FFFFFF"
    C_ACCENT_SURVOL := Melange(C_ACCENT, "FFFFFF", Luminance(C_ACCENT) > 0.5 ? 0.5 : 0.2)

    ; de même pour les états
    if (jeu := Choix(JEUX_ETATS, ETATS))
        trois := [Lisible(jeu.actif, C_FOND), Lisible(jeu.pause, C_FOND), Lisible(jeu.arret, C_FOND)]
    else
        trois := StrSplit(ETATS, ",")
    C_VERT := trois[1], C_AMBRE := trois[2], C_ROUGE := trois[3]
}

TonsAmbiance(valeur) {
    ; tous les tons d'une ambiance ; un code couleur donne une ambiance sur mesure, avec ce fond
    a := Choix(AMBIANCES, valeur)
    if !a {
        clair := Contraste(valeur, "000000") > Contraste(valeur, "FFFFFF")
        a := {fond: valeur, texte: Melange(clair ? "1C1B19" : "F2F0EC", valeur, 0.08)}
    }
    tons := {fond: a.fond, texte: a.texte}
    for nom, part in Map("surface", 0.06, "survol", 0.12, "ligne", 0.11, "doux", 0.64, "sombre", 0.4)
        tons.%nom% := a.HasOwnProp(nom) ? a.%nom% : Melange(a.fond, a.texte, part)
    return tons
}

Choix(liste, id) {
    ; le choix de la liste qui porte ce nom (« » s'il n'y en a pas)
    for item in liste
        if (item.id = id)
            return item
    return ""
}

CouleurValide(valeur, liste) {
    ; un nom de la liste, un code couleur (« 1B2430 ») ou, pour les états, trois codes ; sinon « »
    valeur := StrUpper(StrReplace(StrReplace(Trim(valeur), "#"), " "))
    if Choix(liste, valeur)
        return StrLower(valeur)
    codes := StrSplit(valeur, ",")
    if (codes.Length != (liste = JEUX_ETATS ? 3 : 1))
        return ""
    for code in codes
        if !EstCode(code)
            return ""
    return valeur
}

CouleurDepart(cle, liste) => CouleurValide(ORIGINE[cle], liste) || liste[1].id

EstCode(texte) => RegExMatch(texte, "^[0-9A-Fa-f]{6}$")

Argb(hexa, alpha := 0xFF) => (alpha << 24) | Integer("0x" hexa)

Rvb(hexa) {
    n := Integer("0x" hexa)
    return [(n >> 16) & 0xFF, (n >> 8) & 0xFF, n & 0xFF]
}

Hexa(r, v, b) => Format("{:02X}{:02X}{:02X}", Octet(r), Octet(v), Octet(b))

Octet(x) => Max(0, Min(255, Round(x)))

Melange(a, b, part) {
    ; la couleur entre a (part = 0) et b (part = 1)
    ca := Rvb(a), cb := Rvb(b)
    return Hexa(ca[1] + (cb[1] - ca[1]) * part, ca[2] + (cb[2] - ca[2]) * part, ca[3] + (cb[3] - ca[3]) * part)
}

Luminance(hexa) {
    ; clarté perçue d'une couleur, de 0 (noir) à 1 (blanc), comme dans les règles d'accessibilité du Web
    l := 0
    for i, c in Rvb(hexa) {
        c /= 255
        l += [0.2126, 0.7152, 0.0722][i] * (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4)
    }
    return l
}

Contraste(a, b) {
    ; de 1 (aucun contraste) à 21 (noir sur blanc) ; un texte se lit bien à partir de 4,5
    la := Luminance(a), lb := Luminance(b)
    return (Max(la, lb) + 0.05) / (Min(la, lb) + 0.05)
}

Lisible(couleur, fond, mini := 4.5) {
    ; éclaircit (ou fonce) la couleur juste assez pour qu'elle se lise bien sur ce fond
    vers := Contraste(fond, "FFFFFF") > Contraste(fond, "000000") ? "FFFFFF" : "000000"
    resultat := couleur
    loop 20 {
        if (Contraste(resultat, fond) >= mini)
            break
        resultat := Melange(couleur, vers, A_Index * 0.05)
    }
    return resultat
}

TslVersHexa(t, s, l) {
    ; teinte (0 à 360), intensité et lumière (0 à 1) → code couleur
    c := (1 - Abs(2 * l - 1)) * s
    x := c * (1 - Abs(Mod(t / 60, 2) - 1))
    m := l - c / 2
    switch Floor(Mod(t, 360) / 60) {
        case 0:  r := c, v := x, b := 0
        case 1:  r := x, v := c, b := 0
        case 2:  r := 0, v := c, b := x
        case 3:  r := 0, v := x, b := c
        case 4:  r := x, v := 0, b := c
        default: r := c, v := 0, b := x
    }
    return Hexa((r + m) * 255, (v + m) * 255, (b + m) * 255)
}

HexaVersTsl(hexa) {
    ; code couleur → teinte (0 à 360), intensité et lumière (0 à 1)
    c := Rvb(hexa)
    r := c[1] / 255, v := c[2] / 255, b := c[3] / 255
    maxi := Max(r, v, b), mini := Min(r, v, b), d := maxi - mini
    l := (maxi + mini) / 2
    if (d = 0)
        return {t: 0, s: 0, l: l}
    s := d / (1 - Abs(2 * l - 1))
    if (maxi = r)
        t := 60 * Mod((v - b) / d + 6, 6)
    else if (maxi = v)
        t := 60 * ((b - r) / d + 2)
    else
        t := 60 * ((r - v) / d + 4)
    return {t: t, s: Min(1, s), l: l}
}

; ─────────────────────────────── VISITE GUIDÉE ───────────────────────────────
VisiteOuvrir(auLancement := false) {
    ; la visite depuis le début ; l'assistant se range le temps de la visite
    global visiteVisible, vEtapes, vAssistant
    vEtapes := []
    for e in ETAPES_VISITE
        if (!e.HasOwnProp("ecrans") || MonitorGetCount() >= e.ecrans)
            vEtapes.Push(e)
    vAssistant := auLancement || asstVisible   ; à la fin, l'assistant revient
    if asstVisible
        AssistantMasquer()
    visiteVisible := true
    VisiteEtape(1)
}

VisiteEtape(n) {
    ; affiche l'étape n : le texte prend la hauteur qu'il lui faut, puis la tâche et les boutons
    global vEtape, vDepart, vFait, vVuMasque
    vEtape := n, vFait := false, vVuMasque := false
    vDepart := {cadence: CADENCE_MS, coin: COIN, ecran: ECRAN}
    e := vEtapes[n], total := vEtapes.Length
    Maj(vEtiquette, "VISITE GUIDÉE  ·  " n " SUR " total)
    Maj(vTitre, e.titre)
    Maj(vTexte, e.texte)
    vTexte.GetPos(, &y)
    h := HauteurTexte(vTexte, e.texte)
    vTexte.Move(,,, h)
    y += h
    tache := e.HasOwnProp("tache")
    Montrer(vTacheIcone, tache), Montrer(vTache, tache)
    if tache {
        vTacheIcone.Move(, y + 12), vTache.Move(, y + 12)
        VisiteTache(e, false)
        y += 12 + 30
    }
    Maj(vBouton1, n = 1 ? "Commencer la visite" : n = total ? "Terminer" : "Suivant")
    Maj(vBouton2, n = 1 ? "Passer" : "Retour")
    vBouton1.Move(, y + 18), vBouton2.Move(, y + 18)
    plein := Round(vJaugeL * n / total)
    vJauge.Move(vJaugeX, y + 18 + 34 + 18, plein)
    vPiste.Move(vJaugeX + plein, y + 18 + 34 + 18, vJaugeL - plein)
    premiere := !DllCall("IsWindowVisible", "Ptr", visite.Hwnd)
    visite.Show("AutoSize " (premiere ? "Hide" : "NoActivate"))
    VisiteMaj()
    if premiere
        visite.Show("NoActivate")
}

VisiteBouton(n) {
    ; bouton 1 : commencer, suivant ou terminer ; bouton 2 : passer ou retour
    suivante := n = 1 ? vEtape + 1 : vEtape - 1
    if (suivante >= 1 && suivante <= vEtapes.Length)
        VisiteEtape(suivante)
    else
        VisiteFermer()
}

VisiteFermer() {
    ; fin de la visite (ou visite passée) : elle ne s'ouvrira plus toute seule
    global visiteVisible
    visiteVisible := false
    visite.Hide()
    CadreCacher()
    Noter("visite_vue", 1)
    if vAssistant
        AssistantAfficher()
}

VisiteMaj() {
    ; coche la tâche de l'étape dès qu'elle est faite, puis replace la bulle et le cadre
    global vFait
    e := vEtapes[vEtape]
    if e.HasOwnProp("tache") {
        vFait := vFait || VisiteTacheFaite(e.tache)
        VisiteTache(e, vFait)
    }
    VisitePlacer(e)
    VisiteCadre(e)
}

VisiteTache(e, fait) {
    ; la tâche de l'étape : un rond ambre tant qu'elle reste à faire, une coche verte ensuite
    Maj(vTacheIcone, fait ? I_VALIDE : I_ENCOURS)
    Peindre(vTacheIcone, fait ? C_VERT : C_AMBRE)
    Maj(vTache, fait ? VisiteBravo(e.tache) : e.consigne)
    Peindre(vTache, fait ? C_VERT : C_TEXTE)
}

VisiteTacheFaite(tache) {
    global vVuMasque
    switch tache {
        case "cadence": return CADENCE_MS != vDepart.cadence
        case "coin":    return COIN != vDepart.coin
        case "ecran":   return ECRAN != vDepart.ecran
        case "couleurs": return coulVisible
        default:                       ; « masquer » : masqué, puis revenu
            vVuMasque := vVuMasque || !visible
            return vVuMasque && visible
    }
}

VisiteBravo(tache) {
    switch tache {
        case "cadence":
            n := ParSeconde(CADENCE_MS)
            return "Bravo : " n (n = "1" ? " appui" : " appuis") " par seconde"
        case "coin":     return "Bravo ! F6 encore pour un autre coin"
        case "ecran":    return "Bravo ! F5 encore pour l'écran suivant"
        case "couleurs": return "Bravo ! Essaie une pastille"
        default:         return "Bravo, le panneau est revenu"
    }
}

VisitePlacer(e) {
    ; à côté du panneau (et de la fenêtre des couleurs), à la hauteur de ce que montre l'étape ;
    ; sans rien à montrer, au milieu de l'écran du jeu
    WinGetPos(&vX, &vY, &vL, &vH, visite)
    if (e.cible = "") {
        try
            MonitorGetWorkArea(EcranJeu(), &zG, &zH, &zD, &zB)
        catch
            MonitorGetWorkArea(, &zG, &zH, &zD, &zB)
        x := zG + (zD - zG - vL) // 2, y := zH + (zB - zH - vH) // 2
    } else {
        WinGetPos(&pX, &pY, &pL, &pH, pan)
        gauche := pX, droite := pX + pL
        if coulVisible {
            WinGetPos(&cX,, &cL,, coul)
            gauche := Min(gauche, cX), droite := Max(droite, cX + cL)
        }
        ZoneEcran(&zG, &zH, &zD, &zB)
        ecart := Round(16 * A_ScreenDPI / 96)
        x := (COIN = 2 || COIN = 3) ? gauche - vL - ecart : droite + ecart
        z := VisiteZone(e.cible)
        y := z ? z.y + (z.h - vH) // 2 : vY
        y := Max(zH + ecart, Min(y, zB - vH - ecart))
    }
    if (x != vX || y != vY)
        WinMove(x, y,,, visite)
}

VisiteZone(nom) {
    ; la zone de l'écran que montre l'étape, en pixels (« » si elle n'est pas visible)
    if !visible
        return ""
    switch nom {
        case "panneau":
            WinGetPos(&x, &y, &l, &h, pan)
            return {x: x, y: y, l: l, h: h, rayon: 8}
        case "menu":
            a := RectEcran(btCouleurs), b := RectEcran(btMenu)
            return {x: a.x, y: a.y, l: b.d - a.x, h: b.b - a.y, rayon: 4}
        default:                       ; des lignes du panneau, sur toute la largeur de son contenu
            haut := RectEcran(nom = "etat" ? icEtat : txCadence)
            bas := RectEcran(nom = "etat" ? txAide : txCadence)
            bord := RectEcran(sep1)
            return {x: bord.x, y: haut.y, l: bord.d - bord.x, h: bas.b - haut.y, rayon: 6}
    }
}

VisiteCadre(e) {
    ; le cadre lumineux entoure ce que montre l'étape : il apparaît en fondu, puis glisse en douceur
    ; d'une zone à l'autre. Il n'est redessiné que si la zone ou la couleur d'accent a changé.
    global cadreZone, cadreAnim
    z := e.cible != "" ? VisiteZone(e.cible) : ""
    cle := z ? z.x " " z.y " " z.l " " z.h " " C_ACCENT : ""
    if (cle = cadreZone)
        return
    cadreZone := cle
    if !z
        return CadreCacher()
    if (cadreActuel = "") {
        cadreAnim := {de: z, vers: z, debut: A_TickCount, fondu: true}
        cadre.Show("NoActivate")
    } else if (cadreActuel.x = z.x && cadreActuel.y = z.y && cadreActuel.l = z.l && cadreActuel.h = z.h) {
        return DessinerCadre(z)        ; même place : seule la couleur a changé
    } else
        cadreAnim := {de: cadreActuel, vers: z, debut: A_TickCount, fondu: false}
    CadreAnimer()
    SetTimer(CadreAnimer, 15)
}

CadreAnimer() {
    ; une image de l'animation du cadre : elle dure 0,22 s et ralentit en arrivant
    avance := Min(1, (A_TickCount - cadreAnim.debut) / 220)
    doux := 1 - (1 - avance) ** 3
    z := {}
    for cle in ["x", "y", "l", "h", "rayon"]
        z.%cle% := cadreAnim.de.%cle% + (cadreAnim.vers.%cle% - cadreAnim.de.%cle%) * doux
    DessinerCadre(z, cadreAnim.fondu ? doux : 1)
    if (avance >= 1)
        SetTimer(CadreAnimer, 0)
}

CadreCacher() {
    global cadreZone, cadreActuel
    SetTimer(CadreAnimer, 0)
    cadre.Hide()
    cadreZone := "", cadreActuel := ""
}

DessinerCadre(z, opacite := 1) {
    ; un trait aux coins arrondis, avec un halo doux, un peu à l'écart de la zone
    global cadreActuel
    cadreActuel := z
    k := A_ScreenDPI / 96
    halo := Round(10 * k), bord := halo + Round(6 * k)
    l := Round(z.l) + 2 * bord, h := Round(z.h) + 2 * bord
    t := Toile(l, h)
    t.Effacer(0)
    rayon := (z.rayon + 6) * k
    for trait in [[9, 0x12], [6, 0x24], [3.5, 0x40]]
        t.Contour(halo, halo, l - 2 * halo, h - 2 * halo, rayon, trait[1] * k, Argb(C_ACCENT, trait[2]))
    t.Contour(halo, halo, l - 2 * halo, h - 2 * halo, rayon, 2 * k, Argb(C_ACCENT))
    t.Calque(cadre, Round(z.x) - bord, Round(z.y) - bord, Round(255 * opacite))
}

; ─────────────────────────────── DESSIN ───────────────────────────────
; Les pastilles, les curseurs de la palette et le cadre de la visite sont dessinés avec GDI+,
; la bibliothèque de dessin de Windows, pour avoir des bords bien lisses.
class Toile {
    __New(l, h) {
        ; une image vide de l × h pixels, où l'on dessine
        this.l := l, this.h := h, bmp := 0, g := 0
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", l, "Int", h, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &bmp)
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", bmp, "Ptr*", &g)
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)   ; bords lissés
        this.bmp := bmp, this.g := g
    }

    __Delete() {
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", this.g)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", this.bmp)
    }

    Effacer(argb) => DllCall("gdiplus\GdipGraphicsClear", "Ptr", this.g, "UInt", argb)

    Disque(x, y, d, argb) {
        pinceau := Toile.Pinceau(argb)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", this.g, "Ptr", pinceau, "Float", x, "Float", y, "Float", d, "Float", d)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pinceau)
    }

    Part(x, y, d, debut, angle, argb) {
        ; une part de disque, comme une part de tarte (angles en degrés, 0 = à droite)
        pinceau := Toile.Pinceau(argb)
        DllCall("gdiplus\GdipFillPie", "Ptr", this.g, "Ptr", pinceau, "Float", x, "Float", y, "Float", d, "Float", d
            , "Float", debut, "Float", angle)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pinceau)
    }

    Cercle(x, y, d, epaisseur, argb) {
        stylo := 0
        DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", epaisseur, "Int", 2, "Ptr*", &stylo)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", this.g, "Ptr", stylo, "Float", x, "Float", y, "Float", d, "Float", d)
        DllCall("gdiplus\GdipDeletePen", "Ptr", stylo)
    }

    Gelule(x, y, l, h, couleurs, debut, fin) {
        ; une bande aux bouts arrondis, en dégradé à travers les couleurs, de debut à fin (en x)
        chemin := 0, pinceau := 0
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &chemin)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", chemin, "Float", x, "Float", y, "Float", h, "Float", h, "Float", 90, "Float", 180)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", chemin, "Float", x + l - h, "Float", y, "Float", h, "Float", h, "Float", 270, "Float", 180)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", chemin)
        p1 := Buffer(8), p2 := Buffer(8)
        NumPut("Float", debut, "Float", y, p1)
        NumPut("Float", fin, "Float", y, p2)
        DllCall("gdiplus\GdipCreateLineBrush", "Ptr", p1, "Ptr", p2, "UInt", Argb(couleurs[1]), "UInt", Argb(couleurs[couleurs.Length])
            , "Int", 3, "Ptr*", &pinceau)
        n := couleurs.Length, teintesBande := Buffer(4 * n), positions := Buffer(4 * n)
        for i, c in couleurs
            NumPut("UInt", Argb(c), teintesBande, 4 * (i - 1)), NumPut("Float", (i - 1) / (n - 1), positions, 4 * (i - 1))
        DllCall("gdiplus\GdipSetLinePresetBlend", "Ptr", pinceau, "Ptr", teintesBande, "Ptr", positions, "Int", n)
        DllCall("gdiplus\GdipFillPath", "Ptr", this.g, "Ptr", pinceau, "Ptr", chemin)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pinceau)
        DllCall("gdiplus\GdipDeletePath", "Ptr", chemin)
    }

    Contour(x, y, l, h, rayon, epaisseur, argb) {
        ; le trait d'un rectangle aux coins arrondis
        d := 2 * rayon, chemin := 0, stylo := 0
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &chemin)
        for coin in [[x, y, 180], [x + l - d, y, 270], [x + l - d, y + h - d, 0], [x, y + h - d, 90]]
            DllCall("gdiplus\GdipAddPathArc", "Ptr", chemin, "Float", coin[1], "Float", coin[2], "Float", d, "Float", d
                , "Float", coin[3], "Float", 90)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", chemin)
        DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", epaisseur, "Int", 2, "Ptr*", &stylo)
        DllCall("gdiplus\GdipDrawPath", "Ptr", this.g, "Ptr", stylo, "Ptr", chemin)
        DllCall("gdiplus\GdipDeletePen", "Ptr", stylo)
        DllCall("gdiplus\GdipDeletePath", "Ptr", chemin)
    }

    Poser(ctrl) {
        ; met le dessin dans un contrôle Picture (qui s'occupe ensuite de libérer l'image)
        hbm := 0
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", this.bmp, "Ptr*", &hbm, "UInt", 0xFF000000)
        ctrl.Value := "HBITMAP:" hbm
    }

    Calque(fenetre, x, y, opacite := 255) {
        ; affiche le dessin, avec sa transparence, dans une fenêtre « calque » placée en (x, y) ;
        ; opacite : de 0 (invisible) à 255 (tout à fait visible)
        hbm := 0
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", this.bmp, "Ptr*", &hbm, "UInt", 0)
        hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
        ancien := DllCall("SelectObject", "Ptr", hdc, "Ptr", hbm, "Ptr")
        pos := Buffer(8), taille := Buffer(8), origine := Buffer(8, 0)
        NumPut("Int", x, "Int", y, pos)
        NumPut("Int", this.l, "Int", this.h, taille)
        DllCall("UpdateLayeredWindow", "Ptr", fenetre.Hwnd, "Ptr", 0, "Ptr", pos, "Ptr", taille, "Ptr", hdc
            , "Ptr", origine, "UInt", 0, "UInt*", 0x01000000 | (opacite << 16), "UInt", 2)   ; transparence de chaque point
        DllCall("SelectObject", "Ptr", hdc, "Ptr", ancien)
        DllCall("DeleteDC", "Ptr", hdc)
        DllCall("DeleteObject", "Ptr", hbm)
    }

    static Pinceau(argb) {
        pinceau := 0
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", &pinceau)
        return pinceau
    }
}

RectEcran(ctrl) {
    ; position d'un élément sur l'écran, en pixels : gauche, haut, droite, bas
    r := Buffer(16)
    DllCall("GetWindowRect", "Ptr", ctrl.Hwnd, "Ptr", r)
    return {x: NumGet(r, 0, "Int"), y: NumGet(r, 4, "Int"), d: NumGet(r, 8, "Int"), b: NumGet(r, 12, "Int")}
}

HauteurTexte(ctrl, texte) {
    ; hauteur qu'il faut à un texte de plusieurs lignes, dans la largeur de son élément
    ctrl.GetPos(,, &l)
    hdc := DllCall("GetDC", "Ptr", ctrl.Hwnd, "Ptr")
    ancienne := DllCall("SelectObject", "Ptr", hdc, "Ptr", SendMessage(0x31, 0, 0, ctrl), "Ptr")   ; sa police
    r := Buffer(16, 0)
    NumPut("Int", Round(l * A_ScreenDPI / 96), r, 8)
    DllCall("DrawText", "Ptr", hdc, "Str", texte, "Int", -1, "Ptr", r, "UInt", 0x410)   ; mesurer, avec retours à la ligne
    DllCall("SelectObject", "Ptr", hdc, "Ptr", ancienne)
    DllCall("ReleaseDC", "Ptr", ctrl.Hwnd, "Ptr", hdc)
    return Ceil(NumGet(r, 12, "Int") * 96 / A_ScreenDPI)
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
    ; numéro du programme chiaki-ng s'il est ouvert, sinon 0. Chercher parmi tous les programmes
    ; de Windows prend quelques millisecondes : la réponse sert 0,2 s (0,75 s s'il est fermé).
    static pid := 0, quand := -1000
    if (A_TickCount - quand < (pid ? 200 : 750))
        return pid
    quand := A_TickCount
    for nom in [nomChiaki, "chiaki.exe", "chiaki-ng.exe"]
        if (nom != "" && (pid := ProcessExist(nom)))
            return pid
    return pid := 0
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

SouvenirCouleur(cle, liste) {
    ; comme Souvenir, pour une couleur : un nom de la liste ou un code couleur
    try {
        if (IniRead(MEMOIRE, "memoire", cle "_origine") = ORIGINE[cle])
            if ((valeur := CouleurValide(IniRead(MEMOIRE, "memoire", cle), liste)) != "")
                return valeur
    }
    return CouleurDepart(cle, liste)
}

Retenir() {
    for cle, valeur in Map("cadence", CADENCE_MS, "coin", COIN, "ecran", ECRAN, "sons", SONS
                         , "ambiance", AMBIANCE, "accent", ACCENT, "etats", ETATS) {
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
    ; bordure de la couleur choisie (Windows 11), changée seulement si elle est différente
    static bordures := Map()
    if (bordures.Get(fenetre.Hwnd, "") = couleur)
        return
    bordures[fenetre.Hwnd] := couleur
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", fenetre.Hwnd, "UInt", 34, "UInt*", BGR(couleur), "UInt", 4)
}

BGR(hex) {
    n := Integer("0x" hex)
    return ((n & 0xFF) << 16) | (n & 0xFF00) | ((n >> 16) & 0xFF)
}
