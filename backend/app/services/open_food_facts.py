"""Client for the Open Food Facts product database."""

from dataclasses import dataclass, field

import httpx

BASE_URL = "https://world.openfoodfacts.org/api/v2/product"
FIELDS = (
    "product_name,product_name_en,brands,ingredients_text,ingredients_text_en,"
    "image_front_small_url,labels_tags"
)
# Open Food Facts asks every client to identify itself.
USER_AGENT = "HalalAssistant/1.0 (university project)"


class OpenFoodFactsError(Exception):
    """Open Food Facts could not be reached or answered unexpectedly."""


@dataclass
class OffProduct:
    barcode: str
    name: str
    brand: str | None = None
    ingredients_text: str = ""
    image_url: str | None = None
    labels: list[str] = field(default_factory=list)

    @property
    def has_halal_label(self) -> bool:
        return any("halal" in label.lower() for label in self.labels)


class OpenFoodFactsClient:
    def __init__(self, timeout: float = 10.0) -> None:
        self._timeout = timeout

    def fetch_product(self, barcode: str) -> OffProduct | None:
        """The product for [barcode], or None if Open Food Facts has no entry."""
        try:
            response = httpx.get(
                f"{BASE_URL}/{barcode}.json",
                params={"fields": FIELDS},
                headers={"User-Agent": USER_AGENT},
                timeout=self._timeout,
            )
        except httpx.HTTPError as error:
            raise OpenFoodFactsError(str(error)) from error

        if response.status_code == 404:
            return None
        if response.status_code != 200:
            raise OpenFoodFactsError(f"Unexpected status {response.status_code}")

        try:
            payload = response.json()
        except ValueError as error:
            raise OpenFoodFactsError("Response was not JSON") from error

        product = payload.get("product")
        if payload.get("status") != 1 or not product:
            return None

        return OffProduct(
            barcode=barcode,
            name=(
                product.get("product_name_en")
                or product.get("product_name")
                or "Unnamed product"
            ).strip(),
            brand=(product.get("brands") or "").strip() or None,
            # The analyzer's knowledge base is in English.
            ingredients_text=(
                product.get("ingredients_text_en")
                or product.get("ingredients_text")
                or ""
            ).strip(),
            image_url=product.get("image_front_small_url") or None,
            labels=list(product.get("labels_tags") or []),
        )
