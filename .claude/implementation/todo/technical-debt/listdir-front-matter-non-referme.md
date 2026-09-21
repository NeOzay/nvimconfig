+++
id = "listdir-front-matter-non-referme"
title = "`listdir` lit un front matter non refermé sans le signaler"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "pertinent"
+++

## Constat

`lua/frontmatter.lua`, `parse` (déplacé depuis `plugins/listdir/lua/listdir/item.lua` par le
chantier `chantier-docs-commands`, 2026-09-21 ; `listdir.item` et `lua/chantier.lua` en héritent) : si le second délimiteur `+++` manque, tout le fichier est
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

*Emplacement corrigé le 2026-09-21. Établi par : `require('frontmatter').read()` sur `+++\ntitle = "x"\n\nbody` → `{ body = "", title = "x" }`, sans `err`.*

## Assumé

<OPTIONNEL>
