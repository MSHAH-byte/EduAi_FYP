import os
import json
from dotenv import load_dotenv
from groq import Groq

load_dotenv()

client = Groq(api_key=os.getenv("XAI_API_KEY"))


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

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )

    return clean_json(response.choices[0].message.content)


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
"Point 3"
],
"detailed_notes": "Write detailed notes as a single paragraph without line breaks"
}}

Rules:
- Return only JSON
- No markdown
- No explanations outside JSON
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )

    return clean_json(response.choices[0].message.content)


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

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )

    return clean_json(response.choices[0].message.content)


async def chat_with_ai(message: str, history: list[dict]) -> str:

    messages = [
        {
            "role": "system",
            "content": "You are an AI Teaching Assistant helping students."
        }
    ]

    for msg in history[-6:]:
        messages.append(
            {
                "role": msg.get("role", "user"),
                "content": msg.get("content", "")
            }
        )

    messages.append(
        {
            "role": "user",
            "content": message
        }
    )

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=messages
    )

    return response.choices[0].message.content.strip()