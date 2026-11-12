"""Request and response bodies."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class AnalyzeRequest(BaseModel):
    product_name: str = Field(default="", max_length=256)
    ingredients: str = Field(default="", max_length=5000)
    barcode: str | None = Field(default=None, max_length=32)


class IngredientFinding(BaseModel):
    """How one ingredient of a product was assessed."""

    text: str
    status: str  # permissible | prohibited | needs_verification | unknown
    matched_name: str | None = None
    e_number: str | None = None
    code: str | None = None  # knowledge-database entry, when matched
    explanation: str
    verification_advice: str | None = None


class Certification(BaseModel):
    """Certification is reported separately from the ingredient assessment."""

    status: str  # VERIFIED | NOT_FOUND | UNKNOWN | EXPIRED
    message: str
    notice: str


class AnalysisResult(BaseModel):
    id: int | None = None
    product_name: str
    barcode: str | None = None
    brand: str | None = None
    image_url: str | None = None
    source: str  # manual | barcode
    ingredients_text: str
    overall_status: str
    summary: str
    recommendation: str
    ingredients: list[IngredientFinding]
    certification: Certification
    disclaimer: str
    checked_at: datetime | None = None


class IngredientOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    code: str
    name: str
    e_number: str | None
    aliases: list[str]
    classification: str
    description: str
    possible_origin: str
    halal_assessment: str
    reason: str
    verification_advice: str
    source: str | None


class Dashboard(BaseModel):
    total_checks: int
    status_counts: dict[str, int]
    ingredient_count: int
    recent_checks: list[AnalysisResult]
