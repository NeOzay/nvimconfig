---
slug: tts-piper
titre: TTS Piper avec démon côté client, pilotable depuis Neovim
branche: tts-piper
base: master
statut: en-cours
session: 2
execution: direct
plan: .claude/plans/linear-scribbling-papert.md
brief: .claude/implementation/tts-piper.brief.md
créé: 2026-08-18
maj: 2026-08-18
---

## Objectif et périmètre

Repris du brief (`brief:`), pas réinventé.

**Symptôme** : « Je veux étudier la faisabilité d'utiliser un TTS en SSH » — la config Neovim
tourne sur un VPS sans aucune sortie audio, et `tts.nvim` joue le son côté serveur via `ffplay`.

**But** : faire lire du texte par Piper sur le poste Bazzite, que Neovim tourne en local ou sur
le VPS via SSH, avec la même config Neovim des deux côtés.

**Critères de réussite** :
- des tests automatisés couvrent la logique du fork et le protocole d'échange, joués en loopback
  sur un port distinct de celui de production
- la lecture audio elle-même n'est pas testée automatiquement — validation à l'oreille
- `make test` passe

**Hors-périmètre** :
- Piper ne tourne pas sur le VPS
- les backends `edge` et `openai` sont supprimés du fork
- aucune persistance des réglages sur disque
- pas de compatibilité merge avec l'upstream : divergence totalement assumée

**Amendement du 2026-08-18** : le plugin n'est plus un fork submodule `NeOzay/tts.nvim` mais un
clone de l'upstream dont le dépôt git a été supprimé, **suivi directement par ce dépôt** — même
catégorie que `bookmarks`, `hover-translator` et `docstring-highlight.nvim` (CLAUDE.md). Tombent
avec ce changement : la création du fork sur GitHub, le push du SHA avant référencement, et
l'entrée dans `.gitmodules`.

**Signaux de dérive** :
- si `lua/plugins/tts.lua` doit détecter le contexte ou brancher sur `$SSH_CONNECTION`
- si une dépendance audio (ffmpeg, ffplay, piper, onnxruntime) réapparaît côté VPS
- si une couche « transport pluggable » apparaît : il y a un seul transport, une socket TCP loopback
- si le démon déborde du TTS vers un service générique

## Étapes

- [x] 1. Clone de l'upstream sans son dépôt git — `plugins/tts.nvim/` — vérif: `test -f plugins/tts.nvim/lua/tts-nvim/init.lua && ! test -d plugins/tts.nvim/.git`
- [x] 2. Élagage du clone vers Piper seul — `plugins/tts.nvim/lua/tts-nvim/{init,backends,config}.lua`, `plugins/tts.nvim/plugin/tts-nvim.lua` — vérif: `! grep -rq '^M = {}' plugins/tts.nvim/lua/ && nvim --headless -c "lua assert(loadfile('plugins/tts.nvim/lua/tts-nvim/backends.lua'))" -c qa`
- [x] 3. Client TCP en Lua — `plugins/tts.nvim/lua/tts-nvim/client.lua`, `tests/minimal_init.lua` — vérif: `! grep -rq 'Job:new' plugins/tts.nvim/lua/tts-nvim/init.lua && nvim --headless -u tests/minimal_init.lua -c "lua assert(type(require('tts-nvim.client').request)=='function')" -c qa`
- [x] 4. Démon Piper et unit systemd — `plugins/tts.nvim/daemon/{tts-piperd.py,tts-piperd.service,README.md}` — vérif: `python3 -m py_compile plugins/tts.nvim/daemon/tts-piperd.py && test -f plugins/tts.nvim/daemon/tts-piperd.service -a -f plugins/tts.nvim/daemon/README.md`
- [x] 5. Réglages runtime et interface — `plugins/tts.nvim/lua/tts-nvim/{config,ui}.lua`, `plugins/tts.nvim/plugin/tts-nvim.lua` — vérif: `nvim --headless -u tests/minimal_init.lua -c "lua require('tts-nvim').setup({}); assert(vim.fn.exists(':TTSConfig')==2)" -c qa`
- [x] 6. Tests mini.test — `tests/tts/test_protocol.lua`, `tests/tts/test_daemon_io.lua` — vérif: `make test`
- [x] 7. Intégration au dépôt — `lua/plugins/tts.lua`, `init.lua`, `docs/plugins/tts.md`, `CLAUDE.md` — vérif: `nvim --headless -c "lua assert(require('lazy.core.config').plugins['tts.nvim'], 'spec non chargée')" -c qa`

## État courant

**Prochaine action** : validation à l'oreille sur Bazzite, puis depuis le VPS à travers le tunnel.

État constaté au 2026-08-18 (session 2, sur Bazzite) :
- le démon tournait sur du code antérieur à la journalisation — systemd exécute le script en place,
  une modification ne prend effet qu'au `restart`. Redémarré ;
- le journal a livré la cause du silence : `pw-play` quittait en code 1 avec
  `sndfile: failed to open audio file "-": Format not recognised` ;
- `--raw` ajouté à l'appel `pw-play` ; après redémarrage, `speak` ne journalise plus aucune erreur ;
- `--volume` existe bien dans `pw-play` : l'incertitude reportée du brief est levée, ce n'était pas
  le suspect.

**Vérification** : `make test` — 58 cas, 0 échec (rejoué en session 2)

**Dernier audit** : aucun

**Notes** : `.gitignore:6` contient `/plugins`, donc `plugins/tts.nvim/` est ignoré — le commit
devra passer par `git add -f`, comme les autres plugins suivis directement. Réserve du
`plan-reviewer` toujours ouverte : l'étape 4 est large (démon + unit systemd + doc) pour une
seule vérification de présence.

Modifications non commitées étrangères au chantier présentes dans l'arbre en début de session 2
(`codediff`, `trouble`, `cokeline`, `lualine`, un plan) : à ne jamais stager avec ce chantier.

## Journal de décisions

- **2026-08-18** — Neovim s'adresse inconditionnellement à `127.0.0.1:7788` ; le contexte
  local/SSH est absorbé par un `RemoteForward` côté client, pas par du code.
  *Pourquoi* : une seule config Neovim pour les deux machines, exigence du brief.
  *Rejeté* : tunnel PulseAudio inverse (PCM non compressé, ~1,4 Mbit/s, dépend du client).
- **2026-08-18** — Le relais Python de l'upstream est remplacé par un client `vim.uv` en Lua.
  *Pourquoi* : le VPS n'a alors aucune dépendance à installer.
  *Rejeté* : garder `plenary.Job` + un script relais Python côté serveur.
- **2026-08-18** — Le catalogue de voix est servi par le démon (`{"op":"voices"}`), pas par une
  table figée dans la config. *Pourquoi* : les modèles vivent sur Bazzite, le VPS ne peut pas
  savoir lesquels sont téléchargés.
- **2026-08-18** — Clone de l'upstream sans son dépôt git plutôt que fork submodule ; le plugin
  est suivi directement par ce dépôt. *Pourquoi* : la divergence étant totalement assumée, suivre
  l'upstream n'apporte rien et le push du SHA disparaît. *Rejeté* : submodule `NeOzay/tts.nvim`.
- **2026-08-18** — `plenary.nvim` n'est plus une dépendance du plugin : le transport passe par
  `vim.uv` et l'appel à pandoc par `vim.system`. *Pourquoi* : « on ne garde que le nécessaire », et
  la spec Lazy s'en trouve sans dépendance. *Rejeté* : conserver `plenary.job` pour pandoc seul.
- **2026-08-18** — Une requête = une connexion TCP, jamais de connexion maintenue. *Pourquoi* :
  une coupure du tunnel SSH laisserait sinon un client persuadé d'être connecté.
- **2026-08-18** — `util.getAndProcessText` référençait encore `config.opts`, supprimé lors de
  l'élagage : `:TTS` levait sur toute sélection. *Pourquoi noté* : la suite ne couvrait pas le
  chemin sélection → texte, c'est désormais le cas (`tests/tts/test_selection.lua`).
- **2026-08-18** — Le démon journalise via `logging` : stderr de `pw-play` remonté et code de
  retour contrôlé, exceptions du thread de lecture capturées. *Pourquoi* : la synthèse étant
  paresseuse, ses erreurs surviennent hors de la requête ; avec `stderr=DEVNULL` le seul symptôme
  était « aucun son ». *Rejeté* : laisser le diagnostic au seul client.
- **2026-08-18** — `pw-play` reçoit `--raw` : sans lui il cherche un en-tête de conteneur sur stdin
  et refuse le PCM nu de Piper. *Pourquoi noté* : `--format`/`--rate`/`--channels` ne suppléent pas
  `--raw`, et l'échec était silencieux avant la journalisation.
