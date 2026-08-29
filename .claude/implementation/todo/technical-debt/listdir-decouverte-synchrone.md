+++
id = "listdir-decouverte-synchrone"
title = "La découverte des répertoires-listes bloque l'interface une seconde"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/listdir/lua/listdir/discover.lua`, `M.find(paths, depth)` parcourt l'arborescence de façon
synchrone. Après l'ajout de l'option `ignore` et la suppression du double scan, `depth = 10` sur
`$HOME` mesure encore ~1 s (32 ms sur ce dépôt). La spec livrée, `lua/plugins/listdir.lua`, pose
`depth = 10`.

## Pourquoi c'est gênant

L'ouverture du picker fige Neovim d'autant, sur un geste qu'on répète. Le coût est proportionnel à
la taille de l'arborescence, pas au nombre de listes.

## Pour solder

Passer la découverte au finder asynchrone de Snacks (`function(cb)`), ou mémoriser le résultat du
scan avec une invalidation explicite.

*Identifié par `implementation-auditor`, R3 du rapport d'audit `list-dir-viewer`.*

## Assumé

<OPTIONNEL>
