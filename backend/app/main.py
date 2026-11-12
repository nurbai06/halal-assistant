"""Halal Assistant backend.

Run from the backend directory:
    uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select

from .database import Database, default_database_url
from .models import Ingredient
from .routers import history, ingredients, products
from .services.analyzer import load_seed_ingredients
from .services.open_food_facts import OpenFoodFactsClient


def seed_ingredients(db: Database) -> None:
    """Inserts or updates the knowledge database from data/ingredients.json."""
    with db.session() as session:
        existing = {row.code: row for row in session.scalars(select(Ingredient))}
        for item in load_seed_ingredients():
            values = {"downgrade_context": [], **item}
            row = existing.get(item["code"])
            if row is None:
                session.add(Ingredient(**values))
            else:
                for key, value in values.items():
                    setattr(row, key, value)
        session.commit()


def create_app(database_url: str | None = None, off_client=None) -> FastAPI:
    """Builds the app; tests pass their own database and product client."""
    app = FastAPI(
        title="Halal Assistant API",
        description=(
            "Preliminary, rule-based ingredient assessment. Not a fatwa and "
            "not a halal certificate."
        ),
        version="1.0.0",
    )

    db = Database(database_url or default_database_url())
    db.create_tables()
    seed_ingredients(db)
    app.state.db = db
    app.state.off_client = off_client or OpenFoodFactsClient()

    # Development setting: the Flutter web build runs on another origin.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health", tags=["health"])
    def health() -> dict:
        with db.session() as session:
            count = session.scalar(select(func.count()).select_from(Ingredient))
        return {
            "status": "ok",
            "service": "halal-assistant-backend",
            "version": app.version,
            "ingredients_in_database": count,
        }

    app.include_router(products.router)
    app.include_router(ingredients.router)
    app.include_router(history.router)
    return app


app = create_app()
