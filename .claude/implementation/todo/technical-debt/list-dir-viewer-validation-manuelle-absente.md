+++
id = "list-dir-viewer-validation-manuelle-absente"
title = "La validation manuelle du chantier `list-dir-viewer` n'a jamais été faite"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "inverifiable"
+++

## Constat

Le contrôle 3 de la « Vérification d'ensemble » du plan (session Neovim interactive : `:ListDir`,
tri, `<A-o>`, `<CR>` sur un lien) n'a été exécuté à aucun moment, ni pendant le chantier ni lors des
deux audits, qui l'ont tous deux marqué non exécutable en headless. L'utilisateur a choisi de clore
sans.

## Pourquoi c'est gênant

Tout ce qui touche au rendu et aux fenêtres n'a été vérifié que par appel direct des fonctions :
l'attache de markview au document, l'affichage réel de la preview du picker de listes et le
comportement des mappings sous Snacks reposent sur du raisonnement, pas sur une observation.

## Pour solder

Passer une fois la chaîne complète dans une session interactive, sur une vraie liste.

*Identifié par `implementation-auditor`, R8 du rapport d'audit `list-dir-viewer`.*

## Assumé

<OPTIONNEL>
