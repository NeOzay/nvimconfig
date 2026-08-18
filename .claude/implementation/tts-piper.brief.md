---
slug: tts-piper
titre: TTS Piper avec démon côté client, pilotable depuis Neovim
statut: validé
execution: direct
créé: 2026-08-18
---

## Intention

**Symptôme** : « Je veux étudier la faisabilité d'utiliser un TTS en SSH » — la config Neovim
tourne sur un VPS sans aucune sortie audio, et `tts.nvim` joue le son côté serveur via `ffplay`.
**But** : faire lire du texte par Piper sur le poste Bazzite, que Neovim tourne en local ou sur
le VPS via SSH, avec la même config Neovim des deux côtés.

## Critères de réussite

- « juste tester la logique métier et la communication SSH localement sur un port différent » :
  des tests automatisés couvrent la logique du fork et le protocole d'échange, joués en
  loopback sur un port distinct de celui de production (dit)
- la lecture audio elle-même n'est pas testée automatiquement — validation à l'oreille (dit)
- `make test` passe (dépôt: Makefile, tests/minimal_init.lua)

## Hors-périmètre

- Piper ne tourne pas sur le VPS : « il n'est pas raisonnable de le faire tourner sur le VPS » (dit)
- les backends `edge` et `openai` sont supprimés du fork (dit)
- aucune persistance des réglages sur disque (dit)
- pas de compatibilité merge avec l'upstream : divergence « totalement assumée » (dit)

## Signaux de dérive

- si `lua/plugins/tts.lua` doit détecter le contexte ou brancher sur `$SSH_CONNECTION`,
  l'idée du « 127.0.0.1 partout » est ratée (dit)
- si une dépendance audio (ffmpeg, ffplay, piper, onnxruntime) réapparaît côté VPS (dit)
- si une couche « transport pluggable » apparaît : il y a un seul transport, une socket TCP
  loopback (dit)
- si le démon déborde du TTS vers un service générique — risque de sécurité sur un port
  forwardé (dit)

## Contraintes connues de l'utilisateur

- **Backend** : Piper uniquement, mais la table d'enregistrement de backends de l'upstream est
  conservée (dit)
- **Une seule config** : « j'utilise la même config Nvim partout » — le relais doit exister et
  fonctionner sur les deux machines (dit)
- **Démon** : « le script démon local est placé dans le plugin et documenté comment le
  configurer », lancé par **systemd user** sur Bazzite — pas de spawn automatique par Neovim (dit)
- **Fork** : « on va forker le plugin pour avoir un contrôle total » ; le plugin sert de base,
  pas de socle à garder synchronisé (dit)
- **Pilotage runtime** : voix/modèle Piper, vitesse, volume et cible du démon (hôte/port)
  modifiables depuis Neovim, **pour la session courante seulement** (dit)
- **Sans SSH** : le cas « pas de connexion SSH » doit être géré (dit)
- **Convention de fork** : submodule `git@github.com:NeOzay/<repo>.git` sous `plugins/<nom>/`,
  spec Lazy séparée dans `lua/plugins/<nom>.lua` avec `dir =` ; le SHA doit être poussé avant
  d'être référencé ici (dépôt: .gitmodules, lua/plugins/markview.lua, CLAUDE.md)
- **Client** : Bazzite (Fedora Atomic), PipeWire natif, `pw-play` disponible sans ffmpeg (dit)
- **Précédent UI** : picker Snacks déjà pratiqué dans le dépôt
  (dépôt: plugins/bookmarks/lua/bookmarks/snacks_picker.lua, docs/plugins/snacks-picker-custom.md)

## Incertitudes à lever en plan

- l'environnement Bazzite n'est pas vérifiable depuis le VPS : présence de `uv`, de `pw-play`,
  version de Python, emplacement des modèles Piper. La doc d'installation et l'unit systemd
  devront être écrites sans pouvoir être exécutées — à valider par l'utilisateur sur sa machine.
