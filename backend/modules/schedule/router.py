from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def list_schedule():
    return {"message": "schedule — coming in M1"}
