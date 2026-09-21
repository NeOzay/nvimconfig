+++
id = "frontmatter-cache-masque-illisible"
title = "Le cache de `frontmatter.read` sert encore un fichier devenu illisible"
date = 2026-09-21
source = "chantier-docs-commands, rapport .claude/implementation/done/2026-09-21-chantier-docs-commands.audit.md"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`lua/frontmatter.lua`, `M.read` : le cache est validé sur le seul `mtime` du `fs_stat`. Un fichier
lu une fois puis rendu illisible (`chmod`, qui ne change pas `mtime`) continue d'être servi depuis
le cache, sans erreur.

## Pourquoi c'est gênant

Le signalement des suivis illisibles ajouté par `chantier-docs-commands` n'est pas une garantie :
dans une session où le suivi a déjà été lu, la perte de lecture passe inaperçue. Sans effet
pratique sur l'usage visé.

## Pour solder

Tester l'accès en lecture avant de servir le cache (`vim.uv.fs_access(path, "R")`), ou inclure le
mode du `fs_stat` dans la clé de validité.

*Identifié par `implementation-auditor`, R6 du rapport d'audit `chantier-docs-commands`.*

## Assumé

Clôture avec cette réserve, décidée par l'utilisateur le 2026-09-21.
