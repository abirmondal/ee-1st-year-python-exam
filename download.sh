#!/bin/bash

# Terminal-Based Python Exam System - Download Script for TAs
# Helper script to download exam submissions

set -e

# Check for API_BASE_URL environment variable
if [ -z "$API_BASE_URL" ]; then
    echo "API_BASE_URL not set."
    read -p "Enter API Base URL (e.g., https://your-project.vercel.app): " API_BASE_URL
fi

# Ask for DOWNLOAD_SECRET (silent input)
read -s -p "Enter DOWNLOAD_SECRET: " DOWNLOAD_SECRET
echo ""

# Validate that secret was provided
if [ -z "$DOWNLOAD_SECRET" ]; then
    echo "Error: DOWNLOAD_SECRET is required"
    exit 1
fi

# Main menu loop
while true; do
    echo ""
    echo "=== Exam Submission Download Tool ==="
    echo "1. Download ALL submissions for an exam (Batch)"
    echo "2. Download ONE student's submission"
    echo "3. Exit"
    echo ""
    read -p "Choose an option [1-3]: " choice

    case $choice in
        1)
            # Download batch
            read -p "Enter EXAM_CODE: " EXAM_CODE
            
            if [ -z "$EXAM_CODE" ]; then
                echo "Error: EXAM_CODE is required"
                continue
            fi
            
            FILENAME="${EXAM_CODE}_all_submissions.zip"
            URL="${API_BASE_URL}/api/download-batch"
            
            echo "Downloading all submissions for exam: ${EXAM_CODE}..."
            JSON_BODY="{\"exam_code\": \"$EXAM_CODE\", \"secret\": \"$DOWNLOAD_SECRET\"}"
            curl -L -o "$FILENAME" -X POST -H "Content-Type: application/json" -d "$JSON_BODY" "$URL"
            
            # Validate the download
            if [ -f "$FILENAME" ]; then
                FILE_SIZE=$(stat -f%z "$FILENAME" 2>/dev/null || stat -c%s "$FILENAME" 2>/dev/null)
                if [ "$FILE_SIZE" -gt 100 ]; then
                    echo "Download complete: $FILENAME"
                else
                    echo "Download FAILED. Error response:"
                    cat "$FILENAME"
                    rm "$FILENAME"
                fi
            else
                echo "Download FAILED: File not created"
            fi
            ;;
        
        2)
            # Download single
            read -p "Enter EXAM_CODE: " EXAM_CODE
            read -p "Enter STUDENT_ID: " STUDENT_ID
            
            if [ -z "$EXAM_CODE" ] || [ -z "$STUDENT_ID" ]; then
                echo "Error: Both EXAM_CODE and STUDENT_ID are required"
                continue
            fi
            
            FILENAME="${EXAM_CODE}_${STUDENT_ID}.zip"
            URL="${API_BASE_URL}/api/download-single"
            
            echo "Downloading submission for ${STUDENT_ID}..."
            JSON_BODY="{\"exam_code\": \"$EXAM_CODE\", \"student_id\": \"$STUDENT_ID\", \"secret\": \"$DOWNLOAD_SECRET\"}"
            curl -L -o "$FILENAME" -X POST -H "Content-Type: application/json" -d "$JSON_BODY" "$URL"
            
            # Validate the download
            if [ -f "$FILENAME" ]; then
                FILE_SIZE=$(stat -f%z "$FILENAME" 2>/dev/null || stat -c%s "$FILENAME" 2>/dev/null)
                if [ "$FILE_SIZE" -gt 100 ]; then
                    echo "Download complete: $FILENAME"
                else
                    echo "Download FAILED. Error response:"
                    cat "$FILENAME"
                    rm "$FILENAME"
                fi
            else
                echo "Download FAILED: File not created"
            fi
            ;;
        
        3)
            # Exit
            echo "Exiting..."
            exit 0
            ;;
        
        *)
            echo "Invalid option. Please choose 1, 2, or 3."
            ;;
    esac
done
