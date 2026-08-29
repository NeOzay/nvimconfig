+++
id = "ttsfile-ecrase-le-meme-fichier"
title = "`:TTSFile` écrase toujours le même fichier"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/tts.nvim/daemon/tts-piperd.py` : l'opération `save` de `Server.dispatch` écrit
systématiquement `self.output_dir / "tts.wav"`. Vérifié en `--dry-run` : le chemin est constant.

## Pourquoi c'est gênant

Deux `:TTSFile` de suite détruisent le premier enregistrement sans avertir, et la notification côté
Neovim annonce un chemin qui vient d'être écrasé.

## Pour solder

Horodater le nom de fichier, ou accepter un nom dans la requête.

*Identifié par `implementation-auditor`, R5 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
