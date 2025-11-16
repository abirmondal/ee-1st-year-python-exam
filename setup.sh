#!/bin/bash

# Terminal-Based Python Exam System - Setup Script
# This script sets up the exam environment for students

set -e  # Exit on any error

echo "=== Python Exam System - Setup ==="
echo ""

# Prompt for Enrollment ID
read -p "Enter your Enrollment ID: " ENROLLMENT_ID

if [ -z "$ENROLLMENT_ID" ]; then
    echo "Error: Enrollment ID cannot be empty."
    exit 1
fi

# Prompt for Student Name
read -p "Enter your Full Name: " STUDENT_NAME

if [ -z "$STUDENT_NAME" ]; then
    echo "Error: Student Name cannot be empty."
    exit 1
fi

echo ""
echo "Setting up exam for:"
echo "  Name: $STUDENT_NAME"
echo "  Enrollment ID: $ENROLLMENT_ID"
echo "  Exam Code: $EXAM_CODE"
echo ""

# Create isolated exam directory
EXAM_DIR="$HOME/exam_${ENROLLMENT_ID}"

if [ -d "$EXAM_DIR" ]; then
    echo "Error: Directory $EXAM_DIR already exists."
    echo "To restart the exam setup, please manually delete the directory:"
    echo "  rm -rf $EXAM_DIR"
    exit 1
else
    echo "Creating exam directory: $EXAM_DIR"
    mkdir -p "$EXAM_DIR"
fi
cd "$EXAM_DIR"

# Create student_info.txt file
echo "Creating student information file..."
cat > student_info.txt << EOF
ENROLLMENT_ID: $ENROLLMENT_ID
STUDENT_NAME: $STUDENT_NAME
EOF

# Construct download URL for the exam zip file from Vercel Blob
# TODO: Update this URL with your Vercel Blob project's public URL
VERCEL_BLOB_BASE_URL="https://[YOUR-VERCEL-PROJECT-ID].blob.vercel-storage.com"

while true; do
    # Prompt for Exam Code inside the loop
    read -p "Enter the Exam Code: " EXAM_CODE

    if [ -z "$EXAM_CODE" ]; then
        echo "Error: Exam Code cannot be empty. Please try again."
        continue
    fi

    DOWNLOAD_URL="${VERCEL_BLOB_BASE_URL}/public-exams/${EXAM_CODE}.zip"
    echo "Attempting to download exam files from: $DOWNLOAD_URL"

    # Try to download the exam zip file
    if command -v curl &> /dev/null; then
        curl -L -o "${EXAM_CODE}.zip" "$DOWNLOAD_URL" -f -s -S
        DOWNLOAD_STATUS=$?
    elif command -v wget &> /dev/null; then
        wget -q -O "${EXAM_CODE}.zip" "$DOWNLOAD_URL"
        DOWNLOAD_STATUS=$?
    else
        echo "Error: Neither curl nor wget is available. Please contact your TA."
        exit 1
    fi

    # Check if the download was successful
    if [ $DOWNLOAD_STATUS -eq 0 ] && [ -f "${EXAM_CODE}.zip" ]; then
        # Save the correct code to the info file
        echo "EXAM_CODE: $EXAM_CODE" >> student_info.txt
        break # Exit the loop on success
    else
        echo "--------------------------------------------------"
        echo "✗ ERROR: Invalid Exam Code or network issue."
        echo "  Please check the code and try again."
        echo "--------------------------------------------------"
        # Clean up failed download attempt
        rm -f "${EXAM_CODE}.zip"
    fi
done

echo "Download successful!"
echo "Extracting exam files..."

# Extract the exam files using Python's zipfile module
if command -v python3 &> /dev/null; then
    python3 -m zipfile -e "${EXAM_CODE}.zip" .
elif command -v python &> /dev/null; then
    python -m zipfile -e "${EXAM_CODE}.zip" .
else
    echo "Error: Python is not installed. Please install Python 3."
    exit 1
fi

echo "Extraction complete!"

# Set initial file permissions - make all files read-only
echo "Setting initial file permissions..."
chmod -w prob_* 2>/dev/null || true

# Dynamically create start_exam.sh script
echo "Creating exam start script..."

cat << 'START_EXAM_SCRIPT_EOF' > start_exam.sh
#!/bin/bash

# Terminal-Based Python Exam System - Start Exam Script
# This script starts the exam timer and makes solution files editable

echo "=== Starting Exam ==="
echo ""

# Make only solution files writable
echo "Making solution files editable..."
chmod +w prob_* 2>/dev/null || true

# Append start time (UTC) to student_info.txt
echo "START_TIME: $(TZ="Asia/Kolkata" date +'%Y-%m-%d %H:%M:%S %Z')" >> student_info.txt

# Append start timestamp (Unix timestamp)
echo "START_TIMESTAMP: $(date +%s)" >> student_info.txt

echo ""
echo "✓ Exam started successfully!"
echo "✓ Solution files are now editable."
echo ""
echo "When you are finished, run: ./submit.sh"
echo ""
echo "Good luck!"
echo ""
START_EXAM_SCRIPT_EOF

# Dynamically create submit.sh script
echo "Creating submission script..."

cat << 'SUBMIT_SCRIPT_EOF' > submit.sh
#!/bin/bash

# Terminal-Based Python Exam System - Submission Script
# This script submits your exam answers

set -e  # Exit on any error

# Detect Python command
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "Error: Python is not installed. Please install Python 3."
    exit 1
fi

echo "=== Python Exam System - Submission ==="
echo ""

# Get the ORIGINAL Enrollment ID from student_info.txt
if [ ! -f "student_info.txt" ]; then
    echo "Error: student_info.txt not found. Cannot submit."
    exit 1
fi
ORIGINAL_ID=$(grep 'ENROLLMENT_ID:' student_info.txt | cut -d' ' -f2)

# Confirm Enrollment ID loop
while true; do
    read -p "Please confirm your Enrollment ID [$ORIGINAL_ID]: " CONFIRMED_ID

    # Check 1: Is it empty?
    if [ -z "$CONFIRMED_ID" ]; then
        echo "--------------------------------------------------"
        echo "✗ ERROR: ID cannot be empty. Please try again."
        echo "--------------------------------------------------"
        continue
    fi

    # Check 2: Does it match?
    if [ "$CONFIRMED_ID" != "$ORIGINAL_ID" ]; then
        echo "==================================================================="
        echo "✗ ERROR: ID MISMATCH!"
        echo "==================================================================="
        echo "  You entered:    $CONFIRMED_ID"
        echo "  This exam belongs to: $ORIGINAL_ID"
        echo "  Please try again."
        echo "==================================================================="
        continue
    fi
    
    # If we are here, the ID is not empty AND it matches.
    break
done

echo ""

# Record submission time before preparing
echo "SUBMIT_TIME: $(TZ="Asia/Kolkata" date +'%Y-%m-%d %H:%M:%S %Z')" >> student_info.txt
echo "SUBMIT_TIMESTAMP: $(date +%s)" >> student_info.txt

# Calculate total time
START_TIMESTAMP=$(grep 'START_TIMESTAMP:' student_info.txt | cut -d' ' -f2)
SUBMIT_TIMESTAMP=$(grep 'SUBMIT_TIMESTAMP:' student_info.txt | cut -d' ' -f2)

if [ -n "$START_TIMESTAMP" ] && [ -n "$SUBMIT_TIMESTAMP" ]; then
    DURATION=$((SUBMIT_TIMESTAMP - START_TIMESTAMP))
    echo "TOTAL_TIME_SECONDS: $DURATION" >> student_info.txt
else
    echo "TOTAL_TIME_SECONDS: ERROR_CALCULATING" >> student_info.txt
fi

# Lock solution files
echo "Locking files..."
chmod -w prob_* student_info.txt 2>/dev/null || true

echo "Preparing submission for Enrollment ID: $CONFIRMED_ID"
echo ""

# Extract EXAM_CODE from student_info.txt
EXAM_CODE=$(grep 'EXAM_CODE:' student_info.txt | cut -d' ' -f2)

# Create submission zip file name
SUBMISSION_FILE="${EXAM_CODE}_${CONFIRMED_ID}.zip"

# Remove old submission file if it exists
if [ -f "$SUBMISSION_FILE" ]; then
    rm "$SUBMISSION_FILE"
fi

# Create a list of solution files to include
# This includes common patterns for solution files
echo "Collecting solution files..."

# Create temporary list of files to zip
TEMP_FILE_LIST=$(mktemp)

# Look for solution files (prob_* files)
find . -maxdepth 1 -name "prob_*" -type f > "$TEMP_FILE_LIST" 2>/dev/null || true

# Always include student_info.txt if it exists
if [ -f "student_info.txt" ]; then
    echo "student_info.txt" >> "$TEMP_FILE_LIST"
fi

# Check if any files were found
if [ ! -s "$TEMP_FILE_LIST" ]; then
    echo "Warning: No solution files found."
    echo "Looking for: prob_*"
    rm "$TEMP_FILE_LIST"
    read -p "Do you want to continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        echo "Submission cancelled."
        exit 1
    fi
    # Create an empty zip
    touch placeholder.txt
    echo "No solution files found" > placeholder.txt
    $PYTHON_CMD -m zipfile -c "$SUBMISSION_FILE" placeholder.txt
    rm placeholder.txt
else
    # Create zip with solution files and student info
    while IFS= read -r file; do
        echo "  Adding: $file"
    done < "$TEMP_FILE_LIST"
    
    # Use Python zipfile module to create the zip
    $PYTHON_CMD -m zipfile -c "$SUBMISSION_FILE" $(cat "$TEMP_FILE_LIST")
fi

rm "$TEMP_FILE_LIST"

echo ""
echo "Submission package created: $SUBMISSION_FILE"
echo "Uploading submission..."
echo ""

# TODO: Update with your actual Vercel deployment URL
API_URL="https://ee-1st-year-python-exam.vercel.app/api/submit"

# Upload using curl
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o ./submit_response.txt -w "%{http_code}" -X POST -F "file=@${SUBMISSION_FILE};type=application/zip" "$API_URL")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Submission Successful! Your exam is submitted."
        echo ""
        rm -f ./submit_response.txt
        exit 0
    else
        echo "✗ Submission FAILED. Please check your internet and contact your TA immediately."
        echo "Error Code: $HTTP_CODE"
        cat ./submit_response.txt 2>/dev/null || true
        rm -f ./submit_response.txt
        exit 1
    fi
else
    echo "Error: curl is not available. Please install curl."
    exit 1
fi
SUBMIT_SCRIPT_EOF

# Make scripts executable
chmod +x submit.sh start_exam.sh

echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "All files are currently read-only for integrity."
echo "Your exam files are in: $EXAM_DIR"
echo ""
echo "When you are ready to begin, run:"
echo "  ./start_exam.sh"
echo ""
echo "When you are finished, run:"
echo "  ./submit.sh"
echo ""
echo "Good luck!"
echo ""