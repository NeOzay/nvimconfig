+++
id = "registre-fenetre-non-conforme-pendant-un-solde"
title = "Un solde laisse la liste de destination non conforme entre ses deux commits"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "pertinent"
+++

## Constat

Solder une entrée impose deux commits séparés — `move` d'abord, `## Soldé le` ensuite — pour que la
détection de renommage de Git tienne (`dette.md`, « Solder »). Or le contrat de
`technical-debt-solde/` exige la section `Soldé le`. Entre les deux commits, la liste de destination
est donc non conforme, et le contrôle de conservation de `debt-review` Étape 6, qui lance
`validate`, échouerait à cet instant précis. Rejoué hors dépôt à l'audit : `move` rend `rc=0` en
avertissant que la section manque.

## Pourquoi c'est gênant

Deux exigences du dispositif se contredisent sur une fenêtre courte mais réelle. Le premier solde
rencontrera l'avertissement sans que rien ne dise s'il faut s'en inquiéter, et une revue interrompue
entre les deux commits laisse un registre que `validate` refuse.

## Pour solder

Trancher explicitement dans `dette.md` : soit dire que la fenêtre est attendue et que le contrôle de
l'Étape 6 se lance après le second commit, soit rendre `Soldé le` facultative au contrat et n'exiger
son remplissage qu'à la revue suivante.

## Assumé

Le dispositif est cohérent — l'outil prévient plutôt que d'échouer en silence. C'est la
documentation qui est muette sur l'état intermédiaire. Relevé par `implementation-auditor`, R3 du
rapport d'audit `debt-registry-migration`.
