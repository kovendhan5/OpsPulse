from fastapi.testclient import TestClient

import main

client = TestClient(main.app)


def setup_function():
    """Reset shared state before every test so tests are order-independent."""
    main.orders.clear()
    main._next_id = 1


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_health_has_version():
    r = client.get("/health")
    assert "version" in r.json()


def test_create_and_get_order():
    r = client.post("/orders", json={"item": "book", "quantity": 2})
    assert r.status_code == 201
    order_id = r.json()["id"]
    assert client.get(f"/orders/{order_id}").json()["item"] == "book"


def test_create_returns_all_fields():
    r = client.post("/orders", json={"item": "pen", "quantity": 5})
    body = r.json()
    assert "id" in body
    assert body["item"] == "pen"
    assert body["quantity"] == 5


def test_list_orders():
    client.post("/orders", json={"item": "a", "quantity": 1})
    client.post("/orders", json={"item": "b", "quantity": 2})
    r = client.get("/orders")
    assert r.status_code == 200
    assert len(r.json()) == 2


def test_get_nonexistent_order():
    r = client.get("/orders/9999")
    assert r.status_code == 404


def test_validation_rejects_bad_quantity():
    r = client.post("/orders", json={"item": "book", "quantity": 0})
    assert r.status_code == 422


def test_validation_rejects_empty_item():
    r = client.post("/orders", json={"item": "", "quantity": 1})
    assert r.status_code == 422


def test_validation_rejects_negative_quantity():
    r = client.post("/orders", json={"item": "book", "quantity": -1})
    assert r.status_code == 422


def test_delete_order():
    r = client.post("/orders", json={"item": "book", "quantity": 1})
    order_id = r.json()["id"]
    d = client.delete(f"/orders/{order_id}")
    assert d.status_code == 204
    assert client.get(f"/orders/{order_id}").status_code == 404


def test_delete_nonexistent_order():
    r = client.delete("/orders/9999")
    assert r.status_code == 404


def test_id_no_collision_after_delete():
    """After deleting an order, new orders must not reuse the same ID."""
    r1 = client.post("/orders", json={"item": "a", "quantity": 1})
    id1 = r1.json()["id"]
    client.delete(f"/orders/{id1}")
    r2 = client.post("/orders", json={"item": "b", "quantity": 1})
    id2 = r2.json()["id"]
    assert id2 != id1, "IDs must not collide after a delete"


def test_metrics_exposed():
    client.get("/health")
    body = client.get("/metrics").text
    assert "http_requests_total" in body


def test_metrics_contains_latency():
    client.get("/health")
    body = client.get("/metrics").text
    assert "http_request_duration_seconds" in body


def test_simulated_failure(monkeypatch):
    monkeypatch.setattr(main, "FAIL_RATE", 1.0)
    assert client.get("/orders").status_code == 500
