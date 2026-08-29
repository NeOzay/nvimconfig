+++
id = "test-deduction-voix-non-discriminant"
title = "Le test de déduction de voix ne discrimine que par coïncidence"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`tests/tts/test_protocol.lua`, cas `build_request` / « déduit la voix de la langue » : il lit la voix
attendue dans la table que le code testé consulte lui-même — `local expected =
config.languages_to_voice[config.backend]["fr"]`. Il ne distingue le cas « voix déduite de la
langue » du cas « repli sur `piper_model` » que parce que `piper_model` (`fr_FR-siwis-medium`)
diffère aujourd'hui de `languages_to_voice.piper.fr` (`fr_FR-glados-medium`).

## Pourquoi c'est gênant

Si les deux valeurs venaient à coïncider, le test passerait aussi bien sur un `current_voice()`
retombé sur le repli, c'est-à-dire dans le cas qu'il est censé exclure.

## Pour solder

Poser dans le test une table `languages_to_voice` propre, dont la valeur `fr` diffère explicitement
de `piper_model`.

*Identifié par `implementation-auditor`, R13 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
