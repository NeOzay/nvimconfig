+++
id = "todo-sans-readme"
title = "`todo/README.md`, annoncé par l'arborescence du pipeline, n'existe pas"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

L'arborescence de référence du pipeline (`implementation-tracker/references/contrat.md`, section
« Arborescence et nommage ») place un `README.md` à la racine de `todo/`, au-dessus des trois
répertoires-listes. Le chantier `debt-registry-migration` a créé les trois listes et laissé ce
fichier de côté, hors périmètre assumé.

## Pourquoi c'est gênant

`todo/` porte désormais trois répertoires dont les noms seuls ne disent pas la règle qui les
sépare — ce qui entre au registre actif, ce qui passe en soldé, ce qui part en écarté, et le fait
qu'une entrée change de liste au lieu d'être marquée. Un lecteur qui ouvre `todo/` sans connaître
`dette.md` n'a rien qui l'y renvoie.

## Pour solder

Écrire `todo/README.md` : le rôle des trois listes, la règle « l'état est porté par le répertoire,
jamais par un champ », et un renvoi vers `dette.md` plutôt qu'une recopie de ses règles. Attention à
le poser à la racine de `todo/` et non dans une liste — tout `*.md` à la racine d'une liste est
compté comme un élément.

## Assumé

Écarté du périmètre au cadrage, l'utilisateur ayant choisi de limiter le chantier à la migration et
aux gabarits de revue.
