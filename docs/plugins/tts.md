# tts.nvim

## Role
Lecture vocale d'une sélection par Piper, synthétisée sur la machine qui a une sortie audio —
pas forcément celle où tourne Neovim.

## Files
- Spec : `lua/plugins/tts.lua`
- Code : `plugins/tts.nvim/` (clone de `johannww/tts.nvim` sans son dépôt git, **suivi
  directement par ce dépôt** — pas de submodule, pas d'upstream à suivre)
- Démon : `plugins/tts.nvim/daemon/` (`tts-piperd.py`, `tts-piperd.service`, `README.md`)
- Tests : `tests/tts/test_protocol.lua`, `tests/tts/test_daemon_io.lua`,
  `tests/tts/test_selection.lua`

## Key Behaviors

**Neovim ne synthétise rien.** Il envoie une ligne JSON à `127.0.0.1:7788` et c'est tout. Le démon
Piper tourne sur le poste de travail (Bazzite, systemd `--user`) et pousse le PCM dans `pw-play`.

L'adresse est **inconditionnelle** : aucune détection de contexte, aucun branchement sur
`$SSH_CONNECTION`. En local le démon est sur place ; depuis un serveur distant, un
`RemoteForward 7788 127.0.0.1:7788` y mène. Sans tunnel, la connexion est refusée et le plugin le
signale par une notification — c'est un cas nominal, pas une erreur.

Une requête = une connexion, jamais de connexion maintenue : sinon une coupure du tunnel laisserait
un client persuadé d'être connecté.

**Le catalogue de voix vit chez le démon.** `:TTSVoice` interroge `{"op":"voices"}` plutôt que de
lire une table figée : Neovim ne peut pas savoir quels modèles sont téléchargés sur l'autre machine.

**Aucune persistance.** Les réglages valent pour la session ; ils retombent sur `opts` de la spec
au redémarrage.

Écarts assumés d'avec l'upstream : plus de backends `edge`/`openai`, plus de relais Python côté
Neovim (`plenary.Job` remplacé par `vim.uv`), plus de dépendance à `plenary` du tout (pandoc passe
par `vim.system`). La table `backends.backends` est conservée comme point d'enregistrement.

## Keymaps
Aucune. Le plugin se charge sur ses commandes (`cmd` dans la spec) — `<leader>tt` et `<leader>ts`
étant déjà pris, le choix d'un raccourci est laissé ouvert.

| Commande | Rôle |
|---|---|
| `:TTS` | Lire la sélection visuelle |
| `:TTSStop` | Interrompre la lecture |
| `:TTSFile` | Écrire la synthèse dans un fichier, **sur la machine du démon** |
| `:TTSConfig` | Picker des quatre réglages avec leur valeur courante |
| `:TTSVoice` / `:TTSSpeed` / `:TTSVolume` / `:TTSTarget` | Réglages individuels |

## Gotchas

- **Le taux d'échantillonnage vient du modèle**, pas d'une constante. L'upstream codait 22050 en
  dur (`backends/piper_tts.py:43`) alors que les voix `x_low` sont à 16000 — sa voix italienne par
  défaut était donc lue trop aiguë.
- **`.gitignore:6` contient `/plugins`** : les fichiers du plugin doivent être ajoutés avec
  `git add -f`, comme `bookmarks` et `hover-translator`.
- **Tunnel *stale*** : après une déconnexion brutale, sshd peut garder le port lié et le
  `RemoteForward` suivant échoue avec un simple avertissement. Symptôme trompeur — Neovim se
  connecte mais rien ne sort. `ServerAliveInterval 30` l'évite dans la plupart des cas.
- **Deux sessions SSH simultanées** vers le même hôte : seule la première obtient le port.
- **Le démon refuse toute adresse hors boucle locale** : le forward SSH est le seul chemin d'accès.
- **`config.opts` n'existe plus** : le module de configuration expose ses champs à plat
  (`config.speed`, pas `config.opts.speed`). Un vestige de l'API upstream avait survécu dans
  `util.getAndProcessText` et faisait échouer `:TTS` sur une sélection.
- `tests/minimal_init.lua` doit prépendre `plugins/tts.nvim` au runtimepath — le `lua/` de la
  racine ne résout pas les plugins tenus sous `plugins/`.

## Changelog
- 2026-08-18 : création. Clone de l'upstream élagué vers Piper seul, transport déporté vers un
  démon côté client, réglages runtime et picker Snacks, tests mini.test contre le démon en
  `--dry-run`. Chantier `tts-piper`.
- 2026-08-18 : `util.getAndProcessText` passait `config.opts`, disparu à l'élagage — `:TTS`
  levait une erreur sur toute sélection. Corrigé, et le chemin sélection → texte est désormais
  couvert par `tests/tts/test_selection.lua`. Au passage, les lignes d'une sélection multi-lignes
  sont jointes par une espace : l'upstream les soudait.
