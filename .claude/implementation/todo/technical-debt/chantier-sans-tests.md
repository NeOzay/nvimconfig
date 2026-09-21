+++
id = "chantier-sans-tests"
title = "`:Suivi`, `:Brief`, `:Plan`, `:Audit` n'ont aucun test persistant"
date = 2026-09-21
source = "chantier-docs-commands, rapport .claude/implementation/done/2026-09-21-chantier-docs-commands.audit.md"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

`lua/chantier.lua` n'est couvert que par des scripts headless jetables, écrits pendant le chantier
hors du dépôt. Celui de l'étape 2 du plan contrôlait seulement l'absence de buffer, pas la présence
du message exigé par les critères du brief ; les messages n'ont été vérifiés que par les scripts de
l'auditeur, eux aussi jetés. Le dépôt dispose pourtant d'un cadre MiniTest (`tests/`, cible
`make test`).

## Pourquoi c'est gênant

Une régression sur un chemin d'erreur — message perdu, buffer ouvert à tort — passerait sans bruit :
la seule vérification réutilisable n'en regarde que la moitié, et elle n'est pas versionnée.

## Pour solder

Un `tests/chantier/` qui monte un dépôt temporaire et vérifie, pour chaque cas (ouverture, champ
vide ou `<À REMPLIR>`, fichier absent, `master`, branche sans suivi, leurre dans `done/`, HEAD
détachée, suivi illisible), à la fois le buffer courant et le message notifié.

*Identifié par `implementation-auditor`, R4 du rapport d'audit `chantier-docs-commands`.*

## Assumé

Clôture avec cette réserve, décidée par l'utilisateur le 2026-09-21.
