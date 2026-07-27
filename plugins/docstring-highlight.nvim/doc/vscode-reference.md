# Référence : python-docstring-highlighter (VSCode)

Analyse complète du plugin VSCode [python-docstring-highlighter](https://github.com/rodolphebarbanneau/python-docstring-highlighter) v0.2.4.
Focus sur le style **Google** (prioritaire pour notre implémentation).

## Architecture du plugin VSCode

Le plugin utilise **4 fichiers TextMate grammar** injectés dans les docstrings Python :

| Fichier | Scope | Rôle |
|---|---|---|
| `base.tmLanguage.json` | `source.docstring.python` | Éléments communs à tous les formats |
| `google.tmLanguage.json` | `source.docstring.google.python` | Spécifique au style Google |
| `numpy.tmLanguage.json` | `source.docstring.google.numpy` | Spécifique au style NumPy |
| `sphinx.tmLanguage.json` | `source.docstring.google.sphinx` | Spécifique au style Sphinx |

Injection cible : `string.quoted.docstring.multi.python` et `string.quoted.docstring.raw.multi.python`.

**Limitation TextMate** : ne supporte que le matching single-line (pas de patterns multi-lignes).

---

## Éléments de base (base.tmLanguage.json)

Ces éléments sont communs à tous les formats de docstring.

### 1. Section Heading

**Scope** : `docstring.heading.python`

**Regex** : `(?:^\s*)()(_*(?:[A-Z]\w*(?:\s+(?!$))?)+)(:?$)`

**Décomposition** :
- `(?:^\s*)` — début de ligne + indentation optionnelle
- `()` — capture 1 vide (begin, pour cohérence)
- `(_*(?:[A-Z]\w*(?:\s+(?!$))?)+)` — capture 2 : un ou plusieurs mots commençant par majuscule, optionnellement préfixés par `_`, séparés par espaces (mais pas espace en fin de ligne)
- `(:?$)` — capture 3 : deux-points optionnel en fin de ligne

**Captures** :
| Groupe | Scope | Rôle |
|---|---|---|
| 2 (placeholder) | `constant.character.escape.docstring.python` | Le texte du heading |
| 3 (end) | `punctuation.definition.tag.end.docstring.python` | Le `:` final |

**Exemples matchés** :
```
Args:
Returns:
Raises:
See Also:
Other Parameters:
Keyword Arguments:
_Private Section:
```

**Exemples NON matchés** :
```
args:          (minuscule)
ARGS:          (pas CamelCase mais UPPER — marche car [A-Z]\w*)
some text      (pas de : final, mais `:?` rend optionnel — attention)
```

**Note** : Ce pattern est très générique — il matche tout mot capitalisé en début de ligne suivi d'un `:`. Il ne se limite PAS à une liste de mots-clés. Notre plugin utilise une liste fermée de mots-clés, ce qui est plus précis.

---

### 2. Section Separator

**Scope** : `docstring.separator.python`

**Regex** : `(?:^\s*)(=|-){3,}(?:$)`

**Matche** : lignes composées de 3+ signes `=` ou `-` (style NumPy).

**Exemples** :
```
----------
==========
---
```

**Highlight group suggéré** : `DocstringSeparator`

---

### 3. Directive RST

**Scope** : `docstring.directive.python`

**Regex** : `(?:^\s*)(\.\.\s)([\s\w]+)(:+)`

**Décomposition** :
- `(?:^\s*)` — début de ligne + indentation
- `(\.\.\s)` — capture 1 : `.. ` (deux points + espace)
- `([\s\w]+)` — capture 2 : nom de la directive (lettres, chiffres, espaces)
- `(:+)` — capture 3 : un ou plusieurs `:`

**Captures** :
| Groupe | Scope | Rôle |
|---|---|---|
| 1 (begin) | `punctuation.definition.tag.begin` | `.. ` |
| 2 (placeholder) | `constant.character.escape` | Nom de la directive |
| 3 (end) | `punctuation.definition.tag.end` | `::` |

**Exemples** :
```
.. note::
.. warning::
.. todo::
.. deprecated::
.. seealso::
.. versionadded::
.. versionchanged::
.. _Google Python Style Guide:
```

**Highlight group suggéré** : `DocstringDirective`

---

### 4. Inline Literal (double backticks)

**Scope** : `docstring.literal.python`

**Regex** : ` (``)([^`]+)(``) `

**Matche** : contenu entre doubles backticks ` `` `. C'est le format RST standard pour les literals inline.

**Captures** :
| Groupe | Scope | Rôle |
|---|---|---|
| 1 (begin) | `punctuation.definition.tag.begin` | ` `` ` |
| 2 (placeholder) | `constant.character.escape` | Le contenu |
| 3 (end) | `punctuation.definition.tag.end` | ` `` ` |

**Exemples** :
```
the ``Args`` section
use ``sphinx.ext.todo`` extension
``napoleon_include_special_with_doc``
```

**Highlight group suggéré** : `DocstringLiteral` (distinct de `DocstringInlineCode` pour les simples backticks)

---

### 5. Interpreted Text — Cross-references avec rôle

4 catégories de cross-references, chacune avec un rôle RST (`:role:`) suivi d'un texte entre backticks.

#### 5a. Function references

**Scope** : `docstring.snippet.function.python`

**Regex** : `(:func:|:meth:)(`[^`]+`)`

**Matche** : `:func:` ou `:meth:` suivi de `` `nom` ``

**Captures** :
| Partie | Scope | Rôle |
|---|---|---|
| Identifiant (`:func:`) | `entity.name.tag` | Le rôle RST |
| Backtick contenu | `entity.name.function` | Le nom de fonction/méthode |

**Exemples** :
```
:meth:`__init__`
:func:`my_function`
:meth:`ExampleClass.method`
```

**Highlight group suggéré** : `DocstringRefFunction`

#### 5b. Type references

**Scope** : `docstring.snippet.type.python`

**Regex** : `(:class:|:exc:|:mod:|:obj:)(`[^`]+`)`

**Rôles** : `:class:`, `:exc:`, `:mod:`, `:obj:`

**Exemples** :
```
:class:`ExampleClass`
:obj:`list`
:exc:`ValueError`
:mod:`os.path`
```

**Highlight group suggéré** : `DocstringRefType`

#### 5c. Variable references

**Scope** : `docstring.snippet.variable.python`

**Regex** : `(:attr:|:const:|:param:|:paramref:)(`[^`]+`)`

**Rôles** : `:attr:`, `:const:`, `:param:`, `:paramref:`

**Exemples** :
```
:attr:`self.name`
:param:`param1`
:const:`MAX_SIZE`
```

**Highlight group suggéré** : `DocstringRefVariable`

#### 5d. Other references (catch-all)

**Scope** : `docstring.snippet.other.python`

**Regex** : `(:\w*:)(`[^`]+`)`

**Matche** : tout rôle RST non capturé par les catégories précédentes.

**Exemples** :
```
:ref:`some-label`
:doc:`guide`
:data:`sys.path`
:type:`int`
```

**Highlight group suggéré** : `DocstringRefOther`

---

### 6. Interpreted Text — Simple (sans rôle)

**Scope** : `docstring.snippet.python`

**Regex** : `(?:^|[^:])(`)([^`]+)(`_?)`

**Décomposition** :
- `(?:^|[^:])` — pas précédé de `:` (pour éviter de matcher les cross-references)
- `(`)` — backtick ouvrant
- `([^`]+)` — contenu
- `(`_?)` — backtick fermant + `_` optionnel (lien RST)

**Exemples** :
```
`param1`
`PEP 484`_
`n` - 1
`self`
`Google Python Style Guide`_
```

**Note** : C'est l'équivalent de notre `DocstringInlineCode` actuel.

**Highlight group** : `DocstringInlineCode` (déjà implémenté)

---

## Éléments Google (google.tmLanguage.json)

### 7. Variable / Paramètre (Google style)

**Scope** : `docstring.variable.google.python`

**Regex** : `(?:^\s*)((?:-\s*)?)((?:\*\*|\*)?[a-zA-Z_]\w*(?:\[.*\])?)((?\s\(.*\))?:)(?=\s)`

**Décomposition** :
- `(?:^\s*)` — début de ligne + indentation
- `((?:-\s*)?)` — capture 1 : tiret optionnel + espace (pour listes)
- `((?:\*\*|\*)?[a-zA-Z_]\w*(?:\[.*\])?)` — capture 2 : nom du paramètre
  - `(?:\*\*|\*)?` — préfixe `*` ou `**` optionnel (pour `*args`, `**kwargs`)
  - `[a-zA-Z_]\w*` — nom d'identifiant Python
  - `(?:\[.*\])?` — subscript optionnel (ex: `param[0]`)
- `((?:\s\(.*\))?:)` — capture 3 : type entre parenthèses optionnel + `:`
  - `(?:\s\(.*\))?` — espace + `(type)` optionnel
  - `:` — deux-points obligatoire
- `(?=\s)` — suivi d'un espace (lookahead)

**Captures** :
| Groupe | Scope | Rôle |
|---|---|---|
| 1 (begin) | `punctuation.definition.tag.begin` | Tiret optionnel |
| 2 (placeholder) | `entity.name.variable` | Nom du paramètre |
| 3 (end) | `punctuation.definition.tag.end` | `(type):` ou `:` |

**Exemples matchés** :
```
    param1 (int): Description          → param="param1", type="(int)"
    param2 (Optional[str]): Desc       → param="param2", type="(Optional[str])"
    *args: Description                 → param="*args", type=none
    **kwargs: Description              → param="**kwargs", type=none
    param3 (List[str]): Description    → param="param3", type="(List[str])"
    msg (str): Description             → param="msg", type="(str)"
    attr1 (str): Description           → param="attr1", type="(str)"
    - item: Description                → tiret="-", param="item"
    n (int): Description               → param="n", type="(int)"
```

**Note importante** : Le plugin VSCode met le type (incluant les parenthèses et le `:`) dans la capture 3 (end/punctuation), pas dans une capture séparée pour le type. C'est un choix de design — le type est coloré comme "ponctuation" et non comme un élément sémantique distinct.

Notre plugin actuel sépare correctement le param et le type en deux highlight groups distincts (`DocstringParam` et `DocstringType`), ce qui est **mieux** que le plugin VSCode.

**Highlight groups** : `DocstringParam` + `DocstringType` (déjà implémentés)

---

### 8. Inline Type (Google style)

**Scope** : `docstring.type.google.python`

**Regex** : `(?<="{3}|'{3})()([^\s:]+)(:)(?=\s)`

**Décomposition** :
- `(?<="{3}|'{3})` — lookbehind : juste après `"""` ou `'''`
- `()` — capture 1 vide
- `([^\s:]+)` — capture 2 : le type (pas d'espaces ni de `:`)
- `(:)` — capture 3 : deux-points
- `(?=\s)` — suivi d'un espace

**Matche** : le type sur la première ligne d'un docstring inline (juste après les triples quotes).

**Exemples** :
```python
"""int: Module level variable documented inline."""
"""str: Properties should be documented in their getter method."""
"""str: Docstring *after* attribute, with type specified."""
```

**Highlight group suggéré** : `DocstringType`

---

## Récapitulatif : tous les éléments à implémenter

### Priorité 1 — Déjà implémentés (Google style)

| # | Élément | HG actuel | Status |
|---|---|---|---|
| 1 | Section headings | `DocstringSection` | OK |
| 7 | Params + types (Google) | `DocstringParam` + `DocstringType` | OK |
| 6 | Inline code (simple backtick) | `DocstringInlineCode` | OK |

### Priorité 2 — Éléments base manquants (focus Google)

| # | Élément | HG suggéré | Regex (adaptée Lua) | Difficulté |
|---|---|---|---|---|
| 3 | Directives RST | `DocstringDirective` | `^%s*%.%.%s[%s%w]+:+` | Facile |
| 4 | Inline literal (``) | `DocstringLiteral` | ` `` `` ` avec captures | Facile |
| 5a | Ref function (`:meth:`, `:func:`) | `DocstringRefFunction` | `:func:\|:meth:` + backtick | Moyen |
| 5b | Ref type (`:class:`, `:exc:`, etc.) | `DocstringRefType` | `:class:\|:exc:\|:mod:\|:obj:` + backtick | Moyen |
| 5c | Ref variable (`:attr:`, `:param:`, etc.) | `DocstringRefVariable` | `:attr:\|:const:\|:param:\|:paramref:` + backtick | Moyen |
| 5d | Ref other (catch-all) | `DocstringRefOther` | `:%w+:` + backtick | Moyen |
| 8 | Inline type (Google, après `"""`) | `DocstringType` | Lookbehind après triple-quote | Moyen |
| 2 | Section separator | `DocstringSeparator` | `^%s*[=-][=-][=-]+$` | Facile |

### Priorité 3 — Simplification possible des highlight groups

Le plugin VSCode utilise beaucoup de scopes granulaires. Pour notre plugin, on peut simplifier :

| VSCode scopes | Notre HG | Couleur suggérée |
|---|---|---|
| `docstring.heading` | `DocstringSection` | Orange, bold |
| `docstring.directive` | `DocstringDirective` | Orange (comme sections) |
| `docstring.literal` | `DocstringLiteral` | Vert (comme inline code) |
| `docstring.snippet.function` | `DocstringRefFunction` | Jaune/gold |
| `docstring.snippet.type` | `DocstringRefType` | Cyan italic |
| `docstring.snippet.variable` | `DocstringRefVariable` | Cyan |
| `docstring.snippet.other` | `DocstringRefOther` | Gris clair |
| `docstring.snippet` (simple backtick) | `DocstringInlineCode` | Vert |
| `docstring.variable.google` | `DocstringParam` | Cyan |
| `docstring.type.google` | `DocstringType` | Cyan italic |
| `docstring.separator` | `DocstringSeparator` | Gris/dim |
| `docstring.identifier` (`:role:`) | `DocstringIdentifier` | Gris/dim |

**Alternative minimaliste** : regrouper les cross-references en un seul HG `DocstringRef` avec sous-parties `DocstringRefRole` (le `:meth:`) et `DocstringRefContent` (le `` `nom` ``).

---

## Exemples concrets extraits du fichier test Google

```python
# Heading
"""Example module with Google style docstrings.
    # ↑ pas de heading (pas de majuscule en début de mot isolé avec :)

Attributes:
    # ↑ HEADING — "Attributes:"

See Also:
    # ↑ HEADING — "See Also:" (multi-mots)

.. todo::
    # ↑ DIRECTIVE — ".." = begin, "todo" = placeholder, "::" = end

    module_level_variable1 (int): Module level variables...
    # ↑ VARIABLE GOOGLE — param="module_level_variable1", type="(int)"

    ``Attributes``
    # ↑ LITERAL — contenu="Attributes"

    `Extension Documentation`_
    # ↑ SNIPPET (interpreted text avec lien) — contenu="Extension Documentation"
"""

def function_with_types_in_docstring(param1, param2, param3):
    """Example function with types documented in the docstring.

    Args:
        # ↑ HEADING
        param1 (int): The first parameter.
        # ↑ VARIABLE GOOGLE — param="param1", type="(int)"
        param2 (int): The second parameter.
        param3 (str): The third parameter.

    Returns:
        # ↑ HEADING
        bool: The return value.
        # ↑ INLINE TYPE GOOGLE (après début de section Returns)
    """

class ExampleError(Exception):
    """The :meth:`__init__` method may be documented...
    #      ↑ REF FUNCTION — role=":meth:", content="__init__"

    Note:
        # ↑ HEADING
        Do not include the `self` parameter in the ``Args`` section.
        #                   ↑ SNIPPET          ↑ LITERAL
    """

class ExampleClass(object):
    @property
    def readonly_property(self):
        """str: Properties should be documented in their getter method."""
        # ↑ INLINE TYPE GOOGLE — type="str" (juste après """)

    @property
    def readwrite_property(self):
        """:obj:`list` of :obj:`str`: Properties with both...
        #  ↑ REF TYPE   ↑ REF TYPE
        """
```

---

## Notes d'implémentation

### Ordre d'évaluation des patterns

Le plugin VSCode applique les patterns dans l'ordre de déclaration. Les patterns spécifiques (cross-references avec rôle) sont évalués AVANT le pattern générique (interpreted text simple). Notre `highlight_line()` devrait respecter le même ordre :

1. Section heading (le plus prioritaire)
2. Directive RST
3. Inline literal (``)
4. Cross-references avec rôle (`:meth:`, `:class:`, etc.)
5. Cross-references catch-all (`:any:`)
6. Inline code simple (backtick)
7. Variable/param Google
8. Inline type Google

### Gestion des conflits

Quand un pattern matche, les autres ne doivent PAS matcher la même portion de texte. Le plugin VSCode gère ça via l'ordre des patterns TextMate. Dans notre plugin, on doit tracker les ranges déjà highlightés et les ignorer pour les patterns suivants, OU utiliser des patterns exclusifs (non-overlapping).

### Inline type Google — cas spécial

Le pattern `(?<="{3}|'{3})([^\s:]+)(:)` nécessite un lookbehind pour détecter qu'on est juste après les triple-quotes. En Lua/Neovim, on peut :
- Vérifier si la ligne est la PREMIÈRE ligne d'une docstring
- ET si elle contient un pattern `^[^\s:]+:%s` en début de contenu

Cela concerne les docstrings inline d'attributs et properties.
