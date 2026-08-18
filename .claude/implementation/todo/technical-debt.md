# Registre de dette technique

Ce que les chantiers de ce dépôt ont laissé derrière eux : problèmes **constatés et vérifiés**,
non résolus au moment de clore. Chaque entrée dit ce qui a été vu, pourquoi c'est gênant, et par
quoi elle serait soldée.

N'y figurent pas : les idées d'amélioration (rien n'a été constaté), ce qui a été corrigé pendant
le chantier (le rapport d'audit en garde la trace), ni les préférences de style qu'aucun critère
ne porte.

Une entrée soldée est **retirée** d'ici et déplacée dans `technical-debt-solde.md`, avec la
commande qui l'établit.

> Dernière vérification : 2026-08-18 (chantier `tts-piper`)

## 2026-08-18 — `:TTSVoice` rend `:TTSSetLanguage` définitivement sans effet

**Constat** — `plugins/tts.nvim/lua/tts-nvim/config.lua:63-69` : dès que `config.voice` est posé
par `:TTSVoice`, `current_voice()` le renvoie toujours et la déduction par langue est court-circuitée
pour toute la session. `tts_set_language` (`init.lua:72-86`) notifie pourtant
`langue fr (fr_FR-siwis-medium)` — une voix qui ne sera pas utilisée.

**Pourquoi c'est gênant** — aucun moyen de revenir au mode « voix déduite de la langue » sans
redémarrer Neovim, et le message affirme le contraire du comportement réel.

**Pour solder** — permettre à `:TTSVoice` de reprendre la valeur vide pour remettre `config.voice`
à `nil`, et faire dire à la notification de `:TTSSetLanguage` quelle voix sera *effectivement*
utilisée.

*Identifié par `implementation-auditor`, R3 du rapport d'audit `tts-piper`.*

## 2026-08-18 — `text_processor.lua` porte deux défauts hérités de l'upstream

**Constat** — `plugins/tts.nvim/lua/tts-nvim/text_processor.lua` : (a) le motif de lien markdown
`text:gsub("%[(.-)%]%(.-)", "%1")` (ligne 44) n'a pas de parenthèse fermante `%)` et ne consomme
donc pas la cible du lien ; (b) `pandoc()` (lignes 17-20) appelle `vim.system(…):wait()` de façon
**bloquante** dans la boucle d'événements. Le module est aussi le seul du plugin resté au style
upstream (4 espaces, commentaires anglais, annotations Emmylua absentes).

**Pourquoi c'est gênant** — l'URL d'un lien markdown est lue à voix haute, et une grosse sélection
avec `syntax_removal_method = "pandoc"` fige Neovim le temps de la conversion. Le dépôt d'origine
ayant été supprimé, personne d'autre ne les corrigera.

**Pour solder** — fermer le motif en `%[(.-)%]%(.-%)`, passer `pandoc()` en asynchrone via le
callback de `vim.system`, et aligner le fichier sur le style du dépôt.

*Identifié par `implementation-auditor`, R4 du rapport d'audit `tts-piper`.*

## 2026-08-18 — `:TTSFile` écrase toujours le même fichier

**Constat** — `plugins/tts.nvim/daemon/tts-piperd.py` : l'opération `save` écrit systématiquement
`<output-dir>/tts.wav`. Vérifié en `--dry-run` : le chemin est constant.

**Pourquoi c'est gênant** — deux `:TTSFile` de suite détruisent le premier enregistrement sans
avertir, et la notification côté Neovim annonce un chemin qui vient d'être écrasé.

**Pour solder** — horodater le nom de fichier, ou accepter un nom dans la requête.

*Identifié par `implementation-auditor`, R5 du rapport d'audit `tts-piper`.*

## 2026-08-18 — Le LICENSE du plugin mentionne une dépendance supprimée

**Constat** — `plugins/tts.nvim/LICENSE:27` mentionne encore la bibliothèque `edge_tts` et sa
LGPLv3, alors que le backend `edge` a été retiré au chantier `tts-piper`. C'est la dernière
occurrence de `edge`/`openai` dans le plugin.

**Pourquoi c'est gênant** — affirmation fausse dans un fichier légal suivi par ce dépôt.

**Pour solder** — retirer la clause `edge_tts`, en gardant l'attribution d'origine du plugin.

*Identifié par `implementation-auditor`, R6 du rapport d'audit `tts-piper`.*

## 2026-08-18 — Le délai de garde du client TTS n'est pas armé si `uv.new_timer()` échoue

**Constat** — `plugins/tts.nvim/lua/tts-nvim/client.lua:69-103` : le `if timer then` laisse la
requête sans délai si la création du timer échoue, sans notifier ni appeler `on_response` — alors
que l'échec de `uv.new_tcp()` juste au-dessus, lui, notifie (lignes 64-67).

**Pourquoi c'est gênant** — chemin d'échec silencieux : la requête reste pendante indéfiniment.
Très improbable, mais l'incohérence avec le cas voisin est ce qui le rend notable.

**Pour solder** — notifier et abandonner comme pour `uv.new_tcp()`.

*Identifié par `implementation-auditor`, R8 du rapport d'audit `tts-piper`.*

## 2026-08-18 — La vérification de l'étape 2 a perdu une clause du plan

**Constat** — l'étape 2 du suivi `tts-piper` a laissé tomber la clause
`! grep -rqi 'openai\|edge'` que portait le plan. Rejouée à l'audit, elle échouerait aujourd'hui,
sur `LICENSE` seul. La réserve du `plan-reviewer` sur l'étape 4 (démon + unit systemd + doc pour
une seule vérification de présence) est du même ordre : assumée, jamais levée.

**Pourquoi c'est gênant** — un lecteur ultérieur ne peut pas distinguer un assouplissement raisonné
d'un oubli ; l'écart n'est justifié ni dans l'étape ni au journal.

**Pour solder** — au prochain chantier sur ce plugin, justifier l'écart au journal ou rétablir la
clause une fois le `LICENSE` corrigé.

*Identifié par `implementation-auditor`, R9 du rapport d'audit `tts-piper`.*

## 2026-08-18 — `speak` coupe la lecture en cours avant de savoir si la nouvelle aboutira

**Constat** — `plugins/tts.nvim/daemon/tts-piperd.py` : le `player.stop()` remonté dans `dispatch`
interrompt la lecture dès qu'une demande est acceptée, avant toute synthèse. Constaté à l'audit
avec `pw-play` introuvable : réponse `{"ok": true}`, phrase précédente coupée, échec visible au
seul journal.

**Assumé** — compromis délibéré, documenté dans le code : l'alternative retardait l'interruption du
temps de chargement d'un modèle froid (~0,84 s).

**Pourquoi c'est gênant** — élargit la fenêtre où le client croit à un succès qui n'aura pas lieu.

**Pour solder** — ne couper qu'une fois le premier bloc PCM prêt, si le coût en latence
d'interruption redevient acceptable.

*Identifié par `implementation-auditor`, R11 du rapport d'audit `tts-piper`.*

## 2026-08-18 — Le test de déduction de voix ne discrimine que par coïncidence

**Constat** — `tests/tts/test_protocol.lua:68-74` lit la voix attendue dans la table que le code
testé consulte lui-même. Il ne distingue le cas « voix déduite de la langue » du cas « repli sur
`piper_model` » que parce que `piper_model` (`fr_FR-siwis-medium`) diffère aujourd'hui de
`languages_to_voice.piper.fr` (`fr_FR-glados-medium`).

**Pourquoi c'est gênant** — si les deux valeurs venaient à coïncider, le test passerait aussi bien
sur un `current_voice()` retombé sur le repli, c'est-à-dire dans le cas qu'il est censé exclure.

**Pour solder** — poser dans le test une table `languages_to_voice` propre, dont la valeur `fr`
diffère explicitement de `piper_model`.

*Identifié par `implementation-auditor`, R13 du rapport d'audit `tts-piper`.*
