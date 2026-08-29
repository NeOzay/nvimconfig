+++
id = "listdir-cache-document-homonyme"
title = "Deux répertoires-listes homonymes partagent le document concaténé de `listdir`"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "pertinent"
+++

## Constat

`plugins/listdir/lua/listdir/document.lua`, `M.path(contract)` ne dérive le nom du fichier de cache
que de `contract.name`, assaini par `contract.name:gsub("[^%w%-_.]", "_")`. Ouvrir le document de
deux listes `demo` distinctes rend le même `bufnr` et le même `~/.cache/nvim/listdir/demo.md`
(vérifié pendant l'audit).

## Pourquoi c'est gênant

Le contenu est régénéré à chaque ouverture, donc jamais faux dans la fenêtre active ; mais une
fenêtre restée sur le premier document affiche silencieusement le second. Le chemin d'origine écrit
en tête du document atténue sans lever l'ambiguïté.

## Pour solder

Faire entrer le chemin du répertoire-liste dans le nom du fichier de cache, par exemple un condensé
court suffixant le nom déclaré au contrat.

*Identifié par `implementation-auditor`, R6 du rapport d'audit `list-dir-viewer`.*

## Assumé

<OPTIONNEL>
