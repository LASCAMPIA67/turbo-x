# Journal des modifications

Toutes les modifications notables de Turbo X sont consignées ici.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), et le projet respecte le [versionnage sémantique](https://semver.org/lang/fr/).

## [Non publié]

## [0.2.0] - 2026-11-07

### Ajouté

- Assistant de démarrage : 7 étapes qui se cochent toutes seules (chiaki-ng installé, PS5 jumelée, allumée, chiaki-ng ouvert, connecté, au premier plan, Turbo X démarré), avec la marche à suivre et des boutons pour chaque étape. Touche <kbd>F1</kbd>.
- Ouverture automatique de chiaki-ng au lancement, et connexion directe à la PS5 quand elle est allumée.
- Recherche de la PS5 sur le réseau local, par chacune des connexions du PC (fonctionne même avec un VPN actif).
- Sécurité renforcée : Turbo X n'appuie que si chiaki-ng est aussi connecté à la PS5 (réglage `VERIF_PS5`).
- Notifications quand Turbo X se met en pause ou reprend tout seul, avec la raison.
- Plusieurs écrans : le panneau et l'assistant suivent l'écran du jeu ; touche <kbd>F5</kbd> pour choisir l'écran du panneau.
- Menu directement sur le panneau (bouton ☰ et clic droit), avec les options « Sons » et « Remettre les réglages d'origine ».
- Mémoire des réglages d'une fois sur l'autre : cadence, coin, écran et sons.
- Une seule copie à la fois : les autres copies de Turbo X (et de Spam X) se ferment toutes seules.
- Ligne « PS5 » dans le panneau.
- Fabrication et publication automatiques de `TurboX.exe` par GitHub, avec attestation de provenance.

### Modifié

- Nouveau nom : **Turbo X** (anciennement « Spam X »). Les réglages déjà retenus sont repris automatiquement.
- Nouvelle apparence : graphite chaud et ivoire, couleurs réservées à l'état (vert, ambre, rouge), polices de Windows 11.
- Le badge du panneau affiche le numéro de version.

### Supprimé

- La phrase « Appuis automatiques sur X · chiaki-ng » du panneau.

### Corrigé

- La phrase sous l'état, les libellés et les légendes des touches ne s'affichent plus en gras par erreur.

## 0.1.0 - 2026-10-10

Première version, sous le nom « Spam X », jamais publiée : appuis automatiques sur Entrée dans chiaki-ng, panneau toujours visible, notifications, sons, raccourcis <kbd>F6</kbd> à <kbd>F10</kbd> et <kbd>Ctrl</kbd> + <kbd>F8</kbd>.

[Non publié]: https://github.com/LASCAMPIA67/turbo-x/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/LASCAMPIA67/turbo-x/releases/tag/v0.2.0
