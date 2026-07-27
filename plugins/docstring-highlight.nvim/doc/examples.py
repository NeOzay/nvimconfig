# doc/examples.py — Fichier de test pour docstring-highlight.nvim
# Couvre : sections, params+types, params sans type, inline code, cas limites


# ── 1. Fonction simple avec Args + Returns ────────────────────────────────────


def add(a, b):
    """Additionne deux nombres.

    Args:
        a (int): Premier opérande.
        b (int): Second opérande.

    Returns:
        int: La somme de `a` et `b`.
    """
    return a + b


# ── 2. Params sans type (indent ≥ 4) ─────────────────────────────────────────


def greet(name, loud):
    """Génère un message de salutation.

    Args:
        name: Nom de la personne à saluer.
        loud: Si True, le message est en majuscules.

    Returns:
        Chaîne de salutation formatée.
    """
    msg = f"Hello, {name}!"
    return msg.upper() if loud else msg


# ── 3. Raises + types complexes ───────────────────────────────────────────────


def divide(numerator, denominator):
    """Divise deux nombres réels.

    Args:
        numerator (float): Le dividende.
        denominator (float): Le diviseur, doit être non nul.

    Returns:
        float: Résultat de la division.

    Raises:
        ValueError: Si `denominator` vaut zéro.
        TypeError: Si l'un des arguments n'est pas un nombre.
    """
    if denominator == 0:
        raise ValueError("denominator must not be zero")
    return numerator / denominator


# ── 4. Section Attributes (classe) ───────────────────────────────────────────


class Config:
    """Configuration globale de l'application.

    Attributes:
        debug (bool): Active les logs de débogage.
        max_retries (int): Nombre maximal de tentatives.
        timeout (float): Délai d'attente en secondes.
        name (str): Identifiant lisible de la config.
    """

    def __init__(self, debug=False, max_retries=3, timeout=5.0, name="default"):
        self.debug = debug
        self.max_retries = max_retries
        self.timeout = timeout
        self.name = name


# ── 5. Sections Note + Example ────────────────────────────────────────────────


def clamp(value, lo, hi):
    """Contraint `value` dans l'intervalle [lo, hi].

    Args:
        value (float): Valeur à contraindre.
        lo (float): Borne inférieure.
        hi (float): Borne supérieure.

    Returns:
        float: Valeur contrainte.

    Note:
        Si `lo` > `hi`, le comportement est indéfini.

    Example:
        >>> clamp(10, 0, 5)
        5
        >>> clamp(-1, 0, 5)
        0
    """
    return max(lo, min(value, hi))


# ── 6. See Also + References ──────────────────────────────────────────────────


def normalize(vector):
    """Normalise un vecteur à longueur unitaire.

    Args:
        vector (list[float]): Composantes du vecteur.

    Returns:
        list[float]: Vecteur normalisé.

    Raises:
        ValueError: Si le vecteur est nul (norme = 0).

    See Also:
        `dot_product`, `cross_product`

    References:
        Strang, G. — *Linear Algebra and Its Applications*.
    """
    norm = sum(x**2 for x in vector) ** 0.5
    if norm == 0:
        raise ValueError("cannot normalize zero vector")
    return [x / norm for x in vector]


# ── 7. Keyword Args ───────────────────────────────────────────────────────────


def connect(host, port, **kwargs):
    """Établit une connexion TCP.

    Args:
        host (str): Adresse du serveur.
        port (int): Port cible.

    Keyword Args:
        timeout (float): Délai en secondes (défaut : 30).
        retries (int): Tentatives avant abandon (défaut : 3).
        ssl (bool): Activer TLS.

    Returns:
        socket.socket: Socket connecté.

    Raises:
        ConnectionRefusedError: Si le serveur refuse la connexion.
    """
    pass


# ── 8. Yields ────────────────────────────────────────────────────────────────


def read_chunks(path, size=1024):
    """Lit un fichier par blocs.

    Args:
        path (str): Chemin vers le fichier.
        size (int): Taille de chaque bloc en octets.

    Yields:
        bytes: Prochain bloc de données lu.

    Raises:
        FileNotFoundError: Si `path` n'existe pas.
    """
    with open(path, "rb") as f:
        while chunk := f.read(size):
            yield chunk


# ── 9. Inline code abondant ───────────────────────────────────────────────────


def parse_flag(text: str) -> bool:
    """Analyse un flag booléen depuis une chaîne.

    Valeurs truthy : `"true"`, `"yes"`, `"1"`, `"on"`.
    Valeurs falsy  : `"false"`, `"no"`, `"0"`, `"off"`.
    La casse est ignorée (`text.lower()` appliqué).

    Args:
        text (str): Chaîne à analyser.

    Returns:
        result (bool): `True` si truthy, `False` si falsy.

    Raises:
        ValueError: Si `text` ne correspond à aucune valeur reconnue.
    """
    t = text.strip().lower()
    if t in ("true", "yes", "1", "on"):
        return True
    if t in ("false", "no", "0", "off"):
        return False
    raise ValueError(f"unrecognized flag: {text!r}")


# ── 10. Module-level docstring (au niveau module — premier string du fichier
#        serait capturé, mais on le place ici comme string isolée pour tester
#        la query treesitter sur expression_statement > string au toplevel) ───

SENTINEL = """Constante sentinelle non utilisée.

Args:
    Ce n'est pas une fonction, le plugin ne devrait PAS l'annoter.
"""


# ── 11. Docstring one-liner (pas de sections) ─────────────────────────────────


def noop():
    """Ne fait rien."""
    pass


# ── 12. Section Deprecated ────────────────────────────────────────────────────


def old_api(x):
    """Ancienne interface de calcul.

    Deprecated:
        Utiliser `new_api(x)` à la place.
        Sera supprimée en v2.0.

    Args:
        x (int): Valeur d'entrée.

    Returns:
        int: Résultat.
    """
    return x * 2


# ── 13. Section Warnings + Todo ───────────────────────────────────────────────


def experimental_feature(data):
    """Fonctionnalité expérimentale non stable.

    Warnings:
        L'API peut changer sans préavis.
        Ne pas utiliser en production.

    Todo:
        - Ajouter la validation de `data`.
        - Écrire les tests unitaires.
        - Documenter les cas limites.

    Args:
        data (dict): Données d'entrée non validées.

    Returns:
        dict: Données transformées.
    """
    return data


# ── 14. Params avec types complexes (generics, optionnel) ─────────────────────


def merge(base, overrides, strict=False):
    """Fusionne deux dictionnaires récursivement.

    Args:
        base (dict[str, Any]): Dictionnaire de base.
        overrides (dict[str, Any]): Valeurs à appliquer par-dessus.
        strict (bool): Si True, lève une erreur sur les clés inconnues.

    Returns:
        dict[str, Any]: Nouveau dictionnaire fusionné (pas de mutation).

    Raises:
        KeyError: Si `strict` est True et qu'une clé de `overrides`
            n'existe pas dans `base`.
    """
    result = dict(base)
    for k, v in overrides.items():
        if strict and k not in base:
            raise KeyError(k)
        result[k] = v
    return result


# ── 15. Méthode de classe avec self ──────────────────────────────────────────


class Pipeline:
    """Chaîne de traitement de données."""

    def run(self, records, *, dry_run=False):
        """Exécute le pipeline sur une liste d'enregistrements.

        Args:
            records (list[dict]): Enregistrements à traiter.
            dry_run (bool): Si True, simule sans écrire.

        Returns:
            int: Nombre d'enregistrements traités.

        Raises:
            RuntimeError: Si le pipeline n'est pas initialisé.

        Note:
            En mode `dry_run`, les effets de bord sont désactivés
            mais les validations sont toujours effectuées.
        """
        if dry_run:
            return len(records)
        return len(records)
