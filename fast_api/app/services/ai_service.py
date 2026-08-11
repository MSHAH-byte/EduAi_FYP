import os
import json
import httpx
from dotenv import load_dotenv

load_dotenv()

OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma3:4b")


async def call_ollama(prompt: str) -> str:
    async with httpx.AsyncClient(timeout=120) as client:
        response = await client.post(
            OLLAMA_URL,
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
            },
        )
        response.raise_for_status()
    return response.json()["response"]


def clean_json(text):
    text = text.strip()

    # Remove markdown JSON wrapper if AI returns ```json ... ```
    if text.startswith("```"):
        text = text.split("```")[1]

        if text.startswith("json"):
            text = text[4:]

    text = text.strip()

    try:
        return json.loads(text)

    except json.JSONDecodeError:
        # Fix common AI formatting issues
        text = text.replace("\n", "\\n")
        text = text.replace("\t", "\\t")

        return json.loads(text)


async def generate_slides(topic: str, num_slides: int = 5) -> dict:

    prompt = f"""
Create {num_slides} lecture slides for the topic: "{topic}".

Return ONLY valid JSON:

{{
"topic": "{topic}",
"slides": [
{{
"title": "",
"content": "",
"bullet_points": []
}}
]
}}

No markdown.
"""

    raw = await call_ollama(prompt)
    return clean_json(raw)


async def generate_notes(topic: str) -> dict:

    prompt = f"""
Create structured study notes for:
"{topic}"

Return ONLY valid JSON:

{{
"topic": "{topic}",
"summary": "Short summary",
"key_points": [
"Point 1",
"Point 2",
"Point 3",
"Point 4",
"Point 5"
],
"detailed_notes": "Write detailed notes as a single paragraph without line breaks"
}}

Rules:
- key_points MUST contain EXACTLY 5 items, no more, no less
- Return only JSON
- No markdown
- No explanations outside JSON
"""

    raw = await call_ollama(prompt)
    return clean_json(raw)


async def generate_quiz(topic: str, num_questions: int = 5) -> dict:

    prompt = f"""
Create {num_questions} MCQ questions for:
"{topic}"

Return ONLY valid JSON:

{{
"topic": "{topic}",
"questions": [
{{
"question": "",
"options": [
"Option A",
"Option B",
"Option C",
"Option D"
],
"correct_answer": "",
"explanation": ""
}}
]
}}

No markdown.
"""

    raw = await call_ollama(prompt)
    return clean_json(raw)


async def chat_with_ai(message: str, history: list[dict]) -> str:

    context = ""
    for msg in history[-6:]:
        role = msg.get("role", "user")
        content = msg.get("content", "")
        context += f"{role}: {content}\n"

    prompt = f"""You are an AI Teaching Assistant helping students.

Conversation history:
{context}

Student: {message}

Respond naturally and helpfully."""

    raw = await call_ollama(prompt)
    return raw.strip()