+++
id = "license-mentionne-edge-tts"
title = "Le LICENSE du plugin mentionne une dépendance supprimée"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "pertinent"
+++

## Constat

`plugins/tts.nvim/LICENSE` mentionne encore la bibliothèque `edge_tts` et sa LGPLv3 — la clause
« This software uses the library edge_tts, licensed under the GNU Lesser General Public License v3
(LGPLv3). » — alors que le backend `edge` a été retiré au chantier `tts-piper`. C'est la dernière
occurrence de `edge`/`openai` dans le plugin.

## Pourquoi c'est gênant

Affirmation fausse dans un fichier légal suivi par ce dépôt.

## Pour solder

Retirer la clause `edge_tts`, en gardant l'attribution d'origine du plugin.

*Identifié par `implementation-auditor`, R6 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
