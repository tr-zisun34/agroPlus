from fastapi import FastAPI

from app.routers import auth, districts, farmers, farms

app = FastAPI(title="AgroPlus API")

app.include_router(auth.router)
app.include_router(farmers.router)
app.include_router(districts.router)
app.include_router(farms.router)


@app.get("/health")
def health():
    return {"status": "ok"}
