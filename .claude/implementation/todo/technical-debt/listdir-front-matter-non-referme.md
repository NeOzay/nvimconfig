+++
id = "listdir-front-matter-non-referme"
title = "`listdir` lit un front matter non refermé sans le signaler"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/listdir/lua/listdir/item.lua` : si le second délimiteur `+++` manque, tout le fichier est
consommé comme front matter et `body` ressort vide, sans `err` (vérifié : `title` lu, `body` vide).
Les autres chemins d'erreur du plugin sont corrects — `cli.list` distingue le code non nul de
l'exception `vim.system`, et le finder `notify` puis rend une liste vide.

## Pourquoi c'est gênant

L'élément apparaît normalement dans le picker, avec son titre, et sa section disparaît du document
concaténé sans un mot. C'est le seul échec muet restant du plugin, et il ressemble à un élément au
corps vide.

## Pour solder

Rendre une erreur quand le délimiteur fermant manque, et la remonter comme les autres (`notify`), ou
à défaut marquer l'élément dans le document.

*Identifié par `implementation-auditor`, R7 du rapport d'audit `list-dir-viewer`.*

## Assumé

<OPTIONNEL>
