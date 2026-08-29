+++
id = "listdir-sans-tests"
title = "Le plugin `listdir` ne livre aucun test, dans un dépôt qui en a le cadre"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/listdir/` n'a pas une ligne de test alors que le dépôt fait tourner 60 cas MiniTest — le
`Makefile` porte une cible `test` (`nvim --headless -u tests/minimal_init.lua -c "lua
MiniTest.run()"`), et `tests/` contient `minimal_init.lua`, `tests/lsp/` et `tests/tts/`. Le plan du
chantier affirmait « aucune infrastructure de test ajoutée au dépôt (il n'en a pas) » — c'est faux,
et le plan a été validé ainsi. `contract.read`, `item.parse`, `document.render` et `shifted` sont
pures et conçues pour être vérifiables.

## Pourquoi c'est gênant

Chaque évolution du parseur de contrat, du décalage de titres ou de la forme des liens se
revérifiera à la main, par des commandes headless jetables qui ne survivent pas à la session. Deux
de ces commandes, celles des étapes 7 et 8 du plan, sont d'ailleurs déjà périmées et ont dû être
adaptées pendant l'audit.

## Pour solder

Un `tests/listdir/` couvrant au minimum `contract.read` (métadonnées bornées au premier `[`),
`item.parse` (front matter absent, présent, non refermé), `document.render` (décalage des titres
hors blocs de code, forme `<…>` des liens à parenthèses).

*Identifié par `implementation-auditor`, R5 du rapport d'audit `list-dir-viewer`.*

## Assumé

<OPTIONNEL>
