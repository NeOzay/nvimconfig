# tts-piperd — installation sur le poste de travail

Le démon tourne **sur la machine qui a une sortie audio**, jamais sur un serveur distant. Neovim
n'exécute aucune synthèse : il envoie du texte à `127.0.0.1:7788`. En local le démon est là ;
à travers SSH, un `RemoteForward` y mène. La configuration Neovim est donc la même des deux côtés.

> Instructions écrites pour **Bazzite** (Fedora Atomic). Elles n'ont pas pu être exécutées sur la
> machine de développement, qui est un VPS sans audio — à valider au premier passage.

## 1. Environnement Python

Bazzite étant immuable, rien ne passe par `rpm-ostree` : tout reste en espace utilisateur.

```bash
# uv, s'il n'est pas déjà là (Bazzite embarque aussi Homebrew : `brew install uv` marche)
curl -LsSf https://astral.sh/uv/install.sh | sh

uv venv ~/.local/share/tts-piperd/venv
uv pip install --python ~/.local/share/tts-piperd/venv/bin/python piper-tts
```

`piper-tts` tire `onnxruntime` (~200 Mo). Les wheels existent pour CPython 3.11 à 3.14 en x86_64.

## 2. Modèles de voix

Les modèles vivent dans `~/.local/share/piper-voices` — c'est ce répertoire que le démon liste
pour l'opération `voices`, donc pour le picker de Neovim.

```bash
mkdir -p ~/.local/share/piper-voices
~/.local/share/tts-piperd/venv/bin/python -m piper.download_voices \
    --download-dir ~/.local/share/piper-voices \
    fr_FR-siwis-medium en_US-lessac-medium
```

## 3. Lecture audio

Le démon pousse du PCM brut dans `pw-play`, fourni par PipeWire — présent d'origine sur Bazzite,
aucun ffmpeg requis. Contrôle rapide :

```bash
command -v pw-play && pw-play --help | grep -- --volume
```

## 4. Service systemd

```bash
mkdir -p ~/.config/systemd/user
cp ~/.config/nvim/plugins/tts.nvim/daemon/tts-piperd.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now tts-piperd
systemctl --user status tts-piperd
```

L'unit suppose la configuration Neovim en `~/.config/nvim` et le venv en
`~/.local/share/tts-piperd/venv`. Si l'un des deux diffère, ajuster `ExecStart`.

## 5. Tunnel SSH

Sur le poste de travail, dans `~/.ssh/config` :

```
Host mon-vps
    RemoteForward 7788 127.0.0.1:7788
    ServerAliveInterval 30
```

Le forward se monte à chaque connexion. Les keepalives ne sont pas décoratifs : après une
déconnexion brutale, sshd peut garder le port lié côté serveur, et le `RemoteForward` suivant
échoue avec un simple avertissement — le symptôme est alors « Neovim se connecte mais rien ne
sort ». `GatewayPorts` valant `no` par défaut, le port n'est lié qu'à la boucle locale du serveur.

Deux sessions SSH simultanées vers le même hôte : seule la première obtient le port. Depuis la
même machine c'est transparent ; depuis deux machines différentes, le son sort chez la première.

## 6. Vérifier sans Neovim

```bash
printf '{"op":"voices"}\n' | nc 127.0.0.1 7788
printf '{"op":"speak","text":"bonjour","voice":"fr_FR-siwis-medium","speed":1.0,"volume":1.0}\n' | nc 127.0.0.1 7788
```

## 7. Aucun son alors que le démon répond `{"ok":true}`

`speak` rend la main avant que la synthèse ait commencé : la réponse dit que la requête est
acceptée, pas que le son est sorti. Tout ce qui échoue ensuite part au journal.

```bash
journalctl --user -u tts-piperd -f
```

**Le démon tourne-t-il sur le code du dépôt ?** Systemd exécute le script en place : une
modification ne prend effet qu'au redémarrage du service. Le message d'écoute le trahit — il doit
commencer par `INFO`.

```bash
systemctl --user restart tts-piperd
```

Puis, dans l'ordre :

```bash
# 1. PipeWire répond-il, et pw-play accepte-t-il ses options ?
pw-play --help

# 2. Le son sort-il hors du démon ?
pw-play /usr/share/sounds/freedesktop/stereo/bell.oga

# 3. Le démon voit-il la même session PipeWire que ta session graphique ?
systemctl --user show-environment | grep -E "XDG_RUNTIME_DIR|WAYLAND_DISPLAY|DISPLAY"
```

Un service `--user` hérite de `XDG_RUNTIME_DIR`, ce qui suffit à joindre PipeWire. Si le socket
n'est pas visible, `systemctl --user import-environment` depuis la session graphique le corrige.

### `sndfile: failed to open audio file "-": Format not recognised`

`pw-play` lit stdin via libsndfile et y cherche un en-tête de conteneur ; le PCM nu de Piper n'en a
pas. L'option `--raw` est donc obligatoire, et `--format`/`--rate`/`--channels` ne la remplacent pas.

Pour voir le démon travailler en direct, l'arrêter et le lancer à la main :

```bash
systemctl --user stop tts-piperd
~/.local/share/tts-piperd/venv/bin/python \
    ~/.config/nvim/plugins/tts.nvim/daemon/tts-piperd.py --verbose
```

## Options

| Option | Défaut | Rôle |
|---|---|---|
| `--host` | `127.0.0.1` | Refuse toute adresse hors boucle locale |
| `--port` | `7788` | Port d'écoute |
| `--voices-dir` | `~/.local/share/piper-voices` | Modèles `.onnx` |
| `--output-dir` | `~/tts-nvim` | Destination de `:TTSFile` |
| `--dry-run` | — | Répond au protocole sans Piper ni `pw-play` (tests). `speak` exige quand même que `<voix>.onnx` et `<voix>.onnx.json` existent dans `--voices-dir` : des fichiers vides suffisent, leur contenu n'est jamais lu |

## Protocole

Une ligne JSON par requête, une ligne JSON par réponse.

| Requête | Réponse |
|---|---|
| `{"op":"speak","text":…,"voice":…,"speed":…,"volume":…}` | `{"ok":true}` |
| `{"op":"save","text":…,"voice":…,"speed":…}` | `{"ok":true,"path":…}` |
| `{"op":"stop"}` | `{"ok":true}` |
| `{"op":"voices"}` | `{"ok":true,"voices":[…]}` |

Une erreur répond `{"ok":false,"error":…}`. Le fichier de `save` est écrit **sur la machine du
démon**, pas sur celle où tourne Neovim.
