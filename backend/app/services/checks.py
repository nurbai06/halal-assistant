"""Runs an analysis, stores it as history and converts it to an API response."""

from datetime import timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import Ingredient, ProductCheck, ProductCheckDetail
from ..schemas import AnalysisResult, Certification, IngredientFinding
from .analyzer import DISCLAIMER, Analysis, IngredientAnalyzer, KnowledgeEntry

CERTIFICATE_NOTICE = (
    "Absence of a halal certificate does not automatically mean that a "
    "product is Haram."
)

# Certification states. VERIFIED and EXPIRED are part of the model but are
# never produced here: this app has no source that can confirm a certificate,
# and it does not invent one.
CERT_VERIFIED = "VERIFIED"
CERT_NOT_FOUND = "NOT_FOUND"
CERT_UNKNOWN = "UNKNOWN"
CERT_EXPIRED = "EXPIRED"


def build_analyzer(db: Session) -> IngredientAnalyzer:
    """An analyzer backed by the ingredient table."""
    rows = db.scalars(select(Ingredient).order_by(Ingredient.id)).all()
    return IngredientAnalyzer(
        [
            KnowledgeEntry(
                code=row.code,
                name=row.name,
                e_number=row.e_number,
                aliases=tuple(row.aliases),
                classification=row.classification,
                origin_dependent=row.origin_dependent,
                downgrade_context=tuple(row.downgrade_context or ()),
                reason=row.reason,
                verification_advice=row.verification_advice,
            )
            for row in rows
        ]
    )


def certification_for(source: str, has_halal_label: bool = False) -> tuple[str, str]:
    """Certification status and message; independent of the ingredient result."""
    if source == "manual":
        return (
            CERT_UNKNOWN,
            "Certification information is not available for manually entered products.",
        )
    if has_halal_label:
        return (
            CERT_UNKNOWN,
            "Open Food Facts lists a halal label for this product, but this app "
            "has not verified any certificate. Check the packaging for the "
            "certifier's name and certificate number.",
        )
    return (
        CERT_NOT_FOUND,
        "No halal certificate was found in the available product data.",
    )


def create_check(
    db: Session,
    analysis: Analysis,
    *,
    product_name: str,
    ingredients_text: str,
    source: str,
    barcode: str | None = None,
    brand: str | None = None,
    image_url: str | None = None,
    has_halal_label: bool = False,
    save: bool = True,
) -> AnalysisResult:
    cert_status, cert_message = certification_for(source, has_halal_label)
    check = ProductCheck(
        product_name=product_name.strip() or "Unnamed product",
        barcode=barcode,
        brand=brand,
        image_url=image_url,
        source=source,
        ingredients_text=ingredients_text.strip(),
        overall_status=analysis.overall_status,
        summary=analysis.summary,
        recommendation=analysis.recommendation,
        certification_status=cert_status,
        certification_message=cert_message,
        details=[
            ProductCheckDetail(
                position=position,
                text=finding.text,
                status=finding.status,
                matched_name=finding.matched_name,
                e_number=finding.e_number,
                code=finding.code,
                explanation=finding.explanation,
                verification_advice=finding.verification_advice,
            )
            for position, finding in enumerate(analysis.findings)
        ],
    )
    if save:
        db.add(check)
        db.commit()
        db.refresh(check)
    return to_result(check)


def to_result(check: ProductCheck) -> AnalysisResult:
    return AnalysisResult(
        id=check.id,
        product_name=check.product_name,
        barcode=check.barcode,
        brand=check.brand,
        image_url=check.image_url,
        source=check.source,
        ingredients_text=check.ingredients_text,
        overall_status=check.overall_status,
        summary=check.summary,
        recommendation=check.recommendation,
        ingredients=[
            IngredientFinding(
                text=detail.text,
                status=detail.status,
                matched_name=detail.matched_name,
                e_number=detail.e_number,
                code=detail.code,
                explanation=detail.explanation,
                verification_advice=detail.verification_advice,
            )
            for detail in check.details
        ],
        certification=Certification(
            status=check.certification_status,
            message=check.certification_message,
            notice=CERTIFICATE_NOTICE,
        ),
        disclaimer=DISCLAIMER,
        # Stored as naive UTC; say so explicitly for the client.
        checked_at=(
            check.checked_at.replace(tzinfo=timezone.utc) if check.checked_at else None
        ),
    )
