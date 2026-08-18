# TTS Piper avec démon côté client, pilotable depuis Neovim

Brief : `.claude/implementation/tts-piper.brief.md` (validé, `execution: direct`)

## Contexte

La config Neovim tourne sur un VPS qui n'a **aucune sortie audio** : `/dev/snd` ne contient que
`seq` et `timer`, aucun module `snd` chargé, ni PulseAudio ni PipeWire, `DISPLAY` vide. Or
`tts.nvim` (upstream `johannww/tts.nvim`) synthétise **et joue** le son côté serveur : chaque
backend termine par un `subprocess.Popen(["ffplay", …])` (`backends/piper_tts.py:37`,
`backends/edge.py:24`). En SSH, rien ne peut sortir.

Le poste de travail est sous Bazzite (Fedora Atomic), avec PipeWire natif — donc `pw-play`
disponible sans ffmpeg. La cible : **Piper tourne sur Bazzite, le VPS n'envoie que du texte**, et
la même config Neovim fonctionne des deux côtés sans distinction.

L'astuce qui rend cela possible sans brancher sur le contexte : Neovim s'adresse **toujours** à
`127.0.0.1:7788`. En local, le démon est là. En SSH, un `RemoteForward` y mène. Sans tunnel, la
connexion est refusée et Neovim le dit sans casser.

## Architecture retenue

```
Bazzite : tts-piperd (systemd --user) sur 127.0.0.1:7788
            PiperVoice résident ──> pw-play

nvim local  ──> 127.0.0.1:7788   direct
nvim VPS    ──> 127.0.0.1:7788   via RemoteForward 7788 127.0.0.1:7788
nvim VPS sans tunnel ──> ECONNREFUSED → vim.notify(WARN)
```

Trois écarts délibérés d'avec l'upstream (divergence assumée, cf. brief) :

1. **Plus de relais Python côté Neovim.** L'upstream lance un démon Python par backend
   (`init.lua:88`, `plenary.Job`) et lui parle sur stdin. On le remplace par un client `vim.uv`
   TCP en Lua : le VPS n'a alors strictement aucune dépendance à installer.
2. **Piper seul**, mais la table `M.backends` de `backends.lua` est conservée comme point
   d'enregistrement (choix explicite du brief).
3. **Le catalogue de voix vit sur Bazzite.** Le picker interroge le démon (`{"op":"voices"}`)
   plutôt que de lire une table figée : le VPS ne peut pas savoir quels modèles sont téléchargés.

### Protocole

JSON une ligne, terminé par `\n`, sur TCP loopback :

- `{"op":"speak","text":…,"voice":…,"speed":…,"volume":…}` → `{"ok":true}`
- `{"op":"stop"}` → interrompt la lecture en cours (remplacement, comportement de l'upstream)
- `{"op":"voices"}` → `{"ok":true,"voices":[…]}` (modèles `.onnx` présents côté Bazzite)

Le démon lit `voice.config.sample_rate` au lieu du 22050 codé en dur de l'upstream
(`backends/piper_tts.py:43`) — les modèles `x_low` échantillonnent à 16000.

## Étapes

### 1. Fork et submodule

`gh` n'est pas installé sur le VPS, mais l'authentification SSH GitHub y répond déjà `Hi NeOzay!`.
**Action utilisateur préalable** : créer le fork `NeOzay/tts.nvim` depuis l'interface GitHub.
Ensuite `git submodule add -f git@github.com:NeOzay/tts.nvim.git plugins/tts.nvim`, conformément
aux six forks existants (`.gitmodules`).

Le `-f` n'est pas cosmétique : `.gitignore:6` contient `/plugins`, et
`git check-ignore -v plugins/tts.nvim` confirme que le chemin est ignoré. Les neuf plugins déjà
présents sous `plugins/` sont bien suivis malgré cette règle ; sans `-f`, `submodule add` refuse.

Fichiers : `.gitmodules`, `plugins/tts.nvim/`
Vérif : `test -f plugins/tts.nvim/lua/tts-nvim/init.lua && git -C plugins/tts.nvim remote -v`

### 2. Élagage du fork vers Piper seul

Supprimer `backends/edge.py`, `backends/openai_tts.py`, les entrées `edge`/`openai` de
`backends.lua` et les options correspondantes de `config.lua`. Corriger au passage les deux
défauts relevés : `M = {}` sans `local` — présent **aussi bien dans `init.lua:1` que dans
`config.lua:1`**, fuite en global dont dépend `plugin/tts-nvim.lua` — et le déréférencement de
`backend.validate_config` sur backend inconnu (`init.lua:63-80`).

Fichiers : `plugins/tts.nvim/lua/tts-nvim/{init,backends,config}.lua`,
`plugins/tts.nvim/plugin/tts-nvim.lua`, suppression de `backends/edge.py`, `backends/openai_tts.py`
Vérif : `! grep -rq '^M = {}' plugins/tts.nvim/lua/ && ! grep -rqi 'openai\|edge' plugins/tts.nvim/lua/ plugins/tts.nvim/backends/ && nvim --headless -c "lua assert(loadfile('plugins/tts.nvim/lua/tts-nvim/backends.lua'))" -c qa`

### 3. Client TCP en Lua

Nouveau `lua/tts-nvim/client.lua` : connexion `vim.uv.new_tcp()` vers `config.host/port`, envoi
d'une requête JSON, lecture de la réponse, timeout court. Sur `ECONNREFUSED` → `vim.notify` en
`WARN` nommant la cible, sans erreur Lua. `M.tts`/`M.tts_to_file` (`init.lua:12-26`) passent par le
client ; le `Job:new` de l'upstream disparaît. `plenary` reste requis uniquement par
`text_processor.lua` (pandoc).

`tests/minimal_init.lua` ne prépend aujourd'hui que mini.test et `vim.fn.getcwd()` : le code du
fork, sous `plugins/tts.nvim/lua/tts-nvim/`, n'y est pas résolvable. Une ligne
`vim.opt.rtp:prepend(vim.fn.getcwd() .. "/plugins/tts.nvim")` est ajoutée — sans elle, ni cette
vérification ni les tests de l'étape 6 ne peuvent charger le plugin.

Fichiers : `plugins/tts.nvim/lua/tts-nvim/{client,init,backends}.lua`, `tests/minimal_init.lua`
Vérif : `! grep -rq 'Job:new' plugins/tts.nvim/lua/tts-nvim/init.lua && nvim --headless -u tests/minimal_init.lua -c "lua local c=require('tts-nvim.client'); assert(type(c.request)=='function')" -c qa`

### 4. Démon Piper et unit systemd

Nouveau `daemon/tts-piperd.py` dans le fork : serveur TCP lié à `127.0.0.1` seulement, cache des
`PiperVoice` chargés, synthèse en flux, PCM poussé dans
`pw-play --format s16 --rate <sr> --channels 1 --volume <v> -`. **L'import de `piper` est
paresseux** et un mode `--dry-run` répond au protocole sans synthétiser ni jouer — c'est ce qui
rend l'étape 6 exécutable sur le VPS, où ni Piper ni PipeWire n'existent.

`daemon/tts-piperd.service` (systemd `--user`) et `daemon/README.md` : installation sous Bazzite
(`uv` en espace utilisateur, pas de `rpm-ostree`), téléchargement des modèles, ligne
`RemoteForward 7788 127.0.0.1:7788` dans `~/.ssh/config`.

Fichiers : `plugins/tts.nvim/daemon/{tts-piperd.py,tts-piperd.service,README.md}`
Vérif : `python3 -m py_compile plugins/tts.nvim/daemon/tts-piperd.py`

### 5. Réglages runtime et interface

Voix/modèle, vitesse, volume et cible (hôte:port) modifiables **pour la session courante
seulement**, aucune écriture disque. Commandes `:TTSVoice`, `:TTSSpeed`, `:TTSVolume`,
`:TTSTarget`, plus un `:TTSConfig` ouvrant un picker Snacks des quatre réglages avec leur valeur
courante — le dépôt pratique déjà ce style (`plugins/bookmarks/lua/bookmarks/snacks_picker.lua`,
`docs/plugins/snacks-picker-custom.md`). L'entrée « voix » ouvre un sous-picker alimenté par
`{"op":"voices"}`.

Fichiers : `plugins/tts.nvim/lua/tts-nvim/{config,ui}.lua`, `plugins/tts.nvim/plugin/tts-nvim.lua`
Vérif : `nvim --headless -u tests/minimal_init.lua -c "lua require('tts-nvim').setup({}); assert(vim.fn.exists(':TTSConfig')==2)" -c qa`

### 6. Tests mini.test

Deux fichiers, sur le modèle de `tests/lsp/hover/test_format.lua` :

- `tests/tts/test_protocol.lua` — logique métier : encodage/décodage des requêtes, application des
  réglages runtime, comportement quand la cible est injoignable.
- `tests/tts/test_daemon_io.lua` — communication réelle : le test démarre `tts-piperd.py --dry-run`
  sur **le port 7799** (distinct du 7788 de production), fait un aller-retour `speak` et `voices`
  via `client.lua`, puis arrête le démon.

Le runtimepath des tests aura été corrigé à l'étape 3 ; sans cela `require("tts-nvim.client")`
échoue là où `require("lsp.hover.format")` réussit, ce dernier étant résolu par `lua/` à la racine.

Fichiers : `tests/tts/test_protocol.lua`, `tests/tts/test_daemon_io.lua`
Vérif : `make test`

### 7. Intégration au dépôt

Spec Lazy `lua/plugins/tts.lua` avec `dir = vim.fn.stdpath("config") .. "/plugins/tts.nvim"` sur le
modèle de `lua/plugins/markview.lua`, import `{ import = "plugins.tts" }` dans `init.lua` (les specs
sont explicitement listées, pas auto-découvertes), doc `docs/plugins/tts.md` au gabarit de
`CLAUDE.md`, et la ligne correspondante dans l'index des plugins de `CLAUDE.md`.

Fichiers : `lua/plugins/tts.lua`, `init.lua`, `docs/plugins/tts.md`, `CLAUDE.md`
Vérif : `nvim --headless -c "lua assert(require('lazy.core.config').plugins['tts.nvim'], 'spec non chargée')" -c qa` (ici la config complète est voulue : c'est le chargement par lazy.nvim qu'on contrôle)

## Vérification de bout en bout

Sur le VPS, sans audio ni Piper :

```bash
make test                                    # logique + aller-retour sur 7799
nvim --headless -c "lua assert(require('tts-nvim'))" -c qa
```

Sur Bazzite, après installation du démon (`daemon/README.md`) :

```bash
systemctl --user status tts-piperd
```

puis, à l'oreille : sélection visuelle + `:TTS` dans Neovim **en local**, puis le même geste
**depuis le VPS en SSH** avec le `RemoteForward` actif. Enfin, `:TTS` depuis le VPS **sans tunnel**
doit produire une notification claire et aucune erreur Lua.

## Hors-périmètre (rappel du brief)

Pas de Piper sur le VPS · backends `edge` et `openai` supprimés · aucune persistance disque des
réglages · aucune compatibilité merge avec l'upstream.

## Signaux d'arrêt

S'arrêter et en reparler si : `lua/plugins/tts.lua` doit brancher sur `$SSH_CONNECTION` · une
dépendance audio réapparaît côté VPS · une couche « transport pluggable » apparaît · le démon
déborde du TTS.

## Incertitude reportée

L'environnement Bazzite n'est pas vérifiable depuis le VPS : présence de `uv` et `pw-play`,
version de Python, emplacement des modèles Piper, et l'option `--volume` de `pw-play`. L'unit
systemd et la doc d'installation seront écrites sans pouvoir être exécutées — validation par
l'utilisateur sur sa machine.
