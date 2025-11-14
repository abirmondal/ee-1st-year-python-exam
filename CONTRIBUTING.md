# Contributing to Terminal-Based Python Exam System

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear title and description
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Python version, etc.)
- Error messages or logs

### Suggesting Enhancements

For feature requests:
- Describe the feature clearly
- Explain the use case
- Provide examples if possible
- Discuss potential implementation approaches

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes**
4. **Test thoroughly**
5. **Commit with clear messages**: `git commit -m "Add feature X"`
6. **Push to your fork**: `git push origin feature/your-feature-name`
7. **Create a Pull Request**

## Development Guidelines

### Code Style

**Python (api/index.py)**:
- Follow PEP 8 style guide
- Use meaningful variable names
- Add docstrings to functions
- Keep functions focused and small
- Handle errors gracefully

**Shell Scripts (setup.sh)**:
- Use `set -e` for error handling
- Quote variables properly
- Add comments for complex logic
- Test on multiple shells if possible
- Follow shellcheck recommendations

### Testing

Before submitting:
1. Test the complete workflow end-to-end
2. Verify all API endpoints work
3. Check for edge cases
4. Test with different file sizes
5. Verify error handling

### Documentation

- Update README.md if changing functionality
- Add comments for complex code
- Update DEPLOYMENT.md if changing deployment process
- Include examples for new features

## Project Structure

```
/
├── api/
│   └── index.py          # FastAPI backend - Add new endpoints here
├── public/
│   └── exam_files/       # Exam zip files - Add new exams here
├── setup.sh              # Student setup script
├── requirements.txt      # Python dependencies
├── vercel.json          # Vercel configuration
├── README.md            # Main documentation
├── DEPLOYMENT.md        # Deployment guide
└── CONTRIBUTING.md      # This file
```

## Adding New Features

### Adding a New API Endpoint

1. Open `api/index.py`
2. Add the endpoint function:
   ```python
   @app.get("/api/new-endpoint")
   async def new_endpoint():
       return {"status": "success"}
   ```
3. Add validation and error handling
4. Test locally
5. Update documentation

### Adding Exam File Validation

Edit the `submit_exam` function in `api/index.py`:

```python
# Add new validation
if not some_condition:
    raise HTTPException(
        status_code=400,
        detail="Validation failed: reason"
    )
```

### Customizing Submission Handling

This is a submission-only system. To customize submission handling:

1. Modify the `submit_exam` function in `api/index.py`
2. Add additional file validation
3. Change the submission naming format
4. Add metadata extraction

### Adding File Types to Submission

Edit `setup.sh` to change what files are collected. Current pattern uses `prob_*`:

```bash
find . -maxdepth 1 -name "prob_*" -type f
```

To add more file types:
```bash
find . -maxdepth 1 \( -name "prob_*" -o -name "*.cpp" \) -type f
```

## Common Tasks

### Update File Size Limit

In `api/index.py`, change:
```python
MAX_FILE_SIZE = 10 * 1024 * 1024  # Current: 10MB
```

### Add Support for More File Types

In `api/index.py`, update `valid_content_types`:
```python
valid_content_types = [
    "application/zip",
    "application/x-zip-compressed",
    "application/octet-stream",
    # Add more types
]
```

### Add Student Notifications

Add email/SMS notification after submission (in `api/index.py`):
```python
@app.post("/api/submit")
async def submit_exam(file: UploadFile = File(...)):
    # ... existing code ...
    
    # Add notification
    send_notification(student_id, "Submission received")
    
    return response
```

## Testing Locally

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/abirmondal/py-exam-cli.git
cd py-exam-cli

# Install dependencies
pip install -r requirements.txt

# Run the API
uvicorn api.index:app --reload
```

### Test API Endpoints

```bash
# Test submission
curl -X POST -F "file=@test.zip" http://localhost:8000/api/submit
```

### Test Setup Script

```bash
# Run setup script
./setup.sh

# Test inputs:
# Enrollment ID: TEST123
# Exam Code: cst101
```

## Release Process

1. Update version numbers if applicable
2. Update CHANGELOG.md (if exists)
3. Create a git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push tags: `git push origin --tags`
5. Create a GitHub release
6. Deploy to Vercel: `vercel --prod`

## Code Review Checklist

Before submitting a PR, ensure:
- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] No security vulnerabilities introduced
- [ ] Documentation updated
- [ ] Changes are backward compatible (or breaking changes documented)
- [ ] Error handling is comprehensive
- [ ] Code is commented where necessary
- [ ] No hardcoded credentials or secrets
- [ ] File operations are safe (no destructive commands)

## Security Considerations

### When Contributing

- Never commit secrets or API keys
- Validate all user inputs
- Use parameterized queries if adding database features
- Follow principle of least privilege
- Handle sensitive data carefully
- Review dependencies for vulnerabilities

### Security Review

All contributions will be reviewed for:
- Input validation
- Data protection
- Error handling
- Secure defaults
- Dependency security

## Getting Help

- **Questions**: Open an issue with the "question" label
- **Bugs**: Open an issue with the "bug" label
- **Features**: Open an issue with the "enhancement" label
- **Documentation**: Open an issue with the "documentation" label

## Recognition

Contributors will be:
- Listed in the project README
- Mentioned in release notes
- Credited in commit messages

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive experience for everyone.

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information
- Other conduct which could reasonably be considered inappropriate

## Questions?

Feel free to reach out by opening an issue or discussion on GitHub.

---

Thank you for contributing! 🎉
