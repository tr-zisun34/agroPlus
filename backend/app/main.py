from fastapi import FastAPI

from app.routers import auth, farmers

app = FastAPI(title="AgroPlus API")

app.include_router(auth.router)
app.include_router(farmers.router)


@app.get("/health")
def health():
    return {"status": "ok"}
