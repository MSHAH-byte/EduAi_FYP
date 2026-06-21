import os
import json
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

async def generate_slides(topic: str, num_slides: int = 5) -> dict:
    prompt = f"""
    Create {num_slides} lecture slides for the topic: "{topic}".
    Return ONLY a valid JSON object with this exact structure:
    {{
        "topic": "{topic}",
        "slides": [
            {{
                "title": "Slide title here",
                "content": "Main content of the slide",
                "bullet_points": ["Point 1", "Point 2", "Point 3"]
            }}
        ]
    }}
    Return only JSON, no markdown, no explanation.
    """
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    text = response.text.strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
    return json.loads(text.strip())

async def generate_notes(topic: str) -> dict:
    prompt = f"""
    Create structured study notes for the topic: "{topic}".
    Return ONLY a valid JSON object with this exact structure:
    {{
        "topic": "{topic}",
        "summary": "Brief summary in 2-3 sentences",
        "key_points": ["Key point 1", "Key point 2", "Key point 3", "Key point 4", "Key point 5"],
        "detailed_notes": "Detailed explanation of the topic in paragraph form"
    }}
    Return only JSON, no markdown, no explanation.
    """
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    text = response.text.strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
    return json.loads(text.strip())

async def generate_quiz(topic: str, num_questions: int = 5) -> dict:
    prompt = f"""
    Create a quiz with {num_questions} multiple choice questions for the topic: "{topic}".
    Return ONLY a valid JSON object with this exact structure:
    {{
        "topic": "{topic}",
        "questions": [
            {{
                "question": "Question text here?",
                "options": ["Option A", "Option B", "Option C", "Option D"],
                "correct_answer": "Option A",
                "explanation": "Brief explanation of why this is correct"
            }}
        ]
    }}
    Return only JSON, no markdown, no explanation.
    """
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    text = response.text.strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
    return json.loads(text.strip())

async def chat_with_ai(message: str, history: list[dict]) -> str:
    context = ""
    if history:
        for msg in history[-6:]:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            context += f"{role}: {content}\n"

    prompt = f"""
    You are an AI Teaching Assistant helping students learn.
    You can generate slides, notes, quizzes, and answer academic questions.
    Be helpful, clear, and educational.

    Conversation history:
    {context}

    Student: {message}

    Respond naturally and helpfully.
    """
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    return response.text.strip()