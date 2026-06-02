import os
import re
import struct
from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path

import pyperclip
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, File, Header, HTTPException, Request, UploadFile, status
from fastapi.responses import FileResponse
from pydantic import BaseModel


load_dotenv()

API_TOKEN = os.getenv("API_TOKEN")
BASE_DIR = Path(__file__).resolve().parent
IMAGE_UPLOAD_DIR = BASE_DIR / "uploads" / "images"
FILE_UPLOAD_DIR = BASE_DIR / "uploads" / "files"
UPLOAD_ROOT_DIR = BASE_DIR / "uploads"
MAX_UPLOAD_FILES = 5

app = FastAPI(title="Clipboard Sync API")


class ClipboardRequest(BaseModel):
    text: str


class ClipboardResponse(BaseModel):
    text: str


class UploadResponse(BaseModel):
    filename: str
    path: str
    clipboard_set: bool
    clipboard_error: str | None = None


def verify_api_key(x_api_key: str | None = Header(default=None)) -> None:
    if not API_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="API_TOKEN is not configured",
        )

    if x_api_key != API_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
        )


@app.get("/clipboard/text", response_model=ClipboardResponse)
def get_clipboard_text(_: None = Depends(verify_api_key)) -> ClipboardResponse:
    return ClipboardResponse(text=pyperclip.paste())


@app.post("/clipboard/text", response_model=ClipboardResponse)
async def set_clipboard_text(
    request: Request,
    _: None = Depends(verify_api_key),
) -> ClipboardResponse:
    text = await read_clipboard_text(request)
    pyperclip.copy(text)
    return ClipboardResponse(text=text)


@app.post("/clipboard/image", response_model=UploadResponse)
async def upload_image(
    file: UploadFile = File(...),
    _: None = Depends(verify_api_key),
) -> UploadResponse:
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file must be an image",
        )

    saved_path = await save_upload(file, IMAGE_UPLOAD_DIR)
    clipboard_set, clipboard_error = copy_image_to_windows_clipboard(saved_path)
    return build_upload_response(saved_path, clipboard_set, clipboard_error)


@app.get("/clipboard/image/latest")
def get_latest_image(_: None = Depends(verify_api_key)) -> FileResponse:
    return latest_file_response(IMAGE_UPLOAD_DIR)


@app.post("/clipboard/file", response_model=UploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    _: None = Depends(verify_api_key),
) -> UploadResponse:
    saved_path = await save_upload(file, FILE_UPLOAD_DIR)
    clipboard_set, clipboard_error = copy_file_to_windows_clipboard(saved_path)
    return build_upload_response(saved_path, clipboard_set, clipboard_error)


@app.get("/clipboard/file/latest")
def get_latest_file(_: None = Depends(verify_api_key)) -> FileResponse:
    return latest_file_response(FILE_UPLOAD_DIR)


# Backward-compatible aliases for the earlier text-only API.
@app.get("/clipboard", response_model=ClipboardResponse)
def get_clipboard(_: None = Depends(verify_api_key)) -> ClipboardResponse:
    return get_clipboard_text()


@app.post("/clipboard", response_model=ClipboardResponse)
async def set_clipboard(
    request: Request,
    _: None = Depends(verify_api_key),
) -> ClipboardResponse:
    return await set_clipboard_text(request)


async def read_clipboard_text(request: Request) -> str:
    content_type = request.headers.get("content-type", "").lower()

    if "application/json" in content_type:
        try:
            payload = await request.json()
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid JSON body",
            ) from exc

        if not isinstance(payload, dict) or not isinstance(payload.get("text"), str):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail='JSON body must be like {"text": "clipboard text"}',
            )

        return ClipboardRequest(text=payload["text"]).text

    body = await request.body()
    return body.decode("utf-8")


async def save_upload(upload: UploadFile, upload_dir: Path) -> Path:
    upload_dir.mkdir(parents=True, exist_ok=True)
    filename = safe_timestamped_filename(upload.filename)
    destination = resolve_inside(upload_dir, filename)

    with destination.open("wb") as output:
        while chunk := await upload.read(1024 * 1024):
            output.write(chunk)

    await upload.close()
    prune_uploads()
    return destination


def safe_timestamped_filename(filename: str | None) -> str:
    original_name = Path(filename or "upload").name
    stem = Path(original_name).stem or "upload"
    suffix = Path(original_name).suffix

    safe_stem = re.sub(r"[^A-Za-z0-9._-]+", "_", stem).strip("._-") or "upload"
    safe_suffix = re.sub(r"[^A-Za-z0-9.]+", "", suffix)[:20]
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")

    return f"{timestamp}_{safe_stem}{safe_suffix}"


def resolve_inside(base_dir: Path, filename: str) -> Path:
    base = base_dir.resolve()
    destination = (base / filename).resolve()

    if base != destination.parent:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid filename",
        )

    return destination


def latest_file_response(upload_dir: Path) -> FileResponse:
    upload_dir.mkdir(parents=True, exist_ok=True)
    files = [path for path in upload_dir.iterdir() if path.is_file()]

    if not files:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No uploaded files found",
        )

    latest = max(files, key=lambda path: path.stat().st_mtime_ns)
    return FileResponse(path=latest, filename=latest.name)


def prune_uploads() -> None:
    files = [
        path
        for upload_dir in (IMAGE_UPLOAD_DIR, FILE_UPLOAD_DIR)
        for path in upload_dir.glob("*")
        if path.is_file()
    ]

    files.sort(key=lambda path: path.stat().st_mtime_ns, reverse=True)

    for old_file in files[MAX_UPLOAD_FILES:]:
        old_file.unlink(missing_ok=True)


def build_upload_response(
    saved_path: Path,
    clipboard_set: bool,
    clipboard_error: str | None,
) -> UploadResponse:
    return UploadResponse(
        filename=saved_path.name,
        path=str(saved_path.relative_to(BASE_DIR)),
        clipboard_set=clipboard_set,
        clipboard_error=clipboard_error,
    )


def copy_image_to_windows_clipboard(image_path: Path) -> tuple[bool, str | None]:
    try:
        import win32clipboard
        from PIL import Image

        with Image.open(image_path) as image:
            output = BytesIO()
            image.convert("RGB").save(output, "BMP")
            dib_data = output.getvalue()[14:]

        win32clipboard.OpenClipboard()
        try:
            win32clipboard.EmptyClipboard()
            win32clipboard.SetClipboardData(win32clipboard.CF_DIB, dib_data)
        finally:
            win32clipboard.CloseClipboard()

        return True, None
    except Exception as exc:
        return False, str(exc)


def copy_file_to_windows_clipboard(file_path: Path) -> tuple[bool, str | None]:
    try:
        import win32clipboard
        import win32con

        # DROPFILES structure + UTF-16LE absolute path list + double null terminator.
        encoded_paths = (str(file_path.resolve()) + "\0\0").encode("utf-16le")
        dropfiles = struct.pack("IiiII", 20, 0, 0, 0, 1)
        clipboard_data = dropfiles + encoded_paths

        win32clipboard.OpenClipboard()
        try:
            win32clipboard.EmptyClipboard()
            win32clipboard.SetClipboardData(win32con.CF_HDROP, clipboard_data)
        finally:
            win32clipboard.CloseClipboard()

        return True, None
    except Exception as exc:
        return False, str(exc)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8787)
