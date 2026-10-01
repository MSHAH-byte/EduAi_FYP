import os
import json
import httpx
from dotenv import load_dotenv

load_dotenv()

OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma3:4b")

# The Modelfile ships temperature 1.0, which is too loose for strict JSON on a
# small model — it wanders off-format and clean_json fails intermittently.
# Structured endpoints pin it low; chat keeps some warmth.
JSON_TEMPERATURE = 0.3
CHAT_TEMPERATURE = 0.7

# Ollama defaults num_ctx to 4096 regardless of what the model supports, and
# silently truncates anything longer. Raising it lets the summarizer send far
# bigger chunks, which means fewer sequential calls and a much faster upload.
NUM_CTX = 8192


async def call_ollama(
    prompt: str,
    temperature: float = CHAT_TEMPERATURE,
    json_mode: bool = False,
    schema: dict | None = None,
) -> str:
    """
    Call the local model.

    json_mode=True asks Ollama to constrain generation so the output is
    syntactically valid JSON. This is enforced during decoding, so a small
    model cannot emit a truncated or malformed object the way it can when
    only the prompt asks for JSON. Use it for every structured endpoint.
    """
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": temperature,
            "num_ctx": NUM_CTX,
        },
    }
    if schema is not None:
        # A full JSON schema constrains generation far more tightly than
        # format="json" alone: minItems forces the model to keep producing
        # array entries instead of closing the array after one.
        payload["format"] = schema
    elif json_mode:
        payload["format"] = "json"

    async with httpx.AsyncClient(timeout=180) as client:
        response = await client.post(OLLAMA_URL, json=payload)
        response.raise_for_status()
    return response.json()["response"]


def _slides_schema(num_slides: int) -> dict:
    return {
        "type": "object",
        "properties": {
            "topic": {"type": "string"},
            "slides": {
                "type": "array",
                "minItems": num_slides,
                "maxItems": num_slides,
                "items": {
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "content": {"type": "string"},
                        "bullet_points": {
                            "type": "array",
                            "minItems": 3,
                            "maxItems": 3,
                            "items": {"type": "string"},
                        },
                    },
                    "required": ["title", "content", "bullet_points"],
                },
            },
        },
        "required": ["topic", "slides"],
    }


def _quiz_schema(num_questions: int) -> dict:
    return {
        "type": "object",
        "properties": {
            "topic": {"type": "string"},
            "questions": {
                "type": "array",
                "minItems": num_questions,
                "maxItems": num_questions,
                "items": {
                    "type": "object",
                    "properties": {
                        "question": {"type": "string"},
                        "options": {
                            "type": "array",
                            "minItems": 4,
                            "maxItems": 4,
                            "items": {"type": "string"},
                        },
                        "correct_answer": {"type": "string"},
                        "explanation": {"type": "string"},
                    },
                    "required": [
                        "question",
                        "options",
                        "correct_answer",
                        "explanation",
                    ],
                },
            },
        },
        "required": ["topic", "questions"],
    }


async def _generate_with_count(
    prompt: str,
    schema: dict,
    key: str,
    expected: int,
    attempts: int = 2,
) -> dict:
    """
    Call the model and verify the array actually has `expected` entries.

    The schema usually enforces this, but a small model can still fall short.
    One extra attempt is cheap insurance against a short list appearing in a
    demo; whichever attempt is closest to the target is returned.
    """
    best: dict | None = None

    for _ in range(attempts):
        try:
            raw = await call_ollama(
                prompt, temperature=JSON_TEMPERATURE, schema=schema
            )
            data = clean_json(raw)
        except Exception:
            continue

        items = data.get(key) or []
        if len(items) == expected:
            return data
        if best is None or len(items) > len(best.get(key) or []):
            best = data

    if best is None:
        raise ValueError("The model did not return usable JSON.")
    return best


def _extract_json_block(text: str) -> str:
    """
    Pull the first complete {...} object out of a response.

    Small models often wrap JSON in commentary ("Here's the JSON:" before,
    "Hope this helps!" after). Scanning for balanced braces while ignoring
    braces inside strings survives that; requiring a clean response does not.
    """
    start = text.find("{")
    if start == -1:
        return text

    depth = 0
    in_string = False
    escaped = False

    for i in range(start, len(text)):
        ch = text[i]

        if escaped:
            escaped = False
            continue
        if ch == "\\":
            escaped = True
            continue
        if ch == '"':
            in_string = not in_string
            continue
        if in_string:
            continue

        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]

    return text[start:]


def clean_json(text):
    text = text.strip()

    # Remove markdown JSON wrapper if AI returns ```json ... ```
    if text.startswith("```"):
        parts = text.split("```")
        if len(parts) > 1:
            text = parts[1]
        if text.startswith("json"):
            text = text[4:]

    text = text.strip()

    # 1. Straight parse — the happy path.
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # 2. Carve out the JSON object and ignore any surrounding chatter.
    candidate = _extract_json_block(text)
    try:
        return json.loads(candidate)
    except json.JSONDecodeError:
        pass

    # 3. Last resort: escape raw control characters inside the block. Some
    #    models emit literal newlines inside string values, which is invalid.
    repaired = candidate.replace("\n", "\\n").replace("\t", "\\t")
    try:
        return json.loads(repaired)
    except json.JSONDecodeError as exc:
        # Printed so a failure is diagnosable from the uvicorn console rather
        # than surfacing as an opaque 500.
        print("=== RAW MODEL OUTPUT (unparseable) ===")
        print(text[:2000])
        print("=== END RAW MODEL OUTPUT ===")
        raise ValueError(
            f"The model did not return valid JSON: {exc}"
        ) from exc


async def generate_slides(topic: str, num_slides: int = 5) -> dict:

    # Build a skeleton containing exactly num_slides slots. A small model
    # copies the shape it is shown, so a one-item example produces one slide
    # no matter what the instruction above it says.
    slots = ",\n".join(
        f'{{"title": "Slide {i} title", "content": "", "bullet_points": ["", "", ""]}}'
        for i in range(1, num_slides + 1)
    )

    prompt = f"""
Create exactly {num_slides} lecture slides for the topic: "{topic}".

Fill in this JSON structure. It already contains {num_slides} slide objects —
keep all {num_slides} of them and replace the empty values with real content.

{{
"topic": "{topic}",
"slides": [
{slots}
]
}}

Rules:
- The "slides" array MUST contain exactly {num_slides} objects
- Return only the JSON object, nothing before or after it
- Do NOT use markdown formatting such as **, *, or # inside any field value
- "content" must be plain prose, 2-3 sentences
- Each slide needs 3 short "bullet_points"
"""

    return await _generate_with_count(
        prompt, _slides_schema(num_slides), "slides", num_slides
    )


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
- "summary" should be 3-4 full sentences explaining the topic
- "detailed_notes" should be a thorough paragraph of at least 150 words
- Return only the JSON object, nothing before or after it
- Do NOT use markdown formatting such as **, *, or # inside any field value
"""

    raw = await call_ollama(prompt, temperature=JSON_TEMPERATURE, json_mode=True)
    return clean_json(raw)


async def generate_quiz(topic: str, num_questions: int = 5) -> dict:

    # Same reason as generate_slides: show exactly as many question slots as
    # are wanted, each with exactly four option slots.
    slots = ",\n".join(
        f'{{"question": "Question {i}", "options": ["", "", "", ""], '
        f'"correct_answer": "", "explanation": ""}}'
        for i in range(1, num_questions + 1)
    )

    prompt = f"""
Create exactly {num_questions} multiple choice questions about: "{topic}"

Fill in this JSON structure. It already contains {num_questions} question
objects, each with 4 empty options — keep them all and replace every empty
string with real content.

{{
"topic": "{topic}",
"questions": [
{slots}
]
}}

Rules:
- The "questions" array MUST contain exactly {num_questions} objects
- Every "options" array MUST contain exactly 4 non-empty strings
- "correct_answer" must be copied word for word from one of that question's options
- "explanation" is one sentence saying why that answer is correct
- Return only the JSON object, nothing before or after it
- Do NOT add any commentary before or after the JSON
- Do NOT use markdown formatting such as **, *, or # inside any field value
"""

    return await _generate_with_count(
        prompt, _quiz_schema(num_questions), "questions", num_questions
    )


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