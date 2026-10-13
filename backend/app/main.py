from fastapi import FastAPI

from app.routers import auth, chat, districts, farmers, farms, recommendations

app = FastAPI(title="AgroPlus API")

app.include_router(auth.router)
app.include_router(farmers.router)
app.include_router(districts.router)
app.include_router(farms.router)
app.include_router(recommendations.router)
app.include_router(chat.router)


@app.get("/health")
def health():
    return {"status": "ok"}
