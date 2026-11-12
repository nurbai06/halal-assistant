"""The ingredient knowledge database."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Ingredient
from ..schemas import IngredientOut

router = APIRouter(prefix="/api/ingredients", tags=["ingredients"])


@router.get("", response_model=list[IngredientOut])
def list_ingredients(q: str | None = None, db: Session = Depends(get_db)):
    """All entries, optionally filtered by name or E-number."""
    query = select(Ingredient).order_by(Ingredient.name)
    if q and q.strip():
        pattern = f"%{q.strip().lower()}%"
        query = query.where(
            or_(
                func.lower(Ingredient.name).like(pattern),
                func.lower(Ingredient.e_number).like(pattern),
            )
        )
    return db.scalars(query).all()


@router.get("/{code}", response_model=IngredientOut)
def get_ingredient(code: str, db: Session = Depends(get_db)):
    """One entry, by its code ("lecithin") or E-number ("E322")."""
    key = code.strip().lower()
    ingredient = db.scalars(
        select(Ingredient)
        .where(or_(Ingredient.code == key, func.lower(Ingredient.e_number) == key))
        # When two entries share an E-number, prefer the generic one (lower id).
        .order_by((Ingredient.code != key), Ingredient.id)
    ).first()
    if ingredient is None:
        raise HTTPException(status_code=404, detail=f"Ingredient '{code}' was not found.")
    return ingredient
