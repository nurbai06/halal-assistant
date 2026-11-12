"""Transparent, rule-based ingredient analysis.

The analyzer never guesses an origin. An additive whose source is not stated
(E471, E322, E422, gelatin, ...) is reported as "needs verification"; it only
becomes "prohibited" when the label itself declares a prohibited source, and
"permissible" when the label declares a plant, microbial or synthetic one.
"""

import json
import re
from dataclasses import dataclass, field
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

# Overall results.
HALAL_INDICATED = "HALAL_INDICATED"
HARAM_INDICATOR = "HARAM_INDICATOR"
NEEDS_VERIFICATION = "NEEDS_VERIFICATION"
INSUFFICIENT_INFORMATION = "INSUFFICIENT_INFORMATION"

# Per-ingredient results.
PERMISSIBLE = "permissible"
PROHIBITED = "prohibited"
DOUBTFUL = "needs_verification"
UNKNOWN = "unknown"

DISCLAIMER = (
    "This is an automated, preliminary assessment based only on the ingredient "
    "list. It is not a fatwa, a religious ruling or a halal certificate. For a "
    "definitive answer, consult a qualified scholar or a recognised halal "
    "certification body."
)

# Words that state where an origin-dependent additive comes from.
PLANT_WORDS = {
    "vegetable", "plant", "plant-based", "soy", "soya", "soybean", "sunflower",
    "rapeseed", "canola", "palm", "vegan", "vegetarian", "microbial", "synthetic",
}
PORK_WORDS = {"pork", "porcine", "lard", "swine"}
FISH_WORDS = {"fish", "marine"}
ANIMAL_WORDS = {"animal", "beef", "bovine", "tallow"}
ORIGIN_WORDS = PLANT_WORDS | PORK_WORDS | FISH_WORDS | ANIMAL_WORDS

# Labels name the function before the additive ("emulsifier: E471"); the
# function word itself is not an ingredient.
CLASS_WORDS = {
    "emulsifier", "emulsifiers", "stabiliser", "stabilisers", "stabilizer",
    "stabilizers", "colour", "colours", "color", "colors", "preservative",
    "preservatives", "antioxidant", "antioxidants", "acidity regulator",
    "acidity regulators", "thickener", "thickeners", "raising agent",
    "raising agents", "sweetener", "sweeteners", "flavour enhancer",
    "flavour enhancers", "flavor enhancer", "gelling agent", "gelling agents",
    "humectant", "humectants", "glazing agent", "glazing agents", "acid",
    "acids", "ingredients", "contains", "may contain", "and", "halal",
}

_ORIGIN_PAREN = re.compile(
    r"\(\s*(?:from\s+|of\s+)?((?:%s)(?:[\s-]+(?:origin|based|derived|source|sourced))?)\s*\)"
    % "|".join(sorted(ORIGIN_WORDS, key=len, reverse=True))
)


@dataclass(frozen=True)
class KnowledgeEntry:
    code: str
    name: str
    e_number: str | None
    aliases: tuple[str, ...]
    classification: str
    origin_dependent: bool
    downgrade_context: tuple[str, ...]
    reason: str
    verification_advice: str


@dataclass
class Finding:
    text: str
    status: str
    explanation: str
    matched_name: str | None = None
    e_number: str | None = None
    code: str | None = None
    verification_advice: str | None = None


@dataclass
class Analysis:
    overall_status: str
    summary: str
    recommendation: str
    findings: list[Finding] = field(default_factory=list)


def load_seed_ingredients() -> list[dict]:
    return json.loads((DATA_DIR / "ingredients.json").read_text(encoding="utf-8"))


def load_common_ingredients() -> list[str]:
    return json.loads((DATA_DIR / "common_ingredients.json").read_text(encoding="utf-8"))


def _has_word(phrase: str, text: str) -> bool:
    return re.search(rf"(?<![a-z0-9]){re.escape(phrase)}(?![a-z0-9])", text) is not None


def _has_any(words: set[str] | tuple[str, ...], text: str) -> bool:
    return any(_has_word(word, text) for word in words)


def split_ingredients(text: str) -> list[str]:
    """Turns a label's ingredient list into separate, normalised ingredients."""
    cleaned = text.lower().replace("_", " ").replace("*", " ")
    # "E 471", "E-471" -> "e471"
    cleaned = re.sub(r"\be[\s-]?(\d{3,4}[a-z]?)\b", r"e\1", cleaned)
    # Percentages say nothing about permissibility.
    cleaned = re.sub(r"\d+(?:[.,]\d+)?\s*%", " ", cleaned)
    # Keep a declared origin with its ingredient: "E471 (vegetable)" -> "e471 vegetable".
    cleaned = _ORIGIN_PAREN.sub(r" \1 ", cleaned)
    cleaned = re.sub(r"[()\[\]{}:;\n]", ",", cleaned)

    tokens: list[str] = []
    for raw in cleaned.split(","):
        token = re.sub(r"\s+", " ", raw).strip(" .-")
        if not token or token in CLASS_WORDS or token in tokens:
            continue
        tokens.append(token)
    return tokens


class IngredientAnalyzer:
    def __init__(self, entries: list[KnowledgeEntry], common: list[str] | None = None) -> None:
        self._entries = entries
        self._common = common if common is not None else load_common_ingredients()

    def analyze(self, ingredients_text: str) -> Analysis:
        tokens = split_ingredients(ingredients_text or "")
        findings = [finding for token in tokens for finding in self._assess(token)]
        return _summarise(findings)

    def _assess(self, token: str) -> list[Finding]:
        matches = self._match_entries(token)
        if matches:
            return [self._finding_for(token, entry) for entry in matches]
        if self._is_common(token):
            return [
                Finding(
                    text=_display(token),
                    status=PERMISSIBLE,
                    explanation="Common ingredient with no known concern.",
                )
            ]
        return [
            Finding(
                text=_display(token),
                status=UNKNOWN,
                explanation=(
                    "This ingredient is not in the knowledge database, so it "
                    "could not be assessed."
                ),
                verification_advice=(
                    "Look it up or ask the manufacturer if you are unsure."
                ),
            )
        ]

    def _match_entries(self, token: str) -> list[KnowledgeEntry]:
        """Knowledge entries named in the token, most specific alias first."""
        candidates = []
        for entry in self._entries:
            for alias in entry.aliases:
                for found in re.finditer(
                    rf"(?<![a-z0-9]){re.escape(alias)}(?![a-z0-9])", token
                ):
                    candidates.append((found.start(), found.end(), entry, alias))
        candidates.sort(key=lambda c: (-(c[1] - c[0]), c[0]))

        accepted: list[tuple[int, int, KnowledgeEntry, str]] = []
        for candidate in candidates:
            start, end = candidate[0], candidate[1]
            if all(end <= a[0] or start >= a[1] for a in accepted):
                accepted.append(candidate)
        accepted.sort(key=lambda c: c[0])

        # In "beef gelatin" the word "beef" states the gelatin's origin; it is
        # not a second ingredient.
        if any(entry.origin_dependent for _, _, entry, _ in accepted):
            accepted = [
                a for a in accepted if a[2].origin_dependent or a[3] not in ORIGIN_WORDS
            ]

        entries: list[KnowledgeEntry] = []
        for _, _, entry, _ in accepted:
            if entry not in entries:
                entries.append(entry)
        return entries

    def _finding_for(self, token: str, entry: KnowledgeEntry) -> Finding:
        status = entry.classification
        explanation = entry.reason
        advice: str | None = entry.verification_advice

        if entry.origin_dependent:
            if _has_any(PORK_WORDS, token):
                status = PROHIBITED
                explanation = (
                    f"The label declares a pork origin for {entry.name.lower()}, "
                    "and pork is prohibited."
                )
                advice = "Avoid this product."
            elif _has_any(PLANT_WORDS, token):
                status = PERMISSIBLE
                explanation = (
                    f"The label declares a plant, microbial or synthetic origin "
                    f"for {entry.name.lower()}, which raises no concern."
                )
                advice = None
            elif _has_any(FISH_WORDS, token):
                status = PERMISSIBLE
                explanation = (
                    f"The label declares a fish origin for {entry.name.lower()}, "
                    "which raises no concern."
                )
                advice = None
            elif _has_any(ANIMAL_WORDS, token):
                status = DOUBTFUL
                explanation = (
                    f"The label declares an animal origin for {entry.name.lower()}; "
                    "whether it is permissible depends on the animal and how it "
                    "was slaughtered."
                )
                advice = "Look for a halal certificate that covers this ingredient."
        elif (
            status == PROHIBITED
            and entry.downgrade_context
            and _has_any(entry.downgrade_context, token)
        ):
            status = DOUBTFUL
            explanation = (
                "The label names it as a flavouring, which may not contain the "
                "beverage itself."
            )
            advice = "Ask the manufacturer whether the flavouring contains alcohol."

        if status == PERMISSIBLE:
            advice = None
        return Finding(
            text=_display(token),
            status=status,
            explanation=explanation,
            matched_name=entry.name,
            e_number=entry.e_number,
            code=entry.code,
            verification_advice=advice,
        )

    def _is_common(self, token: str) -> bool:
        return any(
            re.search(rf"(?<![a-z0-9]){re.escape(phrase)}(?:e?s)?(?![a-z0-9])", token)
            for phrase in self._common
        )


def _display(token: str) -> str:
    """'e471 vegetable' -> 'E471 vegetable', 'wheat flour' -> 'Wheat flour'."""
    text = re.sub(r"\be(\d{3,4}[a-z]?)\b", lambda m: "E" + m.group(1), token)
    return text[:1].upper() + text[1:]


def _names(findings: list[Finding]) -> str:
    return ", ".join(dict.fromkeys(f.matched_name or f.text for f in findings))


def _summarise(findings: list[Finding]) -> Analysis:
    prohibited = [f for f in findings if f.status == PROHIBITED]
    doubtful = [f for f in findings if f.status == DOUBTFUL]
    unknown = [f for f in findings if f.status == UNKNOWN]
    recognised = len(findings) - len(unknown)

    if not findings:
        return Analysis(
            overall_status=INSUFFICIENT_INFORMATION,
            summary="No ingredients were provided, so the product could not be assessed.",
            recommendation=(
                "Enter the full ingredient list from the packaging and check again."
            ),
        )

    if prohibited:
        summary = f"A clearly prohibited ingredient was identified: {_names(prohibited)}."
        if doubtful:
            summary += f" In addition, these need verification: {_names(doubtful)}."
        return Analysis(
            overall_status=HARAM_INDICATOR,
            summary=summary,
            recommendation=(
                "Avoid this product unless the manufacturer or a halal "
                "certification body confirms that the ingredient list is wrong."
            ),
            findings=findings,
        )

    if doubtful:
        return Analysis(
            overall_status=NEEDS_VERIFICATION,
            summary=(
                "No clearly prohibited ingredient was found, but the origin of "
                f"these ingredients is uncertain: {_names(doubtful)}."
            ),
            recommendation=(
                "Look for a halal certificate on the packaging, or ask the "
                "manufacturer about the source of the ingredients listed above."
            ),
            findings=findings,
        )

    if len(unknown) >= recognised:
        return Analysis(
            overall_status=INSUFFICIENT_INFORMATION,
            summary=(
                "Most of the ingredients could not be reliably identified: "
                f"{_names(unknown)}."
            ),
            recommendation=(
                "Check the spelling, enter the ingredients in English, or ask "
                "the manufacturer for details."
            ),
            findings=findings,
        )

    summary = (
        "No known problematic ingredients were identified in the supplied "
        "information. This is a preliminary ingredient-based assessment, not "
        "an official halal certification."
    )
    if unknown:
        summary += f" These ingredients could not be assessed: {_names(unknown)}."
    return Analysis(
        overall_status=HALAL_INDICATED,
        summary=summary,
        recommendation=(
            "For full assurance, look for a halal certificate from a "
            "recognised certification body."
        ),
        findings=findings,
    )
