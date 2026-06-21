from fastapi import APIRouter, HTTPException
from app.models.schemas import GenerateRequest, SlidesResponse, NotesResponse, QuizResponse
from app.services.ai_service import generate_slides, generate_notes, generate_quiz

router = APIRouter()

@router.post("/slides", response_model=SlidesResponse)
async def create_slides(request: GenerateRequest):
    try:
        result = await generate_slides(request.topic, request.num_items or 5)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/notes", response_model=NotesResponse)
async def create_notes(request: GenerateRequest):
    try:
        result = await generate_notes(request.topic)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/quiz", response_model=QuizResponse)
async def create_quiz(request: GenerateRequest):
    try:
        result = await generate_quiz(request.topic, request.num_items or 5)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
