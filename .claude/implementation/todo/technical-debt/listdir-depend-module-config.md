+++
id = "listdir-depend-module-config"
title = "Le plugin local `listdir` dépend du module `frontmatter` de la config"
date = 2026-09-21
source = "chantier-docs-commands, rapport .claude/implementation/done/2026-09-21-chantier-docs-commands.audit.md"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`plugins/listdir/lua/listdir/item.lua` fait `require("frontmatter")`, un module de premier niveau
de la config (`lua/frontmatter.lua`), extrait par le chantier `chantier-docs-commands` pour être
partagé avec `lua/chantier.lua`. Le plugin, structuré comme un plugin autonome, ne se charge plus
hors de cette config.

## Pourquoi c'est gênant

Sortir ou publier `listdir` oblige à ré-internaliser le parseur. Et `frontmatter` est un nom
générique dans l'espace global des modules Lua : un plugin tiers livrant un
`lua/frontmatter.lua` le masquerait selon l'ordre du `runtimepath`, sans erreur au chargement.

## Pour solder

Déplacer le parseur sous un espace de noms propre (`ozay.frontmatter`, ou un plugin local dédié
sous `plugins/`), ou le rapatrier dans `listdir` si le plugin doit redevenir autonome.

*Identifié par `implementation-auditor`, R3 du rapport d'audit `chantier-docs-commands`.*

## Assumé

Décision du journal du chantier (2026-09-21) : module commun voulu par l'utilisateur, `listdir`
n'étant utilisé que dans cette config ; un plugin dédié a été jugé disproportionné.
