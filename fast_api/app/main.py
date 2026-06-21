from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.routes import generate, chat

app = FastAPI(
    title="AI Teaching Assistant API",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(generate.router, prefix="/api/v1/generate", tags=["Generate"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])

@app.get("/")
async def root():
    return {"status": "AI Teaching Assistant API is running"}
