"""OpsPulse Orders API: a tiny service whose job is to be deployed and observed well."""
import os
import random
import time
from typing import Dict

from fastapi import FastAPI, HTTPException, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from pydantic import BaseModel, Field

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
# Used in the demo: set FAIL_RATE=0.5 to simulate a "bad release".
FAIL_RATE = float(os.getenv("FAIL_RATE", "0"))

REQUESTS = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "path", "status"]
)
LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["path"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.3, 0.5, 1.0, 2.5),
)

app = FastAPI(title="OpsPulse Orders API", version=APP_VERSION)
orders: Dict[int, dict] = {}


class OrderIn(BaseModel):
    item: str = Field(min_length=1, max_length=100)
    quantity: int = Field(gt=0, le=1000)


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.perf_counter()
    status = 500
    try:
        response = await call_next(request)
        status = response.status_code
        return response
    finally:
        route = request.scope.get("route")
        path = route.path if route else request.url.path
        LATENCY.labels(path).observe(time.perf_counter() - start)
        REQUESTS.labels(request.method, path, str(status)).inc()


def maybe_fail() -> None:
    if random.random() < FAIL_RATE:
        raise HTTPException(status_code=500, detail="simulated failure")


@app.get("/health")
def health():
    return {"status": "ok", "version": APP_VERSION}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/orders")
def list_orders():
    maybe_fail()
    return list(orders.values())


@app.post("/orders", status_code=201)
def create_order(order: OrderIn):
    maybe_fail()
    order_id = len(orders) + 1
    orders[order_id] = {"id": order_id, **order.model_dump()}
    return orders[order_id]


@app.get("/orders/{order_id}")
def get_order(order_id: int):
    maybe_fail()
    if order_id not in orders:
        raise HTTPException(status_code=404, detail="order not found")
    return orders[order_id]
