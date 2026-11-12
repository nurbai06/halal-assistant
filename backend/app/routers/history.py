"""Previously checked products and dashboard statistics."""

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Ingredient, ProductCheck
from ..schemas import AnalysisResult, AnalyzeRequest, Dashboard
from ..services.analyzer import (
    HALAL_INDICATED,
    HARAM_INDICATOR,
    INSUFFICIENT_INFORMATION,
    NEEDS_VERIFICATION,
)
from ..services.checks import build_analyzer, create_check, to_result

router = APIRouter(prefix="/api", tags=["history"])


def _recent(db: Session, limit: int) -> list[ProductCheck]:
    return db.scalars(
        select(ProductCheck)
        .order_by(ProductCheck.checked_at.desc(), ProductCheck.id.desc())
        .limit(limit)
    ).all()


@router.get("/history", response_model=list[AnalysisResult])
def list_history(limit: int = 100, db: Session = Depends(get_db)):
    """Checked products, newest first."""
    return [to_result(check) for check in _recent(db, max(1, min(limit, 500)))]


@router.post("/history", response_model=AnalysisResult, status_code=201)
def save_history(body: AnalyzeRequest, db: Session = Depends(get_db)):
    """Analyses a product and stores the check.

    The status is always computed by the server, never taken from the client.
    """
    analysis = build_analyzer(db).analyze(body.ingredients)
    return create_check(
        db,
        analysis,
        product_name=body.product_name,
        ingredients_text=body.ingredients,
        source="manual",
        barcode=body.barcode,
    )


@router.get("/history/{check_id}", response_model=AnalysisResult)
def get_history_item(check_id: int, db: Session = Depends(get_db)):
    check = db.get(ProductCheck, check_id)
    if check is None:
        raise HTTPException(status_code=404, detail="History record not found.")
    return to_result(check)


@router.delete("/history/{check_id}", status_code=204)
def delete_history_item(check_id: int, db: Session = Depends(get_db)):
    check = db.get(ProductCheck, check_id)
    if check is None:
        raise HTTPException(status_code=404, detail="History record not found.")
    db.delete(check)
    db.commit()
    return Response(status_code=204)


@router.get("/dashboard", response_model=Dashboard)
def dashboard(db: Session = Depends(get_db)):
    """Numbers and recent checks for the home screen."""
    counts = dict(
        db.execute(
            select(ProductCheck.overall_status, func.count()).group_by(
                ProductCheck.overall_status
            )
        ).all()
    )
    statuses = (
        HALAL_INDICATED,
        HARAM_INDICATOR,
        NEEDS_VERIFICATION,
        INSUFFICIENT_INFORMATION,
    )
    return Dashboard(
        total_checks=sum(counts.values()),
        status_counts={status: counts.get(status, 0) for status in statuses},
        ingredient_count=db.scalar(select(func.count()).select_from(Ingredient)) or 0,
        recent_checks=[to_result(check) for check in _recent(db, 5)],
    )
