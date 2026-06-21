from pydantic import BaseModel
from typing import Optional

class GenerateRequest(BaseModel):
    topic: str
    num_items: Optional[int] = 5

class SlideContent(BaseModel):
    title: str
    content: str
    bullet_points: list[str]

class SlidesResponse(BaseModel):
    topic: str
    slides: list[SlideContent]

class NotesResponse(BaseModel):
    topic: str
    summary: str
    key_points: list[str]
    detailed_notes: str

class QuizQuestion(BaseModel):
    question: str
    options: list[str]
    correct_answer: str
    explanation: str

class QuizResponse(BaseModel):
    topic: str
    questions: list[QuizQuestion]

class ChatRequest(BaseModel):
    message: str
    conversation_history: Optional[list[dict]] = []

class ChatResponse(BaseModel):
    response: str
