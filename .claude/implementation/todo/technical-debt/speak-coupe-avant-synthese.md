+++
id = "speak-coupe-avant-synthese"
title = "`speak` coupe la lecture en cours avant de savoir si la nouvelle aboutira"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "pertinent"
+++

## Constat

`plugins/tts.nvim/daemon/tts-piperd.py` : le `self.player.stop()` remonté dans `Server.dispatch`
interrompt la lecture dès qu'une demande est acceptée, avant toute synthèse. Constaté à l'audit avec
`pw-play` introuvable : réponse `{"ok": true}`, phrase précédente coupée, échec visible au seul
journal.

## Pourquoi c'est gênant

Élargit la fenêtre où le client croit à un succès qui n'aura pas lieu.

## Pour solder

Ne couper qu'une fois le premier bloc PCM prêt, si le coût en latence d'interruption redevient
acceptable.

*Identifié par `implementation-auditor`, R11 du rapport d'audit `tts-piper`.*

## Assumé

Compromis délibéré, documenté dans le code : l'alternative retardait l'interruption du temps de
chargement d'un modèle froid (~0,84 s).
