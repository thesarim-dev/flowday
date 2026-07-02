from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def list_clients():
    return {"message": "clients — coming in M1"}
