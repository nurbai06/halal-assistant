import os
import tempfile

# Importing app.main builds the default app; point it at a throwaway database
# so running the tests never touches the real one.
os.environ["HALAL_DB_PATH"] = os.path.join(tempfile.mkdtemp(), "import.db")

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.main import create_app  # noqa: E402
from app.services.open_food_facts import OffProduct, OpenFoodFactsError  # noqa: E402


class FakeOpenFoodFacts:
    """Stands in for Open Food Facts so tests need no network."""

    def __init__(self) -> None:
        self.products: dict[str, OffProduct] = {}
        self.fail = False

    def fetch_product(self, barcode: str) -> OffProduct | None:
        if self.fail:
            raise OpenFoodFactsError("network down")
        return self.products.get(barcode)


@pytest.fixture
def off() -> FakeOpenFoodFacts:
    return FakeOpenFoodFacts()


@pytest.fixture
def db_url(tmp_path) -> str:
    return f"sqlite:///{tmp_path / 'test.db'}"


@pytest.fixture
def client(db_url, off) -> TestClient:
    app = create_app(database_url=db_url, off_client=off)
    with TestClient(app) as test_client:
        yield test_client
    app.state.db.dispose()
