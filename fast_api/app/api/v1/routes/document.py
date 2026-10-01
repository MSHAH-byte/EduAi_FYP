"""
Document upload + summarization endpoint.

Thin by design: HTTP concerns only. Extraction lives in document_service,
model interaction lives in summary_service.
"""

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool

from app.models.schemas import DocumentSummaryResponse
from app.services.document_service import (
    CorruptDocumentError,
    EmptyDocumentError,
    FileTooLargeError,
    UnsupportedFileTypeError,
    extract_text,
)
from app.services.summary_service import SummarizationError, summarize_document

router = APIRouter()

@router.post("/summarize", response_model=DocumentSummaryResponse)
async def summarize_uploaded_document(file: UploadFile = File(...)):
    data = await file.read()
    filename = file.filename or "document"

    # --- extraction ---------------------------------------------------
    # pypdf and python-docx are blocking, so keep them off the event loop.
    try:
        text = await run_in_threadpool(extract_text, filename, data)
    except UnsupportedFileTypeError as exc:
        raise HTTPException(status_code=415, detail=str(exc))
    except FileTooLargeError as exc:
        raise HTTPException(status_code=413, detail=str(exc))
    except (EmptyDocumentError, CorruptDocumentError) as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    # --- summarization ------------------------------------------------
    try:
        summary, chunks = await summarize_document(text)
    except SummarizationError as exc:
        # 503: the request was fine, the model layer was not.
        raise HTTPException(status_code=503, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Summarization failed: {exc}")

    return DocumentSummaryResponse(
        filename=filename,
        summary=summary,
        character_count=len(text),
        chunks_processed=chunks,
    )
