from fastapi.testclient import TestClient

from app.main import create_app
from app.services.open_food_facts import OffProduct

NOTICE = "Absence of a halal certificate does not automatically mean that a product is Haram."


def analyze(client, ingredients, name="Test product"):
    response = client.post(
        "/api/analyze", json={"product_name": name, "ingredients": ingredients}
    )
    assert response.status_code == 200
    return response.json()


def statuses(result):
    return {item["text"]: item["status"] for item in result["ingredients"]}


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["ingredients_in_database"] >= 10


# --- Manual analysis and ingredient rules ---------------------------------


def test_manual_analysis_returns_full_result(client):
    result = analyze(
        client,
        "Sugar, wheat flour, vegetable oil, cocoa powder, milk powder, "
        "emulsifier E471, flavouring.",
        name="Chocolate Biscuits",
    )
    assert result["product_name"] == "Chocolate Biscuits"
    assert result["overall_status"] == "NEEDS_VERIFICATION"
    assert result["source"] == "manual"
    assert result["summary"] and result["recommendation"] and result["disclaimer"]
    e471 = next(i for i in result["ingredients"] if i["e_number"] == "E471")
    assert e471["status"] == "needs_verification"
    assert e471["explanation"] and e471["verification_advice"]


def test_clean_ingredients_are_halal_indicated_but_not_certified(client):
    result = analyze(client, "Water, sugar, citric acid, pectin (E440), agar")
    assert result["overall_status"] == "HALAL_INDICATED"
    assert "not an official halal certification" in result["summary"]
    assert all(i["status"] == "permissible" for i in result["ingredients"])


def test_pork_gelatin_is_a_haram_indicator_and_names_the_ingredient(client):
    result = analyze(client, "Sugar, glucose syrup, pork gelatin, citric acid")
    assert result["overall_status"] == "HARAM_INDICATOR"
    assert "Pork gelatin" in result["summary"]
    assert statuses(result)["Pork gelatin"] == "prohibited"


def test_e471_alone_is_not_classified_as_haram(client):
    result = analyze(client, "Wheat flour, E471, salt")
    assert result["overall_status"] == "NEEDS_VERIFICATION"
    assert statuses(result)["E471"] == "needs_verification"


def test_ambiguous_codes_never_produce_a_haram_indicator(client):
    for code in ("E471", "E322", "E422", "E441", "E120", "gelatin", "E 471", "e-471"):
        result = analyze(client, f"Sugar, {code}")
        assert result["overall_status"] == "NEEDS_VERIFICATION", code


def test_declared_plant_origin_resolves_the_doubt(client):
    result = analyze(
        client, "Sugar, soy lecithin, E471 (vegetable), vegetable glycerin, cocoa"
    )
    assert result["overall_status"] == "HALAL_INDICATED"


def test_declared_pork_origin_is_prohibited(client):
    result = analyze(client, "Sugar, gelatin (pork)")
    assert result["overall_status"] == "HARAM_INDICATOR"


def test_beef_gelatin_needs_verification_and_is_listed_once(client):
    result = analyze(client, "Sugar, beef gelatin")
    assert result["overall_status"] == "NEEDS_VERIFICATION"
    assert len(result["ingredients"]) == 2


def test_wine_vinegar_is_not_treated_as_wine(client):
    result = analyze(client, "Water, wine vinegar, salt")
    assert result["overall_status"] == "HALAL_INDICATED"


def test_unknown_ingredients_are_handled_safely(client):
    result = analyze(client, "xyzzium, frobnicate extractum")
    assert result["overall_status"] == "INSUFFICIENT_INFORMATION"
    assert all(i["status"] == "unknown" for i in result["ingredients"])

    mixed = analyze(client, "Water, sugar, salt, xyzzium")
    assert mixed["overall_status"] == "HALAL_INDICATED"
    assert "xyzzium" in mixed["summary"].lower()


def test_empty_ingredients_are_insufficient_information(client):
    assert analyze(client, "")["overall_status"] == "INSUFFICIENT_INFORMATION"
    assert analyze(client, "  ,  ")["overall_status"] == "INSUFFICIENT_INFORMATION"


# --- Certification is separate from the ingredient result -----------------


def test_missing_certification_does_not_mean_haram(client, off):
    off.products["1234567890123"] = OffProduct(
        barcode="1234567890123",
        name="Plain Water",
        ingredients_text="Water, salt",
    )
    result = client.get("/api/products/barcode/1234567890123").json()
    assert result["certification"]["status"] == "NOT_FOUND"
    assert result["certification"]["notice"] == NOTICE
    assert result["overall_status"] == "HALAL_INDICATED"


def test_manual_products_have_unknown_certification(client):
    result = analyze(client, "Sugar, pork gelatin")
    assert result["certification"]["status"] == "UNKNOWN"
    assert result["certification"]["notice"] == NOTICE


def test_a_community_halal_label_is_never_reported_as_verified(client, off):
    off.products["1234567890123"] = OffProduct(
        barcode="1234567890123",
        name="Dates",
        ingredients_text="Dates",
        labels=["en:halal"],
    )
    result = client.get("/api/products/barcode/1234567890123").json()
    assert result["certification"]["status"] == "UNKNOWN"
    assert "not verified" in result["certification"]["message"]


# --- Barcode lookup --------------------------------------------------------


def test_barcode_lookup_analyses_the_product(client, off):
    off.products["3017620422003"] = OffProduct(
        barcode="3017620422003",
        name="Hazelnut Spread",
        brand="Example Brand",
        ingredients_text="Sugar, palm oil, hazelnuts 13%, skimmed milk powder, "
        "emulsifier: lecithins (soya), vanillin",
    )
    response = client.get("/api/products/barcode/3017620422003")
    assert response.status_code == 200
    result = response.json()
    assert result["product_name"] == "Hazelnut Spread"
    assert result["brand"] == "Example Brand"
    assert result["barcode"] == "3017620422003"
    assert result["source"] == "barcode"
    assert result["overall_status"] == "HALAL_INDICATED"


def test_barcode_not_found_returns_404(client):
    response = client.get("/api/products/barcode/0000000000000")
    assert response.status_code == 404
    assert "no product with barcode" in response.json()["detail"].lower()


def test_barcode_without_ingredients_is_insufficient_information(client, off):
    off.products["1234567890123"] = OffProduct(barcode="1234567890123", name="Mystery")
    result = client.get("/api/products/barcode/1234567890123").json()
    assert result["overall_status"] == "INSUFFICIENT_INFORMATION"


def test_product_database_failure_returns_502(client, off):
    off.fail = True
    assert client.get("/api/products/barcode/1234567890123").status_code == 502


def test_invalid_barcode_is_rejected(client):
    assert client.get("/api/products/barcode/abc").status_code == 422


# --- Ingredient dictionary -------------------------------------------------


def test_ingredient_dictionary(client):
    items = client.get("/api/ingredients").json()
    assert len(items) >= 10
    assert {"E441", "E322", "E422", "E471", "E120", "E440", "E406", "E330", "E500"} <= {
        item["e_number"] for item in items
    }

    by_number = client.get("/api/ingredients/E471").json()
    assert by_number["code"] == "mono-diglycerides"
    assert by_number["possible_origin"] and by_number["verification_advice"]

    assert client.get("/api/ingredients/e441").json()["code"] == "gelatin"
    assert client.get("/api/ingredients/pork-gelatin").json()["classification"] == "prohibited"
    assert client.get("/api/ingredients/nope").status_code == 404
    assert [i["code"] for i in client.get("/api/ingredients?q=lecithin").json()] == ["lecithin"]


# --- History and dashboard -------------------------------------------------


def test_analysis_is_saved_to_history(client):
    first = analyze(client, "Sugar, E471", name="Biscuits")
    second = analyze(client, "Water, salt", name="Brine")

    history = client.get("/api/history").json()
    assert [item["product_name"] for item in history] == ["Brine", "Biscuits"]
    assert history[0]["id"] == second["id"]
    assert history[0]["checked_at"]

    opened = client.get(f"/api/history/{first['id']}").json()
    assert opened["overall_status"] == "NEEDS_VERIFICATION"
    assert opened["ingredients"] == first["ingredients"]


def test_post_history_saves_a_check(client):
    response = client.post(
        "/api/history",
        json={"product_name": "Jelly", "ingredients": "Sugar, pork gelatin"},
    )
    assert response.status_code == 201
    assert response.json()["overall_status"] == "HARAM_INDICATOR"
    assert len(client.get("/api/history").json()) == 1


def test_delete_history_record(client):
    record = analyze(client, "Water")
    assert client.delete(f"/api/history/{record['id']}").status_code == 204
    assert client.get("/api/history").json() == []
    assert client.delete(f"/api/history/{record['id']}").status_code == 404


def test_save_false_does_not_store_the_check(client):
    client.post("/api/analyze?save=false", json={"ingredients": "Water"})
    assert client.get("/api/history").json() == []


def test_dashboard_counts_checks(client):
    analyze(client, "Water, salt")
    analyze(client, "Sugar, E471")
    analyze(client, "Sugar, lard")

    dashboard = client.get("/api/dashboard").json()
    assert dashboard["total_checks"] == 3
    assert dashboard["status_counts"] == {
        "HALAL_INDICATED": 1,
        "HARAM_INDICATOR": 1,
        "NEEDS_VERIFICATION": 1,
        "INSUFFICIENT_INFORMATION": 0,
    }
    assert len(dashboard["recent_checks"]) == 3
    assert dashboard["ingredient_count"] >= 10


def test_history_persists_across_restarts(db_url, off):
    first_app = create_app(database_url=db_url, off_client=off)
    with TestClient(first_app) as first:
        first.post(
            "/api/analyze",
            json={"product_name": "Persisted", "ingredients": "Sugar, E322"},
        )
    first_app.state.db.dispose()

    second_app = create_app(database_url=db_url, off_client=off)
    with TestClient(second_app) as second:
        history = second.get("/api/history").json()
        assert [item["product_name"] for item in history] == ["Persisted"]
        assert history[0]["ingredients"][1]["e_number"] == "E322"
        # Seeding again must not duplicate the dictionary.
        codes = [i["code"] for i in second.get("/api/ingredients").json()]
        assert len(codes) == len(set(codes))
    second_app.state.db.dispose()
