+++
id = "registre-fenetre-non-conforme-pendant-un-solde"
title = "Un solde laisse la liste de destination non conforme entre ses deux commits"
date = 2026-08-29
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

Rejoué dans un dépôt jetable, avec les contrats réels de ce registre — une entrée déplacée vers la
liste des soldes, puis `validate` immédiatement après, comme le ferait l'Étape 6 d'une revue
interrompue entre les deux commits :

```
$ python3 "$L" move a todo-sans-readme b
déplacé. Le contrat de b demande encore :
  section « Soldé le » — manquante
Les compléter demande un SECOND commit : ce commit-ci doit rester un renommage pur, sinon git perd
la trace de l'élément.
b/todo-sans-readme.md

$ python3 "$L" validate b ; echo "rc=$?"
b/todo-sans-readme.md: section « Soldé le » — manquante

b : 1 manquement
rc=1
```

## Verdict

Le constat tient, et il est mesuré plutôt que raisonné : `move` réussit, la destination est
immédiatement non conforme, et `validate` sort en 1. Le contrôle de conservation de l'Étape 6, qui
lance `validate`, échouerait donc sur une revue interrompue entre le commit de déplacement et celui
de la preuve.

`pertinent`, et non `pas-une-dette` : la contradiction entre deux exigences écrites du dispositif
(« `Soldé le` est requise au contrat » et « le déplacement ne partage jamais son commit avec
l'écriture ») est vérifiable, et la documentation ne dit nulle part que cet état intermédiaire est
attendu.

Le dispositif reste sain sur un point important, qu'il faut porter à son crédit : `move` **avertit
explicitement** de ce qui manque et rappelle la règle du second commit. L'échec n'est pas
silencieux — c'est ce qui distingue une dette de documentation d'un défaut de conception.

## Action

Reste au registre avec ses deux champs de revue. Le **Pour solder** propose deux issues exclusives
(documenter la fenêtre, ou rendre `Soldé le` facultative) : c'est un arbitrage à rendre, pas un
correctif à appliquer — et il touche `dette.md`, donc le pipeline, pas ce dépôt.

## Arbitrage

<OPTIONNEL>
