+++
id = "lexique-curseur-casse-change-longueur"
title = "`<leader>L` rate le terme sous le curseur quand la mise en minuscules change la longueur de la ligne"
date = 2026-09-27
severite = "inconnue"
chantier = "integrer-commande-lexique"
reference = "R9"
pin = false
source = "integrer-commande-lexique, R9 du rapport .claude/implementation/done/2026-09-27-integrer-commande-lexique.audit.md"
reviewed = "<OPTIONNEL date>"
category = "<OPTIONNEL>"
+++

## Constat

`covering()` de `lua/lexique.lua` cherche les termes dans `vim.fn.tolower(line)` mais compare les
positions trouvées à la colonne du curseur prise dans la ligne d'origine. Un caractère dont la
minuscule n'a pas la même longueur en octets (ẞ → ß, Ⱥ → ⱥ) décale tout ce qui le suit.

Établi par : audit de clôture de `integrer-commande-lexique` (`a329898`) — sur « ẞ Signal de
dérive », curseur sur le dernier octet de « dérive », `at_cursor()` répond « aucun terme du
lexique sous le curseur » ; sur « X Signal de dérive », il rend la définition.

## Pourquoi c'est gênant

Le mappage conclut à l'absence d'un terme bien présent : l'utilisateur croit le terme hors du
lexique. Marginal — il faut un de ces caractères avant le terme sur la même ligne.

## Pour solder

Comparer des positions prises dans la même chaîne : chercher sans changer la longueur (motif
insensible à la casse lettre par lettre), ou convertir la colonne du curseur vers la ligne en
minuscules. Vérifier par un cas mini.test « ẞ Signal de dérive », curseur en fin de « dérive ».

## Assumé

Reporté à la clôture de `integrer-commande-lexique` : aucun critère ne visait ce cas, et un
correctif aurait demandé un quatrième audit.
