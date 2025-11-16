"""
Terminal-Based Python Exam System - FastAPI Backend
Deployed on Vercel as a serverless function
Submission-only system - TAs download submissions for manual grading
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse, HTMLResponse, StreamingResponse
import io
import os
import zipfile
import requests
from vercel_blob import put
from vercel_blob import list as blob_list
from pydantic import BaseModel

# Define the tags for the API docs
tags_metadata = [
    {
        "name": "Student Actions",
        "description": "Endpoints used by the student's `submit.sh` script.",
    },
    {
        "name": "Instructor Tools",
        "description": "Secure endpoints for TAs to download submissions.",
    },
    {
        "name": "General",
        "description": "The root status page.",
    },
]

app = FastAPI(title="Python Exam System API", openapi_tags=tags_metadata)

# Batch download request model, used for post requests
class BatchDownloadRequest(BaseModel):
    exam_code: str
    secret: str

# Single download request model, used for post requests
class SingleDownloadRequest(BaseModel):
    exam_code: str
    student_id: str
    secret: str

# File size limit: 10MB
MAX_FILE_SIZE = 10 * 1024 * 1024


@app.get("/", response_class=HTMLResponse, tags=["General"])
async def root():
    """Root endpoint - API information"""
    html_content = """
    <html>
        <head>
            <title>Exam System API</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    background-color: #f7f9fc;
                    margin: 0;
                    padding: 20px;
                    box-sizing: border-box;
                }
                .card {
                    background-color: #ffffff;
                    border-radius: 16px;
                    box-shadow: 0 10px 40px rgba(0,0,0,0.07);
                    width: 100%;
                    max-width: 600px;
                    padding: 48px;
                    box-sizing: border-box;
                    text-align: center;
                }
                h1 {
                    font-size: 28px;
                    font-weight: 700;
                    color: #111;
                    margin-top: 0;
                    margin-bottom: 16px;
                }
                p {
                    font-size: 17px;
                    color: #555;
                    line-height: 1.7;
                    margin-bottom: 16px;
                }
                code {
                    font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
                    background-color: #f0f0f0;
                    padding: 4px 8px;
                    border-radius: 6px;
                    font-size: 0.95em;
                    color: #111;
                }
                .footer {
                    margin-top: 32px;
                    padding-top: 32px;
                    border-top: 1px solid #eaeaea;
                    font-size: 15px;
                    color: #777;
                }
                .footer p {
                    font-size: 15px;
                    color: #777;
                    margin-bottom: 10px;
                }
                a {
                    color: #0070f3;
                    text-decoration: none;
                    font-weight: 500;
                }
                a:hover {
                    text-decoration: underline;
                }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>Python Exam System API</h1>
                <p>This is the backend API for the terminal-based exam system.</p>
                <p>The API is active. The submission endpoint is at <code>/api/submit</code>.</p>
                
                <div class="footer">
                    <p>
                        Instructors: See the 
                        <a href="https://github.com/abirmondal/py-exam-cli" target="_blank">GitHub repository</a> 
                        for setup instructions.
                    </p>
                    <p>Instructor Download (Batch): <code>/api/download-batch</code></p>
                    <p>Instructor Download (Single): <code>/api/download-single</code></p>
                    <p style="margin-top:20px;">
                        ⭐ If you find this project useful, please consider giving it a star on 
                        <a href="https://github.com/abirmondal/py-exam-cli" target="_blank">GitHub</a>!
                    </p>
                    <p style="margin-top:20px; font-size: 14px; color: #999;">
                        Developed by Abir Mondal
                    </p>
                </div>
            </div>
        </body>
    </html>
    """
    return HTMLResponse(content=html_content, status_code=200)


@app.post("/api/submit", tags=["Student Actions"])
async def submit_exam(file: UploadFile = File(...)):
    """
    Submit exam answers.
    Accepts a zip file containing solution files.
    Saves to Vercel Blob Storage.
    """
    
    # Validate content type
    valid_content_types = [
        "application/zip",
        "application/x-zip-compressed",
        "application/octet-stream"  # Sometimes zip files come as this
    ]
    
    if file.content_type not in valid_content_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Expected ZIP file, got {file.content_type}"
        )
    
    # Validate filename
    if not file.filename or not file.filename.endswith('.zip'):
        raise HTTPException(
            status_code=400,
            detail="Invalid filename. File must have a .zip extension"
        )
    
    try:
        # Read file content
        content = await file.read()
        
        # Validate file size
        if len(content) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Maximum size is {MAX_FILE_SIZE / (1024*1024)}MB"
            )
        
        if len(content) == 0:
            raise HTTPException(
                status_code=400,
                detail="File is empty"
            )
        
        # Validate that it's actually a zip file
        try:
            with zipfile.ZipFile(io.BytesIO(content)) as zf:
                # Just check if we can open it
                zf.namelist()
        except zipfile.BadZipFile:
            raise HTTPException(
                status_code=400,
                detail="Invalid ZIP file. File appears to be corrupted."
            )
        
        # Sanitize the filename to prevent path traversal
        safe_filename = os.path.basename(file.filename)
        # Upload to Vercel Blob Storage
        blob_path = f"submissions/{safe_filename}"
        
        try:
            blob = put(
                blob_path,
                content,
                options={
                    'access': 'private',
                    'addRandomSuffix': False
                }
            )
            
            return JSONResponse(
                status_code=200,
                content={
                    "status": "success",
                    "message": "Submission received successfully",
                    "filename": file.filename,
                    "url": blob.get('url'),
                    "size": len(content)
                }
            )
            
        except Exception as e:
            # Vercel Blob upload failed
            raise HTTPException(
                status_code=500,
                detail=f"Failed to save submission: {str(e)}"
            )
            
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Catch any other unexpected errors
        raise HTTPException(
            status_code=500,
            detail=f"An unexpected error occurred: {str(e)}"
        )


@app.post("/api/download-batch", tags=["Instructor Tools"])
async def download_batch(request: BatchDownloadRequest):
    """
    Download all submissions for a given exam code as a single zip file.
    Requires authentication via DOWNLOAD_SECRET environment variable.
    """
    # Security: Validate secret
    download_secret = os.environ.get("DOWNLOAD_SECRET")
    if not download_secret or download_secret != request.secret:
        raise HTTPException(
            status_code=401,
            detail="Unauthorized: Invalid or missing secret"
        )
    
    # Validate exam_code
    if not request.exam_code or not request.exam_code.strip():
        raise HTTPException(
            status_code=400,
            detail="Exam code is required"
        )
    
    # Construct the file prefix for submissions
    file_prefix = f"submissions/{request.exam_code}_"
    
    try:
        # List all blobs matching the prefix
        result = blob_list(options={'prefix': file_prefix})
        blobs = result.get('blobs', [])
        
        # Check if any submissions exist
        if not blobs:
            raise HTTPException(
                status_code=404,
                detail=f"No submissions found for exam code: {request.exam_code}"
            )
        
        # Create a zip file in memory
        memory_zip = io.BytesIO()
        
        with zipfile.ZipFile(memory_zip, 'w', zipfile.ZIP_DEFLATED) as main_zip:
            for blob in blobs:
                try:
                    # Download the student's zip file
                    blob_url = blob.get('url')
                    response = requests.get(blob_url)
                    response.raise_for_status()  # Will raise an error if download fails
                    student_zip_content = response.content
                    
                    # Extract student_id from the pathname
                    # Format: submissions/{exam_code}_{student_id}.zip
                    pathname = blob.get('pathname', '')
                    filename = pathname.split('/')[-1]  # Get the filename
                    student_id = filename.replace(f"{request.exam_code}_", "").replace(".zip", "")
                    
                    # Unzip the student's submission in memory
                    student_zip = io.BytesIO(student_zip_content)
                    
                    with zipfile.ZipFile(student_zip, 'r') as student_zf:
                        # Add each file from student's zip to the main zip
                        # Place them in a folder named after the student_id
                        for file_info in student_zf.infolist():
                            file_data = student_zf.read(file_info.filename)
                            # Create new path: student_id/original_filename
                            new_path = f"{student_id}/{file_info.filename}"
                            main_zip.writestr(new_path, file_data)
                
                except Exception as e:
                    # If one student's zip is corrupt, log error and continue
                    error_msg = f"Error processing submission: {str(e)}\n"
                    error_path = f"{student_id}/_ERROR.txt"
                    main_zip.writestr(error_path, error_msg)
                    continue
        
        # Seek to the beginning of the in-memory zip
        memory_zip.seek(0)
        
        # Return the zip file as a streaming response
        filename = f"{request.exam_code}_all_submissions.zip"
        return StreamingResponse(
            memory_zip,
            media_type="application/zip",
            headers={
                "Content-Disposition": f"attachment; filename={filename}"
            }
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create batch download: {str(e)}"
        )


@app.post("/api/download-single", tags=["Instructor Tools"])
async def download_single(request: SingleDownloadRequest):
    """
    Download a single student's submission.
    Requires authentication via DOWNLOAD_SECRET environment variable.
    """
    # Security: Validate secret
    download_secret = os.environ.get("DOWNLOAD_SECRET")
    if not download_secret or download_secret != request.secret:
        raise HTTPException(
            status_code=401,
            detail="Unauthorized: Invalid or missing secret"
        )
    
    # Validate parameters
    if not request.exam_code or not request.exam_code.strip():
        raise HTTPException(
            status_code=400,
            detail="Exam code is required"
        )
    
    if not request.student_id or not request.student_id.strip():
        raise HTTPException(
            status_code=400,
            detail="Student ID is required"
        )
    
    # Construct the exact blob path
    blob_path = f"submissions/{request.exam_code}_{request.student_id}.zip"
    
    try:
        # 1. List blobs to find the exact file
        result = blob_list(options={'prefix': blob_path})
        blobs = result.get('blobs', [])

        # 2. Find the exact match
        blob_url = None
        for blob in blobs:
            if blob.get('pathname') == blob_path:
                blob_url = blob.get('url')
                break

        # 3. If no match, raise 404
        if not blob_url:
            raise HTTPException(
                status_code=404,
                detail=f"Submission not found for exam code: {request.exam_code}, student ID: {request.student_id}"
            )

        # 4. Download the file using requests
        response = requests.get(blob_url)
        response.raise_for_status()  # Check for download errors
        file_data = response.content

        # Create a streaming response
        file_stream = io.BytesIO(file_data)
        filename = f"{request.exam_code}_{request.student_id}.zip"

        return StreamingResponse(
            file_stream,
            media_type="application/zip",
            headers={
                "Content-Disposition": f"attachment; filename={filename}"
            }
        )

    except HTTPException:
        raise  # Re-raise FastAPI's own errors
    except Exception as e:
        error_message = str(e)
        # Check if the error is a "not_found" error from Vercel Blob
        if "not_found" in error_message.lower():
            raise HTTPException(
                status_code=404,
                detail=f"Submission not found for exam code: {request.exam_code}, student ID: {request.student_id}"
            )
        # Otherwise, return a generic 500
        raise HTTPException(
            status_code=500,
            detail=f"Failed to download submission: {error_message}"
        )
