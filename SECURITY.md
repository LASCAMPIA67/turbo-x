# Sécurité

## Versions suivies

Seule la dernière version publiée reçoit des corrections de sécurité.

| Version | Corrections de sécurité |
| --- | --- |
| 0.2.x | oui |
| 0.1.x et avant | non |

## Signaler une faille

**N'ouvre pas de ticket public.** Utilise le signalement privé de GitHub : onglet **Security**, puis **Report a vulnerability**, ou directement [ce formulaire](https://github.com/LASCAMPIA67/turbo-x/security/advisories/new).

Décris le problème, comment le reproduire et son effet possible. Tu recevras une réponse dans les 7 jours. Une fois la faille corrigée et publiée, elle sera décrite publiquement, avec tes remerciements si tu le souhaites.

## Ce que fait Turbo X

Pour évaluer les risques, voici exactement ce que fait le programme :

- **Clavier :** il envoie la touche réglée (Entrée par défaut) uniquement quand la fenêtre au premier plan est chiaki-ng et que chiaki-ng est connecté à la PS5. La touche est toujours relâchée à la fermeture.
- **Réseau local :** pour trouver la PS5, il envoie la même question que chiaki-ng (protocole de découverte de la Lecture à distance, port UDP 9302) sur chacune des connexions du PC, et lit les réponses. Il lit aussi la liste des connexions de Windows pour savoir si chiaki-ng est connecté à la PS5 (port 9295).
- **Registre de Windows :** il lit, sans jamais les modifier, le nom des consoles jumelées et le profil actif dans les réglages de chiaki-ng. Il ne lit jamais les clés d'association ni les informations de compte.
- **Fichiers :** il écrit ses propres réglages dans `%APPDATA%\Turbo X\memoire.ini`, et rien d'autre.
- **Internet :** aucune donnée n'est envoyée. Le bouton « Télécharger chiaki-ng » de l'assistant ouvre simplement la page de téléchargement de chiaki-ng dans ton navigateur.

## Fichiers publiés

Chaque version est fabriquée par GitHub Actions à partir du code de ce dépôt, avec des outils officiels figés et vérifiés par empreinte (`outils/versions.psd1`). Chaque fichier publié est accompagné d'une attestation de provenance :

```shell
gh attestation verify TurboX.exe --repo LASCAMPIA67/turbo-x
```
