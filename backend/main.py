from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import get_pool, close_pool
from modules.clients.router import router as clients_router
from modules.assignments.router import router as assignments_router
from modules.schedule.router import router as schedule_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    await get_pool()
    yield
    # shutdown
    await close_pool()


app = FastAPI(
    title="Flowday API",
    description="Backend for the Flowday day planning system",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(clients_router,     prefix="/api/v1/clients",     tags=["clients"])
app.include_router(assignments_router, prefix="/api/v1/assignments", tags=["assignments"])
app.include_router(schedule_router,    prefix="/api/v1/schedule",    tags=["schedule"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "flowday-api"}
