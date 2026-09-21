+++
id = "chantier-find-suivi-retour-union"
title = "`find_suivi` rend les données du suivi ou la liste d'erreurs dans le même retour"
date = 2026-09-21
source = "chantier-docs-commands, rapport .claude/implementation/done/2026-09-21-chantier-docs-commands.audit.md"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

Dans `lua/chantier.lua`, `find_suivi` rend en second retour soit les données du suivi trouvé, soit
la liste des erreurs de lecture (`Ozay.Frontmatter.Data|string[]`) ; `M.open` départage par deux
`---@cast` selon que le premier retour est nil. Correct à l'exécution, sans diagnostic
`emmylua_ls`.

## Pourquoi c'est gênant

Le type ne dit plus laquelle des deux valeurs on tient : une modification qui lirait
`data.fields` hors de la branche « suivi trouvé » passerait l'analyse sans alerte, et
planterait à l'exécution sur une liste d'erreurs.

## Pour solder

Rendre les erreurs dans un troisième retour dédié, chaque valeur gardant un seul type, et retirer
les `---@cast`.

*Identifié par `implementation-auditor`, R5 du rapport d'audit `chantier-docs-commands`.*

## Assumé

Clôture avec cette réserve, décidée par l'utilisateur le 2026-09-21.
