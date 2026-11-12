"""Product analysis: barcode lookup and manual ingredient lists."""

import re

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from ..database import get_db
from ..schemas import AnalysisResult, AnalyzeRequest
from ..services.checks import build_analyzer, create_check
from ..services.open_food_facts import OpenFoodFactsError

router = APIRouter(prefix="/api", tags=["products"])


@router.get("/products/barcode/{barcode}", response_model=AnalysisResult)
def lookup_barcode(
    barcode: str,
    request: Request,
    save: bool = True,
    db: Session = Depends(get_db),
) -> AnalysisResult:
    """Looks the barcode up in Open Food Facts and analyses its ingredients."""
    if not re.fullmatch(r"\d{6,14}", barcode):
        raise HTTPException(status_code=422, detail="A barcode is 6 to 14 digits.")

    try:
        product = request.app.state.off_client.fetch_product(barcode)
    except OpenFoodFactsError as error:
        raise HTTPException(
            status_code=502,
            detail="The product database (Open Food Facts) could not be reached.",
        ) from error

    if product is None:
        raise HTTPException(
            status_code=404,
            detail=f"No product with barcode {barcode} was found in Open Food Facts.",
        )

    analysis = build_analyzer(db).analyze(product.ingredients_text)
    return create_check(
        db,
        analysis,
        product_name=product.name,
        ingredients_text=product.ingredients_text,
        source="barcode",
        barcode=barcode,
        brand=product.brand,
        image_url=product.image_url,
        has_halal_label=product.has_halal_label,
        save=save,
    )


@router.post("/analyze", response_model=AnalysisResult)
def analyze_ingredients(
    body: AnalyzeRequest,
    save: bool = True,
    db: Session = Depends(get_db),
) -> AnalysisResult:
    """Analyses a manually entered ingredient list."""
    analysis = build_analyzer(db).analyze(body.ingredients)
    return create_check(
        db,
        analysis,
        product_name=body.product_name,
        ingredients_text=body.ingredients,
        source="manual",
        barcode=body.barcode,
        save=save,
    )
