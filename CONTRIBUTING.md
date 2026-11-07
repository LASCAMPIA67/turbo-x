# Contribuer à Turbo X

Merci de vouloir aider ! Ce guide explique comment signaler un problème, proposer une idée ou modifier le code.

## Signaler, proposer, demander

- **Un problème :** ouvre un ticket [« Signaler un problème »](https://github.com/LASCAMPIA67/turbo-x/issues/new?template=bug.yml).
- **Une idée :** ouvre un ticket [« Proposer une idée »](https://github.com/LASCAMPIA67/turbo-x/issues/new?template=idee.yml).
- **Une question :** passe par les [discussions](https://github.com/LASCAMPIA67/turbo-x/discussions).
- **Une faille de sécurité :** jamais en public, voir [SECURITY.md](SECURITY.md).

N'écris jamais d'information personnelle : adresse IP, nom de console, chemins de ton PC, identifiants…

## Préparer ton PC

- [AutoHotkey v2](https://www.autohotkey.com/), version 2.0.30 ou plus récente.
- [Git](https://git-scm.com/) et, si possible, [GitHub CLI](https://cli.github.com/).
- Un éditeur qui suit [EditorConfig](https://editorconfig.org/). Avec Visual Studio Code, les extensions conseillées sont proposées à l'ouverture du dossier, dont la prise en charge d'AutoHotkey v2. Le projet y coupe la mise en forme automatique (`.vscode/settings.json`) : elle défait les alignements du script.

## Règles du code

- AutoHotkey **v2** uniquement, avec la ligne `#Requires AutoHotkey v2.0`.
- Fichiers `.ahk`, `.ps1` et `.psd1` en **UTF-8 avec BOM** et fins de ligne **Windows (CRLF)**, sinon les accents s'affichent mal. Les autres fichiers : UTF-8 sans BOM, fins de ligne LF. `.editorconfig` et `.gitattributes` s'en chargent.
- Noms et commentaires **en français**, avec des phrases simples.
- Les **réglages restent en haut** de `src/TurboX.ahk`.
- Ne jamais casser la sécurité : rien n'est envoyé si chiaki-ng n'est pas au premier plan et connecté à la PS5, et la touche est toujours relâchée à la fermeture.
- Les fenêtres (panneau, notification, assistant, couleurs, visite) sont créées avec le style `FENETRE` : elles ne s'activent jamais (`+E0x08000000`), pour ne pas prendre le clavier à chiaki-ng, et sont dessinées en coulisse (`+E0x02000000`), pour ne pas scintiller. Pour changer une couleur ou un texte, passer par `Peindre`, `Fond` ou `Maj`, qui ne redessinent que si quelque chose change.
- Jamais de code couleur écrit en dur : toujours une couleur du thème (`C_FOND`, `C_TEXTE`, `C_ACCENT`…), calculée par `CalculerCouleurs` d'après les choix de la palette. Un élément de couleur fixe est créé avec `Teinter`, pour être repeint quand on change de couleurs. La couleur dit d'abord l'état : actif (`C_VERT`), en pause (`C_AMBRE`), arrêté (`C_ROUGE`).
- Un texte doit rester lisible : un contraste d'au moins 4,5 avec son fond (fonction `Contraste`), comme le demandent les règles d'accessibilité du Web (WCAG).
- L'icône est dessinée par `outils/icone.ps1`, qui écrit `src/TurboX.ico` et `docs/images/icone.png` : pour la changer, modifie ce script puis relance-le. Près de l'horloge, Turbo X l'entoure lui-même de la couleur de l'état (`IconeEtat`).

## Vérifier avant d'envoyer

Dans PowerShell, depuis le dossier du projet :

```powershell
.\outils\verifier.ps1    # script sans erreur, encodage, fins de ligne, version, icône à jour
.\outils\compiler.ps1    # fabrique dist\TurboX.exe
.\outils\icone.ps1       # redessine l'icône, après une modification de son dessin
```

Teste ensuite en vrai, avec chiaki-ng et une PS5.

Les mêmes vérifications tournent sur GitHub à chaque envoi, avec en plus [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) (scripts PowerShell), [markdownlint](https://github.com/DavidAnson/markdownlint-cli2) (documents) et [actionlint](https://github.com/rhysd/actionlint) (workflows).

## Messages de commit

Le projet suit [Conventional Commits](https://www.conventionalcommits.org/fr/v1.0.0/), avec une description en français :

| Type | Quand l'utiliser |
| --- | --- |
| `feat` | nouvelle fonction ou changement visible |
| `fix` | correction d'un problème |
| `docs` | documentation |
| `refactor` | code réorganisé, sans changement visible |
| `build` | outils de fabrication |
| `ci` | vérifications automatiques sur GitHub |
| `chore` | entretien |

Exemple : `feat: l'assistant s'ouvre sur l'écran du jeu`.

## Demandes de fusion

1. Crée une branche à partir de `main`.
2. Décris ton changement dans `CHANGELOG.md`, partie « Non publié ».
3. Ouvre la demande de fusion : le modèle te guide.
4. Les vérifications automatiques doivent être vertes. La fusion se fait en un seul commit (*squash*).

## Versions

Turbo X suit le [versionnage sémantique](https://semver.org/lang/fr/) : `MAJEUR.MINEUR.CORRECTIF`.

- **CORRECTIF** (0.2.1) : uniquement des corrections.
- **MINEUR** (0.3.0) : de nouvelles fonctions, sans rien casser.
- **MAJEUR** (2.0.0) : des changements qui obligent à changer ses habitudes (touches, réglages…).
- Tant que la version commence par **0.**, le projet est en construction. La **1.0.0** sera la première version complète.

Pour publier une version :

1. Mettre le nouveau numéro dans `src/TurboX.ahk`, à deux endroits : `VERSION` et `;@Ahk2Exe-SetVersion`.
2. Dans `CHANGELOG.md`, transformer « Non publié » en `[x.y.z] - AAAA-MM-JJ`, et mettre à jour les liens en bas du fichier.
3. Fusionner, puis créer et envoyer l'étiquette : `git tag -a vx.y.z -m "Turbo X x.y.z"`, puis `git push origin vx.y.z`.
4. GitHub vérifie tout, fabrique `TurboX.exe`, l'atteste et publie la version tout seul.

## Mettre à jour les outils

Les versions d'AutoHotkey et d'Ahk2Exe utilisées pour vérifier et fabriquer sont figées, avec leur empreinte SHA-256, dans `outils/versions.psd1`. Les actions GitHub sont figées par empreinte de commit, et Dependabot propose leurs mises à jour chaque semaine.
