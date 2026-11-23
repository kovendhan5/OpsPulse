from fastapi.testclient import TestClient

import main

client = TestClient(main.app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_create_and_get_order():
    r = client.post("/orders", json={"item": "book", "quantity": 2})
    assert r.status_code == 201
    order_id = r.json()["id"]
    assert client.get(f"/orders/{order_id}").json()["item"] == "book"


def test_validation_rejects_bad_quantity():
    r = client.post("/orders", json={"item": "book", "quantity": 0})
    assert r.status_code == 422


def test_metrics_exposed():
    client.get("/health")
    body = client.get("/metrics").text
    assert "http_requests_total" in body


def test_simulated_failure(monkeypatch):
    monkeypatch.setattr(main, "FAIL_RATE", 1.0)
    assert client.get("/orders").status_code == 500
