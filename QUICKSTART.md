# Quick Start Guide

Get your exam system up and running in 15 minutes!

## For Instructors (Initial Setup)

### Method 1: GitHub Integration (Recommended - 10 minutes)

1. **Fork this repository** to your GitHub account

2. **Go to Vercel Dashboard** and click **Add New... > Project**

3. **Import your GitHub repository**

4. **Click Deploy** (no environment variables needed for submission-only system)

5. **Set up Blob Storage**:
   - Go to **Storage** tab → **Create Database** → **Blob**
   - Vercel auto-configures the required environment variables

6. **Update URLs in setup.sh** (commit to GitHub):
   - Update `VERCEL_BLOB_BASE_URL` with your Blob Storage URL
   - Update `API_URL` with your Vercel deployment URL
   - Vercel will auto-redeploy when you push

### Method 2: Vercel CLI (Advanced - 10 minutes)

```bash
# Install Vercel CLI
npm install -g vercel

# Clone this repository
git clone https://github.com/abirmondal/py-exam-cli.git
cd py-exam-cli

# Login to Vercel
vercel login

# Deploy
vercel --prod
```

Then configure as above:
1. Create Blob Storage in Storage tab
2. Update URLs in setup.sh

### Test It! (1 minute)

```bash
# Test the API
curl https://your-project.vercel.app/

# Should return: {"message": "Python Exam System API", ...}
```

**Done!** Your exam system is live! 🎉

---

## For Students (Taking an Exam)

### 1. Download Setup Script

```bash
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/py-exam-cli/main/setup.sh
```

### 2. Run Setup

```bash
chmod +x setup.sh
./setup.sh
```

Enter:
- Your Enrollment ID (e.g., `STU12345`)
- Your Full Name (e.g., `John Smith`)
- Exam Code (e.g., `cst101`)

### 3. Start the Exam

```bash
cd ~/exam_STU12345
./start_exam.sh
```

This starts the timer and makes `prob_*` solution files editable.

### 4. Complete the Exam

```bash
# Work on your solutions
nano prob_1.py
nano prob_2.py
nano prob_3.txt
```

### 5. Submit

```bash
./submit.sh
```

This locks files and submits as `{EXAM_CODE}_{ENROLLMENT_ID}.zip`. Confirm your Enrollment ID and wait for confirmation.

**Done!** Your exam is submitted! ✓

---

## For Instructors (Creating Exams)

### Quick Exam Creation

```bash
# 1. Create a directory
mkdir my_exam
cd my_exam

# 2. Create solution files using prob_* pattern
cat > prob_1.py << 'EOF'
def add(a, b):
    # Your code here
    pass
EOF

cat > prob_2.txt << 'EOF'
Answer for problem 2:
EOF

# 3. Create the zip
zip -r myexam101.zip prob_*

# 4. Upload to Vercel Blob Storage
# Option 1: Via Vercel Dashboard
# - Go to your project → Storage → Blob
# - Upload myexam101.zip to public-exams/ folder

# Option 2: Via Vercel CLI
vercel blob upload myexam101.zip --store public-exams
```

**Done!** Your exam is available! Students can now use exam code `myexam101`.

---

## For Instructors (Downloading Submissions)

This is a **submission-only system**. Grade manually or use local automation.

### Download Submissions

1. **Go to Vercel Dashboard** → Your Project
2. **Navigate to Storage** → Blob
3. **Browse submissions/ folder**
4. **Download files** - they're named as `{examcode}_{enrollmentid}.zip`
   - Example: `myexam101_STU12345.zip`
5. **Unzip and grade** using your preferred method

**Note**: Only the last submission from each student is kept (previous submissions are automatically overwritten).

**Done!** Grade submissions with your preferred tools! 📊

---

## Common Commands

### Re-deploy After Changes

```bash
git add .
git commit -m "Update exam files"
git push
vercel --prod
```

### View Logs

```bash
vercel logs
```

### Test Submission Locally

```bash
# Create a test zip
echo "Q1: A" > answers.txt
zip test.zip answers.txt

# Submit it
curl -X POST -F "file=@test.zip" https://your-project.vercel.app/api/submit
```

---

## Troubleshooting

### "Invalid Exam Code" Error
- ✓ Check the zip file exists in `public/exam_files/`
- ✓ Verify the exam code matches the filename (without .zip)
- ✓ Ensure the repository is public

### "Submission FAILED" Error
- ✓ Check the Vercel URL is correct in `setup.sh`
- ✓ Verify Blob Storage is configured
- ✓ Test the API: `curl https://your-url.vercel.app/`



---

## Support

- 📖 Read the full [README.md](README.md)
- 🚀 See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment
- 🤝 Check [CONTRIBUTING.md](CONTRIBUTING.md) for customization

---

## Next Steps

1. ✓ Create your first exam
2. ✓ Test with a friend
3. ✓ Share the setup script with students
4. ✓ Monitor submissions in Vercel dashboard
5. ✓ Run grading after exam deadline

**Happy Examining!** 🎓
