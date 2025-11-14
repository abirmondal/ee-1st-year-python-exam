# Terminal-Based Python Exam System

A complete Python & Shell-based CLI system for conducting exams. Manages setup and submission via a FastAPI backend deployed on Vercel with Blob Storage. **Submission-only system** - TAs download submissions for manual/local grading.

## 🚀 Features

- **Student Setup Script**: Download and setup exam environment with a single command
- **Automatic Submission**: Package and submit `prob_*` solution files via CLI
- **Single Endpoint Backend**: FastAPI on Vercel for simple, scalable submission management
- **Blob Storage**: Secure submission storage using Vercel Blob
- **Submission Overwrite**: Only the last submission from a student is kept (based on filename), simplifying exam management
- **File Permissions**: Exam files are read-only until exam starts; only `prob_*` solution files become editable
- **Time Tracking**: Complete audit trail with start time, submit time, and duration

## 📁 Repository Structure

```
/
├── api/
│   └── index.py              # FastAPI backend with /api/submit ONLY
├── setup.sh                  # Master setup script for students
├── requirements.txt          # Python dependencies for Vercel
├── vercel.json              # Vercel configuration
└── README.md                # This file
```

## 🎓 For Students

### Setup Instructions

1. **Download the setup script**:
   ```bash
   curl -O https://raw.githubusercontent.com/abirmondal/ee-1st-year-python-exam/main/setup.sh
   ```

2. **Make it executable and run**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Follow the prompts**:
   - Enter your Enrollment ID (e.g., `STU12345`)
   - Enter your Full Name (e.g., `John Smith`)
   - Enter the Exam Code (e.g., `cst101`)

4. **Start the exam**:
   ```bash
   cd ~/exam_STU12345
   ./start_exam.sh
   ```
   This will start the timer and make `prob_*` solution files editable.

5. **Complete your exam**:
   - Work on the problems in the directory
   - Edit solution files matching the `prob_*` pattern (e.g., `prob_1.py`, `prob_2.txt`, etc.)

6. **Submit your work**:
   ```bash
   ./submit.sh
   ```
   This will lock files and submit your work as `{EXAM_CODE}_{ENROLLMENT_ID}.zip`.

### Important Notes for Students

- Work in the created `~/exam_<ENROLLMENT_ID>` directory
- Files are read-only until you run `./start_exam.sh`
- Only `prob_*` files become editable after starting the exam
- Your time is tracked from start_exam.sh to submit.sh
- Submission filename format: `{EXAM_CODE}_{ENROLLMENT_ID}.zip`
- Only your last submission is kept (previous submissions are overwritten)
- Ensure internet connection before submitting

## 👨‍🏫 For Instructors

### Deployment to Vercel

#### Method 1: GitHub Integration (Recommended)

1. **Fork or push this repository to your GitHub account**

2. **Login to Vercel** and click **Add New... > Project**

3. **Import the GitHub repository** you just created

4. **Click Deploy** (no environment variables needed for submission-only system)

5. **Set up Blob Storage**:
   - After deployment, go to the **Storage** tab
   - Create and link your Vercel Blob store
   - Vercel will automatically add the required blob environment variables

6. **Automatic deployments**:
   - Just `git commit` and `git push` to your main branch
   - Vercel will automatically redeploy

#### Method 2: Vercel CLI (Advanced)

1. **Fork or clone this repository**

2. **Install Vercel CLI** (if not already installed):
   ```bash
   npm i -g vercel
   ```

3. **Login to Vercel**:
   ```bash
   vercel login
   ```

4. **Deploy the project**:
   ```bash
   vercel --prod
   ```

5. **Update the setup.sh script**:
   - Update `VERCEL_BLOB_BASE_URL` with your Vercel Blob Storage URL
   - Update the API URL in the script with your Vercel deployment URL

### Creating Exam Files

1. **Create exam content** in a temporary directory:
   ```bash
   mkdir exam_content
   cd exam_content
   
   # Create coding problem with question and answer space
   cat > prob_1.py << 'EOF'
   """
   Problem 1: Hello World
   Write a Python program that prints "Hello, World!"

   INSTRUCTIONS: Write your code below.
   """

   # Write your code here

   EOF
      
   # Create multiple choice questions
   cat > prob_mcq.txt << 'EOF'
   # INSTRUCTIONS: Write your answer directly after the colon for each question.

   Q1: What is the capital of France? :
   Q2: Which of the following are programming languages (choose all that apply)? :
   Q3: What is 2 + 2? :

   EOF
      
      # Create another coding problem
      cat > prob_2.py << 'EOF'
   """
   Problem 2: Sum Function
   Write a function that returns the sum of two numbers.

   INSTRUCTIONS: Complete the function below.
   """

   def sum_two(a, b):
      # Write your code here
      pass

   EOF
   ```

2. **Zip the exam**:
   ```bash
   zip -r cst101.zip prob_*
   ```

3. **Upload to Vercel Blob Storage**:
   - Go to your Vercel project dashboard
   - Navigate to **Storage** → **Blob**
   - Upload `cst101.zip` to the `public-exams/` folder
   - Or use Vercel CLI: `vercel blob upload cst101.zip --store public-exams`

### Downloading Submissions

This system is **submission-only**. To grade, you must download the files.

1. **Go to your Vercel Project Dashboard**
2. **Navigate to the Storage tab** and select your Blob store
3. **All submissions are in the `submissions/` folder**, named as `<examcode>_<enrollmentid>.zip`
   - Example: `cst101_STU12345.zip`
4. **Download the files** for manual or local automated grading
5. **Unzip and grade** using your preferred tools/methods

**Note**: Only the last submission from each student is kept (previous submissions are automatically overwritten).

## 🔧 API Endpoints

### POST `/api/submit`

Submit exam solutions.

**Request**: 
- Method: POST
- Content-Type: multipart/form-data
- Body: File upload (zip file)

**Response**:
```json
{
  "status": "success",
  "message": "Submission received successfully",
  "filename": "cst101_STU12345.zip",
  "url": "https://...",
  "size": 12345
}
```

**Validations**:
- File must be ZIP format
- Maximum size: 10MB
- Must be a valid zip file

**Note**: Submission filename format is `{EXAM_CODE}_{ENROLLMENT_ID}.zip`. The `addRandomSuffix: False` option ensures that the last submission from a student overwrites any previous submissions.

## 🔒 Security Features

1. **File Validation**: Content type and size checks
2. **Safe Directory Operations**: No destructive `rm` commands in scripts
3. **Input Validation**: All user inputs are validated
4. **Read-Only Protection**: Question files remain read-only; only `prob_*` solution files are editable

## 🛠️ Development

### Local Testing

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the API locally**:
   ```bash
   uvicorn api.index:app --reload
   ```

3. **Test endpoints**:
   ```bash
   # Test submission
   curl -X POST -F "file=@test_submission.zip" http://localhost:8000/api/submit
   ```

### Testing the Setup Script

```bash
# Run locally (will create exam directory in your home)
./setup.sh

# Test inputs:
# Enrollment ID: TEST123
# Exam Code: cst101
```

## 📝 Customization

### Changing File Size Limit

Modify `MAX_FILE_SIZE` in `api/index.py`:

```python
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
```

### Solution File Patterns

To change which files are submitted, edit the `find` command inside the `submit.sh` HEREDOC in `setup.sh` (around line 203). The current pattern is `prob_*`:

```bash
find . -maxdepth 1 -name "prob_*" -type f
```

## 🐛 Troubleshooting

### Students Cannot Download Exam

- Verify the exam code is correct
- Check that the zip file exists in your Vercel Blob Storage under the `public-exams/` path
- Ensure the `VERCEL_BLOB_BASE_URL` in `setup.sh` is correct and publicly accessible
- Check internet connection

### Submission Fails

- Verify the Vercel deployment URL is correct in `submit.sh`
- Check file size (must be < 10MB)
- Ensure the zip file is valid
- Check internet connection

## 🔄 Syncing Updates from the Template

When you create a repository from this template, it's a one-time copy. It does not automatically receive updates if the main template is improved or fixed.

To pull in new updates from the main template, you must add it as a remote (you only need to do this once):

```bash
# 1. Add the main template as a remote named "upstream"
git remote add upstream https://github.com/abirmondal/py-exam-cli.git
```

Then, whenever you want to check for and merge updates:

```bash
# 2. Fetch the latest changes from the template
git fetch upstream

# 3. Merge the changes from the template's main branch into your main branch
git merge upstream/main
```

**Note:** If you have made your own changes to files that also changed in the template (like `setup.sh`), you may have to resolve merge conflicts.

## 📄 License

MIT License - Feel free to use and modify for your educational institution.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## ⚠️ Important Notes

1. **Update URLs**: Before deployment, update the Vercel Blob Storage URL and API URL in `setup.sh`
2. **Test First**: Test the complete workflow before using in production
3. **Backup**: Keep backups of exam files and submissions
4. **Monitor**: Monitor Vercel function logs during exam periods
