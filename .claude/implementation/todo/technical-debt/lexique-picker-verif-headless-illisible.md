+++
id = "lexique-picker-verif-headless-illisible"
title = "La vérification headless du picker lexique mêle son décompte au log ClaudeCode"
date = 2026-09-27
source = "integrer-commande-lexique, R8 du rapport .claude/implementation/done/2026-09-27-integrer-commande-lexique.audit.md"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

La commande headless qui compte les items du picker (`docs/plugins/snacks.md`, Gotchas, et le
plan archivé de `integrer-commande-lexique`, étape 4) se lit par `tail -1` : le nombre sort collé
à la ligne de log `[ClaudeCode] [init] [INFO] Claude Code integration stopped`, soit
`19[ClaudeCode] …`.

Établi par : les deuxième et troisième audits de clôture de `integrer-commande-lexique`
(`7ab2063`, `a329898`).

## Pourquoi c'est gênant

Le critère « > 0 » se juge à l'œil, non par la commande : la même fragilité avait fait échouer la
version précédente de cette vérification (R1). Une vérification qu'on ne peut pas lire
mécaniquement ne s'automatise pas.

## Pour solder

Préfixer le décompte et l'extraire : `print("items=" .. …)` puis `grep -o 'items=[0-9]*'`, dans
`docs/plugins/snacks.md`. Vérifier que la commande rend `items=19` depuis `~/.config/nvim`.

## Assumé

Reporté à la clôture de `integrer-commande-lexique` : la commande établit le critère, seule sa
lecture est fragile.
