# Deployment Guide

This guide will help you deploy the Terminal-Based Python Exam System to Vercel.

## Prerequisites

- A GitHub account
- A Vercel account (free tier works fine)
- Git installed locally
- Node.js and npm installed (for Vercel CLI)

## Step-by-Step Deployment

### 1. Fork or Clone the Repository

```bash
# Clone the repository
git clone https://github.com/abirmondal/py-exam-cli.git
cd py-exam-cli

# Or fork it on GitHub and clone your fork
```

### 2. Customize for Your Institution

#### Update setup.sh

Open `setup.sh` and update line 39 with your repository information:

```bash
# Change this line:
GITHUB_RAW_URL="https://raw.githubusercontent.com/abirmondal/py-exam-cli/main/public/exam_files/${EXAM_CODE}.zip"

# To your repository:
GITHUB_RAW_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/public/exam_files/${EXAM_CODE}.zip"
```

### 3. Install Vercel CLI

```bash
npm install -g vercel
```

### 4. Login to Vercel

```bash
vercel login
```

Follow the prompts to authenticate with your Vercel account.

### 5. Deploy the Project

```bash
# Deploy to production
vercel --prod
```

The CLI will guide you through:
- Linking to an existing project or creating a new one
- Configuring project settings
- Deploying the application

### 6. Configure Environment Variables

After deployment, you need to set up the `GRADING_SECRET` environment variable:

1. Go to your Vercel dashboard: https://vercel.com/dashboard
2. Select your project
3. Go to **Settings** → **Environment Variables**
4. Add a new environment variable:
   - **Name**: `GRADING_SECRET`
   - **Value**: Choose a strong, random secret (e.g., a UUID or long random string)
   - **Environment**: Select all (Production, Preview, Development)
5. Click **Save**

### 7. Configure Vercel Blob Storage

The API uses Vercel Blob Storage for storing submissions and results.

1. In your Vercel project dashboard, go to **Storage**
2. Click **Create Database**
3. Select **Blob**
4. Choose a name for your store (e.g., "exam-submissions")
5. Click **Create**

Vercel will automatically configure the necessary environment variables for Blob Storage.

### 8. Update API URL in setup.sh

After deployment, Vercel will give you a URL (e.g., `https://your-project.vercel.app`).

You need to update the API URL in the `setup.sh` file that gets dynamically created.

Edit `setup.sh` around line 111 and change:

```bash
API_URL="https://your-vercel-deployment.vercel.app/api/submit"
```

To your actual Vercel URL:

```bash
API_URL="https://your-project-name.vercel.app/api/submit"
```

### 9. Commit and Push Changes

```bash
git add setup.sh
git commit -m "Update URLs for deployment"
git push origin main
```

### 10. Redeploy (if needed)

If you made changes after the initial deployment:

```bash
vercel --prod
```

## Verify Deployment

### Test the API

1. Visit your Vercel URL in a browser: `https://your-project.vercel.app`
2. You should see a JSON response with API information

### Test Submission Endpoint

```bash
# Create a test zip file
cd /tmp
echo "Test content" > test.txt
zip test.zip test.txt

# Test the submission
curl -X POST -F "file=@test.zip" https://your-project.vercel.app/api/submit
```

You should get a success response.

### Test Grading Endpoint

```bash
curl "https://your-project.vercel.app/api/start-grading?secret=YOUR_SECRET_KEY"
```

Replace `YOUR_SECRET_KEY` with the value you set in environment variables.

## Add Exam Files

### 1. Create Your Exam Content

```bash
mkdir exam_content
cd exam_content

# Create your exam files
echo "Question 1..." > problem1_question.txt
echo "# Solution template" > problem1_solution.py
echo "Q1:\nQ2:" > answers.txt
```

### 2. Create the Zip File

```bash
zip -r myexam101.zip *.txt *.py
```

### 3. Add to Repository

```bash
mv myexam101.zip /path/to/py-exam-cli/public/exam_files/
cd /path/to/py-exam-cli
git add public/exam_files/myexam101.zip
git commit -m "Add myexam101 exam"
git push origin main
```

The exam will be immediately available via the raw GitHub URL.

## Student Instructions

### Distribute to Students

1. **Setup Script URL**:
   ```
   https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh
   ```

2. **Instructions for Students**:
   ```
   1. Download setup script:
      curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh
   
   2. Make it executable:
      chmod +x setup.sh
   
   3. Run setup:
      ./setup.sh
   
   4. Enter your Enrollment ID when prompted
   5. Enter the Exam Code (e.g., cst101)
   6. Complete the exam
   7. Run: ./submit.sh
   ```

## Monitoring and Maintenance

### View Logs

1. Go to your Vercel dashboard
2. Select your project
3. Go to **Deployments**
4. Click on a deployment
5. View **Functions** logs

### Download Submissions

After students submit, you can:

1. Use the grading endpoint to process all submissions
2. Download the results CSV from Vercel Blob Storage
3. Or manually access Blob Storage through the Vercel dashboard

### Grading Process

```bash
# Start grading with your secret
curl "https://your-project.vercel.app/api/start-grading?secret=YOUR_SECRET"
```

This will:
- Process all submissions in Blob Storage
- Compare answers with the answer key
- Generate a CSV file with results
- Return the URL to download the CSV

## Troubleshooting

### Deployment Fails

**Error**: "No build matches your repository"
- **Solution**: Make sure `vercel.json` is in the repository root

**Error**: "Failed to install dependencies"
- **Solution**: Check that `requirements.txt` is valid
- Try: `pip install -r requirements.txt` locally first

### API Errors

**Error**: "Grading secret not configured"
- **Solution**: Set the `GRADING_SECRET` environment variable in Vercel

**Error**: "Failed to save submission"
- **Solution**: Ensure Vercel Blob Storage is configured
- Check that the BLOB_READ_WRITE_TOKEN is set (automatic with Blob)

### Students Can't Download Exams

**Error**: "Invalid Exam Code or network issue"
- **Solution**: 
  1. Verify the exam zip file exists in `public/exam_files/`
  2. Check the GitHub raw URL is correct
  3. Make sure the repository is public
  4. Test the URL in a browser

### Submissions Fail

**Error**: "Submission FAILED"
- **Solution**:
  1. Check the Vercel deployment URL is correct in `setup.sh`
  2. Verify the API endpoint is working
  3. Check file size (must be < 10MB)
  4. Test with: `curl -X POST -F "file=@submission.zip" https://your-url/api/submit`

## Security Best Practices

1. **Protect Your Secret Key**
   - Never commit the `GRADING_SECRET` to the repository
   - Use a strong, random value
   - Rotate it periodically

2. **Monitor Access**
   - Review Vercel function logs regularly
   - Watch for suspicious activity
   - Set up alerts in Vercel dashboard

3. **Backup Data**
   - Regularly download submissions from Blob Storage
   - Keep local backups of exam files
   - Export grading results frequently

4. **Access Control**
   - Only share the grading endpoint with authorized personnel
   - Keep the secret key confidential
   - Use different secrets for different exam periods

## Cost Considerations

### Vercel Free Tier Limits

- **Function Invocations**: 100,000/month
- **Function Duration**: 100 GB-hours/month
- **Bandwidth**: 100 GB/month
- **Blob Storage**: 1 GB free

For a typical exam with 100 students:
- Setup downloads: ~0.5 MB × 100 = 50 MB
- Submissions: ~1 MB × 100 = 100 MB
- Total: ~150 MB (well within limits)

### Upgrading

If you need more resources:
- Vercel Pro: $20/month
- Includes 1000 GB bandwidth
- Custom domains
- Better support

## Updates and Maintenance

### Update Exam System

```bash
# Pull latest changes
git pull origin main

# Deploy
vercel --prod
```

### Add New Features

1. Make changes locally
2. Test thoroughly
3. Commit and push
4. Deploy to Vercel

## Support

For issues or questions:
- Check the README.md
- Review Vercel documentation: https://vercel.com/docs
- Check function logs in Vercel dashboard
- Review error messages carefully

## Advanced Configuration

### Custom Domain

1. In Vercel dashboard, go to **Settings** → **Domains**
2. Add your custom domain
3. Configure DNS according to Vercel instructions
4. Update the API URL in `setup.sh`

### Function Timeout

If grading takes too long, increase the timeout in `vercel.json`:

```json
{
  "functions": {
    "api/index.py": {
      "maxDuration": 60
    }
  }
}
```

### CORS Configuration

If you need to access the API from a web interface, add CORS middleware in `api/index.py`.

## Conclusion

Your Terminal-Based Python Exam System is now deployed and ready to use! Students can download the setup script, take exams, and submit their work. You can process submissions and generate grades with a single API call.

For production use, make sure to:
- ✓ Set strong secret keys
- ✓ Test the complete workflow
- ✓ Monitor during exam periods
- ✓ Keep backups of all data
- ✓ Review logs regularly
