"""
Terminal-Based Python Exam System - FastAPI Backend
Deployed on Vercel as a serverless function
Submission-only system - TAs download submissions for manual grading
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import io
import zipfile
from vercel_blob import put

app = FastAPI(title="Python Exam System API")


# File size limit: 10MB
MAX_FILE_SIZE = 10 * 1024 * 1024


@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "message": "Python Exam System API - Submission Only",
        "version": "2.0.0",
        "endpoints": {
            "submit": "POST /api/submit"
        }
    }


@app.post("/api/submit")
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
        
        # Upload to Vercel Blob Storage
        blob_path = f"submissions/{file.filename}"
        
        try:
            blob = put(
                pathname=blob_path,
                body=content,
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


# Vercel requires a handler for the serverless function
handler = app
