"""Database tables."""

from datetime import datetime, timezone

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


def _utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


class Ingredient(Base):
    """One entry of the ingredient knowledge database (seeded from JSON)."""

    __tablename__ = "ingredients"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(128))
    e_number: Mapped[str | None] = mapped_column(String(16), index=True)
    aliases: Mapped[list[str]] = mapped_column(JSON)
    classification: Mapped[str] = mapped_column(String(32))
    origin_dependent: Mapped[bool] = mapped_column(Boolean, default=False)
    downgrade_context: Mapped[list[str]] = mapped_column(JSON, default=list)
    description: Mapped[str] = mapped_column(Text)
    possible_origin: Mapped[str] = mapped_column(Text)
    halal_assessment: Mapped[str] = mapped_column(Text)
    reason: Mapped[str] = mapped_column(Text)
    verification_advice: Mapped[str] = mapped_column(Text)
    source: Mapped[str | None] = mapped_column(Text)


class ProductCheck(Base):
    """One analysed product, kept as history."""

    __tablename__ = "product_checks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    product_name: Mapped[str] = mapped_column(String(256))
    barcode: Mapped[str | None] = mapped_column(String(32))
    brand: Mapped[str | None] = mapped_column(String(256))
    image_url: Mapped[str | None] = mapped_column(Text)
    source: Mapped[str] = mapped_column(String(16))
    ingredients_text: Mapped[str] = mapped_column(Text)
    overall_status: Mapped[str] = mapped_column(String(32), index=True)
    summary: Mapped[str] = mapped_column(Text)
    recommendation: Mapped[str] = mapped_column(Text)
    certification_status: Mapped[str] = mapped_column(String(16))
    certification_message: Mapped[str] = mapped_column(Text)
    checked_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now)

    details: Mapped[list["ProductCheckDetail"]] = relationship(
        back_populates="check",
        cascade="all, delete-orphan",
        order_by="ProductCheckDetail.position",
    )


class ProductCheckDetail(Base):
    """The assessment of one ingredient within a product check."""

    __tablename__ = "product_check_details"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    check_id: Mapped[int] = mapped_column(
        ForeignKey("product_checks.id", ondelete="CASCADE"), index=True
    )
    position: Mapped[int] = mapped_column(Integer)
    text: Mapped[str] = mapped_column(String(256))
    status: Mapped[str] = mapped_column(String(32))
    matched_name: Mapped[str | None] = mapped_column(String(128))
    e_number: Mapped[str | None] = mapped_column(String(16))
    code: Mapped[str | None] = mapped_column(String(64))
    explanation: Mapped[str] = mapped_column(Text)
    verification_advice: Mapped[str | None] = mapped_column(Text)

    check: Mapped[ProductCheck] = relationship(back_populates="details")
