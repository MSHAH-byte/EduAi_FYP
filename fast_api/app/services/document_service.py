"""
Document text extraction.

Deliberately knows nothing about FastAPI and nothing about the AI model.
Input: raw bytes + original filename. Output: plain text.
This makes it unit-testable on its own and keeps the route thin.
"""

import io
import re

from pypdf import PdfReader
from docx import Document as DocxDocument

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MAX_FILE_BYTES = 10 * 1024 * 1024          # 10 MB
SUPPORTED_EXTENSIONS = {".pdf", ".docx"}
MIN_USEFUL_CHARS = 30                       # below this we treat it as empty

# ---------------------------------------------------------------------------
# Typed errors — the route maps these to HTTP status codes
# ---------------------------------------------------------------------------

class DocumentError(Exception):
    """Base class for all document processing failures."""

class UnsupportedFileTypeError(DocumentError):
    pass

class FileTooLargeError(DocumentError):
    pass

class EmptyDocumentError(DocumentError):
    pass

class CorruptDocumentError(DocumentError):
    pass

# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------

def _extension_of(filename: str) -> str:
    if "." not in filename:
        return ""
    return "." + filename.rsplit(".", 1)[-1].lower()

def _clean(text: str) -> str:
    """Collapse the whitespace noise that PDF extraction always produces."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()

def _extract_pdf(data: bytes) -> str:
    try:
        reader = PdfReader(io.BytesIO(data))
    except Exception as exc:
        raise CorruptDocumentError("The PDF could not be opened.") from exc

    if reader.is_encrypted:
        # Some PDFs are encrypted with an empty owner password; try that first.
        try:
            reader.decrypt("")
        except Exception as exc:
            raise CorruptDocumentError(
                "This PDF is password protected."
            ) from exc

    parts: list[str] = []
    for page in reader.pages:
        try:
            parts.append(page.extract_text() or "")
        except Exception:
            # One bad page shouldn't kill the whole document.
            continue

    return _clean("\n\n".join(parts))

def _extract_docx(data: bytes) -> str:
    try:
        document = DocxDocument(io.BytesIO(data))
    except Exception as exc:
        raise CorruptDocumentError("The DOCX file could not be opened.") from exc

    parts: list[str] = [p.text for p in document.paragraphs if p.text.strip()]

    # Table content is often where the syllabus/outline actually lives.
    for table in document.tables:
        for row in table.rows:
            cells = [cell.text.strip() for cell in row.cells if cell.text.strip()]
            if cells:
                parts.append(" | ".join(cells))

    return _clean("\n".join(parts))

def extract_text(filename: str, data: bytes) -> str:
    """
    Validate and extract text from an uploaded document.

    Raises UnsupportedFileTypeError, FileTooLargeError, EmptyDocumentError
    or CorruptDocumentError. Never raises anything else for expected inputs.
    """
    extension = _extension_of(filename or "")

    if extension not in SUPPORTED_EXTENSIONS:
        raise UnsupportedFileTypeError(
            f"Only PDF and DOCX files are supported (received '{extension or 'no extension'}')."
        )

    if not data:
        raise EmptyDocumentError("The uploaded file is empty.")

    if len(data) > MAX_FILE_BYTES:
        size_mb = len(data) / (1024 * 1024)
        raise FileTooLargeError(
            f"File is {size_mb:.1f} MB. The limit is {MAX_FILE_BYTES // (1024 * 1024)} MB."
        )

    text = _extract_pdf(data) if extension == ".pdf" else _extract_docx(data)

    if len(text) < MIN_USEFUL_CHARS:
        raise EmptyDocumentError(
            "No readable text was found. If this is a scanned document, "
            "it would need OCR, which is not supported."
        )

    return text
