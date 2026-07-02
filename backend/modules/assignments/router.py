from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def list_assignments():
    return {"message": "assignments — coming in M1"}


@router.get("/today")
async def today_assignments():
    return {"message": "today view — coming in M1"}
