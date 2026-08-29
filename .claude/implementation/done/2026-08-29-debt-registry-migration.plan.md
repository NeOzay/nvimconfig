# Migrer le registre de dette vers le format répertoire-liste

## Contexte

`.claude/implementation/todo/technical-debt.md` est un fichier Markdown unique portant 13 entrées de
dette, issues des audits de clôture de `tts-piper` (8) et `list-dir-viewer` (5).

Toute la documentation du pipeline décrit pourtant un autre dispositif — trois répertoires-listes
manipulés par le skill `list-dir` — et parle du fichier unique **au passé**. `dette.md` :
« L'ancien registre portait **une** ligne "Dernière vérification" en tête de fichier. Elle a disparu
avec le fichier unique ». `contrat.md` dessine l'arborescence avec les trois répertoires. La
documentation a été écrite en avance sur le dépôt.

Conséquence mesurée : `/debt-review` est inexécutable. Son Étape 0 rend
`répertoire introuvable` sur les trois listes, et son Étape 0 ordonne alors de s'arrêter — « Ce
skill relit un registre existant ; il n'en crée pas ».

Ce chantier crée le registre au format attendu, sans perdre d'entrée et sans juger aucune dette. La
revue est une passe séparée, qui viendra après.

## Ce que ce chantier ne fait pas

Repris du brief, et à tenir pendant toute l'exécution :

- **aucun code corrigé** — pas une ligne dans `plugins/` ni `lua/`
- **aucune entrée soldée, écartée ou classée** — pas de `move`, pas de `category`, pas de
  `reviewed`. Les deux listes sœurs (`-solde`, `-ecarte`) sont créées vides et le restent. *Le
  brief écrit « les trois listes sœurs » : c'est un lapsus, le registre actif reçoit les 13
  entrées. Signalé plutôt que corrigé — un brief validé ne se réécrit pas.*
- pas de `todo/README.md`
- le champ `source` reste au marqueur ; la ligne « *Identifié par `implementation-auditor`,
  R<n>…* » reste dans le corps de chaque entrée

## Préalables établis pendant le cadrage

```bash
L="$HOME/.claude/skills/list-dir/scripts/list-dir.py"
T=".claude/implementation/todo"
```

- Les **sept catégories**, en ASCII kebab-case, lues dans `debt-review/references/categories.md` et
  confirmées par la boucle d'affichage des piles de son Étape 3 : `a-solder`, `non-pertinent`,
  `doublon`, `pas-une-dette`, `aggravee`, `pertinent`, `inverifiable`.
- `init` écrit un contrat **squelette** minimal (`store.py`, `init_list` : un `id`, un `title`, une
  section `Constat`). Il est ensuite complété à la main — c'est prévu, et le contrat n'est pas un
  élément de liste : la règle « aucun fichier créé ni renommé à la main » porte sur les entrées.
- **`derive` copie le corps du gabarit `.md` verbatim** (`store.py`, `_project` : `dict(gabarit)`).
  Le gabarit doit donc porter lui-même les marqueurs `<À REMPLIR>` / `<OPTIONNEL>` sous chaque
  titre ; `parse_sections` ignore tout ce qui précède le premier `##`.
- **`derive` refuse une liste source vide** (`store.py` : « aucun élément — il n'y a rien à
  projeter »). La vérification du gabarit de revue doit donc venir **après** la migration des
  entrées, pas avant.
- Les **11** fichiers distincts cités par les 13 entrées existent tous encore dans le dépôt — la
  réécriture des repères a donc une cible à citer dans chaque cas sauf un (voir ci-dessous).
- L'un d'eux, `plugins/tts.nvim/LICENSE`, **n'a pas d'extension** : un contrôle anti-repère filtré
  sur `\.(lua|py|md)` manquerait `LICENSE:27`. Le contrôle retenu est celui du brief, sans filtre
  d'extension.
- La source porte ses rubriques en **gras** (`**Constat**`), pas en titres. La reprise « verbatim »
  porte donc sur le texte : les étiquettes deviennent les titres `##` qu'exige le contrat.

## Étapes

### 1. Créer les trois répertoires-listes et leurs contrats

`init` sur les trois, puis complétion de chaque `contract.toml`.

`technical-debt/` — champs repris de `dette.md`, « Ce qu'une entrée porte » :

```toml
name = "technical-debt"
description = "La dette constatée et non résolue que les chantiers de ce dépôt ont laissée."

[fields.id]
type = "slug"

[fields.title]
type = "text"
required = true
description = "l'énoncé de la dette"

[fields.date]
type = "date"
required = true
description = "date du constat, jamais modifiée"

[fields.source]
type = "text"
required = false
description = "le chantier qui l'a identifiée, et où il l'a écrit"

[fields.reviewed]
type = "date"
required = false
description = "date de la dernière revue qui a statué"

[fields.category]
type = "enum"
required = false
values = ["a-solder", "non-pertinent", "doublon", "pas-une-dette", "aggravee", "pertinent", "inverifiable"]
description = "verdict de la dernière revue"

[sections]
required = ["Constat", "Pourquoi c'est gênant", "Pour solder"]
optional = ["Assumé"]
```

`technical-debt-solde/` et `technical-debt-ecarte/` — mêmes champs, sections différentes.
`dette.md` : elles « exigent en plus `## Soldé le` / `## Écartée le`, et rendent facultatives les
deux du milieu » :

```toml
# solde
[sections]
required = ["Constat", "Soldé le"]
optional = ["Pourquoi c'est gênant", "Pour solder", "Assumé"]

# ecarte
[sections]
required = ["Constat", "Écartée le"]
optional = ["Pourquoi c'est gênant", "Pour solder", "Assumé"]
```

**Vérification**

```bash
for l in technical-debt technical-debt-solde technical-debt-ecarte; do
  python3 "$L" validate "$T/$l" || echo "ÉCHEC : $l"
done
```

`validate` ne suffit pas ici : une liste **sans élément est conforme par construction**, donc cette
boucle passerait à l'identique sur les trois contrats squelettes qu'`init` vient d'écrire. Le
livrable de l'étape étant les trois contrats **complétés**, il faut les relire — script à déposer
dans le scratchpad et à lancer par `python3 <chemin>` :

```python
import sys, os
sys.path.insert(0, os.path.expanduser("~/.claude/skills/list-dir/scripts"))
from listdir import open_list

champs = ["id", "title", "date", "source", "reviewed", "category"]
attendu = {
    "technical-debt":        (["Constat", "Pourquoi c'est gênant", "Pour solder"], ["Assumé"]),
    "technical-debt-solde":  (["Constat", "Soldé le"],
                              ["Pourquoi c'est gênant", "Pour solder", "Assumé"]),
    "technical-debt-ecarte": (["Constat", "Écartée le"],
                              ["Pourquoi c'est gênant", "Pour solder", "Assumé"]),
}
for nom, (req, opt) in attendu.items():
    c = open_list(f".claude/implementation/todo/{nom}").unwrap().contract
    ok = (list(c.fields) == champs
          and c.required_sections == req and c.optional_sections == opt
          and len(c.fields["category"].values) == 7)
    print(("OK   " if ok else "ÉCHEC"), nom)
```

Trois lignes `OK`. Les listes sont vides à ce stade, et c'est légitime au sortir d'`init`.

### 2. Migrer les 8 entrées issues de `tts-piper`

Une entrée = un `python3 "$L" new "$T/technical-debt" <id>`, puis remplissage du fichier créé.

| `id` | `date` | entrée |
|---|---|---|
| `ttsvoice-fige-la-deduction-par-langue` | 2026-08-18 | `:TTSVoice` rend `:TTSSetLanguage` sans effet |
| `text-processor-defauts-upstream` | 2026-08-18 | deux défauts hérités de l'upstream |
| `ttsfile-ecrase-le-meme-fichier` | 2026-08-18 | `:TTSFile` écrase toujours `tts.wav` |
| `license-mentionne-edge-tts` | 2026-08-18 | le LICENSE cite une dépendance supprimée |
| `client-tts-timer-non-arme` | 2026-08-18 | délai de garde non armé si `uv.new_timer()` échoue |
| `verification-etape-2-clause-perdue` | 2026-08-18 | l'étape 2 a perdu une clause du plan |
| `speak-coupe-avant-synthese` | 2026-08-18 | `speak` coupe avant de savoir si la suite aboutit |
| `test-deduction-voix-non-discriminant` | 2026-08-18 | le test ne discrimine que par coïncidence |

**Contenu** : `title`, `date`, et les sections `Constat` / `Pourquoi c'est gênant` / `Pour solder`
reprises **verbatim** du fichier unique — plus `Assumé` pour `speak-coupe-avant-synthese`, la seule
qui en porte une. `source` reste au marqueur `<OPTIONNEL>`, la ligne d'attribution reste dans le
corps.

**Seule transformation** : les repères de ligne. `dette.md` — « Désigner sans numéro de ligne […]
Le repère se périme au premier commit qui insère une ligne au-dessus, sans qu'une commande échoue
et sans que rien ne le signale ». Chaque `fichier:42` devient une citation du **texte** décrit,
prise du rapport d'audit (`done/2026-08-18-tts-piper.audit.md`, section « Qualité du code », qui
nomme les fonctions : `Synthesizer.synthesize` → `self._load`, `dispatch`, `pandoc()`, `save`,
`if timer then`) et confirmée par une lecture du fichier cité.

**Règle pour le cas où la cible a disparu** — ne rien juger, ne rien supprimer : garder la
description sans repère, et noter l'entrée pour la revue. Un cas est déjà connu :
`text-processor-defauts-upstream` décrit deux défauts, et le premier (le motif de lien markdown sans
`%)`) a été corrigé depuis, par le commit `818270d` du 2026-08-23. Le fichier porte aujourd'hui
`text:gsub("%[(.-)%]%((.-)%)", "%1")`. L'entrée est donc à moitié périmée — mais la solder est le
travail de la revue, pas celui-ci.

**Vérification**

```bash
test "$(python3 "$L" list "$T/technical-debt" | wc -l)" -eq 8
python3 "$L" validate "$T/technical-debt" --filled
```

### 3. Migrer les 5 entrées issues de `list-dir-viewer`

Même geste, même règle de citation, rapport d'audit `done/2026-08-29-list-dir-viewer.audit.md`.

| `id` | `date` | entrée |
|---|---|---|
| `listdir-sans-tests` | 2026-08-29 | aucun test, dans un dépôt qui en a le cadre |
| `listdir-cache-document-homonyme` | 2026-08-29 | deux listes homonymes partagent le cache |
| `listdir-front-matter-non-referme` | 2026-08-29 | front matter non refermé lu sans le signaler |
| `list-dir-viewer-validation-manuelle-absente` | 2026-08-29 | la validation manuelle n'a jamais été faite |
| `listdir-decouverte-synchrone` | 2026-08-29 | la découverte bloque l'interface une seconde |

**Vérification**

```bash
test "$(python3 "$L" list "$T/technical-debt" | wc -l)" -eq 13
python3 "$L" validate "$T/technical-debt" --filled

# Le contrôle anti-repère du brief, sans filtre d'extension : `LICENSE:27` doit être attrapé.
# Forme `if`, et non `grep && echo` : ce dernier sort en 1 dans le cas de succès.
if grep -rnE ':[0-9]+' "$T/technical-debt"; then
  echo "À EXAMINER : repère de ligne, ou faux positif légitime (un port, une heure)"
else
  echo "OK : aucun repère"
fi
```

Le motif du brief est volontairement large et peut cueillir un faux positif — un numéro de port
cité dans une prose. Toute ligne remontée se regarde ; aucune ne se supprime sans la regarder.

### 4. Écrire les gabarits de revue et prouver que `/debt-review` peut tourner

Deux fichiers sous `$T/technical-debt/.list/templates/`, forme dictée par
`debt-review/references/gabarit-rapport.md`.

`review.toml` — `title` et `date` reportés par `from`, `reviewed` et `category` requis et laissés au
marqueur :

```toml
name = "revue"
description = "Un verdict par entrée du registre de dette, pour une passe de revue."

[fields.id]
type = "slug"

[fields.title]
type = "text"
required = true
from = "title"

[fields.date]
type = "date"
required = true
from = "date"
description = "date du constat, reportée de l'entrée"

[fields.reviewed]
type = "date"
required = true
description = "date de cette revue, jamais celle du constat"

[fields.category]
type = "enum"
required = true
values = ["a-solder", "non-pertinent", "doublon", "pas-une-dette", "aggravee", "pertinent", "inverifiable"]

[sections]
required = ["Vérifié par", "Verdict", "Action"]
optional = ["Arbitrage"]
```

`review.md` — les marqueurs sont **dans le gabarit**, puisque `derive` recopie le corps tel quel :

```markdown
## Vérifié par

<À REMPLIR>

## Verdict

<À REMPLIR>

## Action

<À REMPLIR>

## Arbitrage

<OPTIONNEL>
```

**Vérification** — rejouer l'Étape 1 de `debt-review` sur une destination jetable, hors du dépôt :

```bash
T2="$(mktemp -d)/revue-test"
python3 "$L" derive "$T/technical-debt" "$T2" --template review
python3 "$L" validate "$T2"
test "$(python3 "$L" list "$T2" | wc -l)" -eq 13
rm -rf "$(dirname "$T2")"
```

### 5. Retirer l'ancien fichier et contrôler la conservation

```bash
git rm "$T/technical-debt.md"
```

**Vérification finale**

```bash
for l in technical-debt technical-debt-solde technical-debt-ecarte; do
  printf '%-26s %s\n' "$l" "$(python3 "$L" list "$T/$l" | wc -l)"
done                                             # 13, 0, 0
python3 "$L" validate "$T/technical-debt" --filled

if grep -rnE ':[0-9]+' "$T/technical-debt"; then
  echo "À EXAMINER : repère de ligne, ou faux positif légitime"
else
  echo "OK : aucun repère"
fi

# `.claude/plans/` est admis : le fichier de plan est un livrable de ce chantier, commité avec le
# suivi (tracker, Étape 2 — « Le plan doit être versionné »).
if git status --short | grep -vE '^.. \.claude/(implementation|plans)/'; then
  echo "ÉCHEC : fichier hors périmètre"
else
  echo "OK : rien hors de .claude/"
fi
```

## Vérification d'ensemble

1. Les trois listes valident, le registre valide en `--filled`, il porte 13 entrées.
2. Aucun repère de ligne ne subsiste dans le registre.
3. `derive --template review` produit 13 fiches conformes : `/debt-review` est exécutable.
4. `git status --short` ne liste que des chemins sous `.claude/` — `implementation/` pour le
   registre, le brief et le suivi, `plans/` pour le fichier de plan que le tracker exige de
   versionner. Le critère du brief dit « sous `.claude/implementation/` » ; il a été écrit avant que
   le plan mode n'assigne son fichier, et `.claude/plans/` s'y ajoute pour cette raison.
5. Le contenu est conservé : les 13 titres du registre correspondent aux 13 titres `## ` de
   l'ancien fichier, à comparer sur la version Git de `technical-debt.md` avant suppression.

## Hand-off à la revue

Ce que la migration aura constaté sans y toucher, et qui revient à `/debt-review` :
`text-processor-defauts-upstream`, dont le premier des deux défauts est corrigé depuis le commit
`818270d`. Toute autre entrée dont la cible se révèle introuvable pendant l'étape 2 ou 3 s'ajoute à
cette liste.
