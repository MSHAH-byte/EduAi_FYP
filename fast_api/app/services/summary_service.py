"""
Summarization orchestration.

This is the ONLY file that knows which model is being used. When the
trained model arrives later, only `_run_model` below changes; nothing
else in the document-upload feature is affected.

Chunking matters here: a small local model has a limited context window, so a
long document is summarized map-reduce style — summarize each chunk, then
summarize the chunk summaries into one final result.
"""

# ---------------------------------------------------------------------------
# >>> MODEL ADAPTER — the one place you change when swapping models <<<
# ---------------------------------------------------------------------------
#
# Wired to call_ollama() in app/services/ai_service.py, which is already a
# clean prompt-in / text-out async function. The existing generate_* and
# chat_with_ai functions are untouched and keep using it as before.

import httpx

from app.services.ai_service import call_ollama

class SummarizationError(Exception):
    """Raised when the model layer fails or returns nothing usable."""

async def _run_model(prompt: str) -> str:
    """Single call into the model layer. Swap the body, keep the signature."""
    try:
        response = await call_ollama(prompt)
    except httpx.ConnectError as exc:
        raise SummarizationError(
            "Could not connect to Ollama on localhost:11434. "
            "Is `ollama serve` running?"
        ) from exc
    except httpx.ReadTimeout as exc:
        raise SummarizationError(
            "The model took too long to respond. Try a shorter document, "
            "or lower CHUNK_CHAR_LIMIT in summary_service.py."
        ) from exc
    except httpx.HTTPStatusError as exc:
        # 404 from Ollama means the model name isn't pulled locally.
        if exc.response.status_code == 404:
            raise SummarizationError(
                "Ollama does not have that model. Check that OLLAMA_MODEL in "
                "your .env matches a name shown by `ollama list`."
            ) from exc
        raise SummarizationError(
            f"Ollama returned an error ({exc.response.status_code})."
        ) from exc

    return _strip_preamble((response or "").strip())

# ---------------------------------------------------------------------------
# Chunking configuration
# ---------------------------------------------------------------------------

# call_ollama sets num_ctx to 8192, so ~12000 chars (~3k tokens) still leaves
# ample room for the response. Bigger chunks mean fewer sequential model calls,
# which is the single biggest factor in upload speed on CPU-only inference.
CHUNK_CHAR_LIMIT = 12000      # ~3k tokens per chunk
CHUNK_OVERLAP = 300           # keeps sentences from being cut across chunks
MAX_CHUNKS = 25               # safety ceiling on very long documents

# Openers a chatty instruct model tends to prepend despite being told not to.
_PREAMBLE_MARKERS = (
    "here's the",
    "here is the",
    "okay,",
    "ok,",
    "sure,",
    "certainly,",
    "of course,",
)

def _strip_preamble(text: str) -> str:
    """
    Drop a leading conversational line such as
    "Okay, here's the combined summary as requested:".

    Prompting alone does not reliably suppress this on small instruct models,
    so this is a cheap safety net. Only the FIRST line is ever considered, and
    only if it is short and ends in a colon — so real summary text is never cut.
    """
    if not text:
        return text

    first, sep, rest = text.partition("\n")
    candidate = first.strip()

    if not sep or not rest.strip():
        return text

    lowered = candidate.lower()
    looks_like_preamble = (
        candidate.endswith(":")
        and len(candidate) < 120
        and any(lowered.startswith(m) for m in _PREAMBLE_MARKERS)
    )

    return rest.strip() if looks_like_preamble else text

def _split_into_chunks(text: str) -> list[str]:
    if len(text) <= CHUNK_CHAR_LIMIT:
        return [text]

    chunks: list[str] = []
    start = 0
    while start < len(text) and len(chunks) < MAX_CHUNKS:
        end = start + CHUNK_CHAR_LIMIT

        # Prefer to break on a paragraph boundary near the end of the window.
        if end < len(text):
            boundary = text.rfind("\n\n", start + CHUNK_CHAR_LIMIT // 2, end)
            if boundary != -1:
                end = boundary

        chunks.append(text[start:end].strip())

        # Step back by the overlap, but never so far that we fail to progress.
        next_start = end - CHUNK_OVERLAP
        start = next_start if next_start > start else end

    return [c for c in chunks if c]

def _chunk_prompt(chunk: str, index: int, total: int) -> str:
    """
    Prompt for one chunk.

    When the document fits in a single chunk this output IS the final answer,
    so it asks for the full treatment (length + follow-up questions). When
    there are several chunks this is only an intermediate summary, and the
    reduce pass adds the questions instead.
    """
    is_final = total == 1

    if is_final:
        return (
            "You are a teaching assistant helping a student understand a document.\n"
            "Read the document below and write a detailed summary.\n\n"
            "Requirements:\n"
            "- The summary must be AT LEAST 150 words\n"
            "- Cover the main topics, key definitions, and important details\n"
            "- Write clear, flowing prose in paragraphs\n"
            "- Do not invent information that is not in the document\n"
            "- Begin directly with the summary, with no preamble or heading\n\n"
            "After the summary, add a blank line and then exactly this section:\n\n"
            "Questions to consider:\n"
            "1. <a question about the document's content>\n"
            "2. <a second, different question about the document's content>\n\n"
            "--- DOCUMENT ---\n"
            f"{chunk}\n"
            "--- END DOCUMENT ---\n\n"
            "Summary:"
        )

    return (
        "You are a teaching assistant summarizing course material for a student.\n"
        f"Summarize the following document extract (part {index} of {total}).\n"
        "Cover the main topics, definitions and any key points a student should know.\n"
        "Be thorough — this will be combined with other parts later.\n"
        "Write clear prose. Do not invent information that is not in the text.\n"
        "Begin directly with the summary. Do not write any preamble, "
        "acknowledgement, or heading.\n\n"
        "--- DOCUMENT EXTRACT ---\n"
        f"{chunk}\n"
        "--- END EXTRACT ---\n\n"
        "Summary:"
    )


def _reduce_prompt(partials: list[str]) -> str:
    joined = "\n\n".join(
        f"Part {i}: {p}" for i, p in enumerate(partials, start=1)
    )
    return (
        "You are a teaching assistant. Below are summaries of consecutive parts "
        "of a single document. Combine them into one coherent summary of the "
        "whole document.\n\n"
        "Requirements:\n"
        "- The combined summary must be AT LEAST 150 words\n"
        "- Remove repetition and organise it logically\n"
        "- Write clear, flowing prose in paragraphs\n"
        "- Begin directly with the summary, with no preamble or heading\n\n"
        "After the summary, add a blank line and then exactly this section:\n\n"
        "Questions to consider:\n"
        "1. <a question about the document's content>\n"
        "2. <a second, different question about the document's content>\n\n"
        f"{joined}\n\n"
        "Combined summary:"
    )


async def summarize_document(text: str) -> tuple[str, int]:
    """
    Summarize extracted document text.

    Returns (summary, chunks_processed). Raises SummarizationError if the
    model layer fails or returns an empty response.
    """
    chunks = _split_into_chunks(text)

    try:
        partials: list[str] = []
        for index, chunk in enumerate(chunks, start=1):
            partial = await _run_model(_chunk_prompt(chunk, index, len(chunks)))
            if partial:
                partials.append(partial)

        if not partials:
            raise SummarizationError("The model returned an empty summary.")

        if len(partials) == 1:
            return partials[0], len(chunks)

        combined = await _run_model(_reduce_prompt(partials))
        if not combined:
            # Fall back to the concatenated partials rather than failing outright.
            combined = "\n\n".join(partials)

        return combined, len(chunks)

    except SummarizationError:
        raise
    except Exception as exc:
        # Connection refused here almost always means Ollama isn't running.
        raise SummarizationError(f"The AI model could not be reached: {exc}") from exc