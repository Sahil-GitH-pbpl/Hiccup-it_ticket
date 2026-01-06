# Use official Python image
FROM python:3.10

# Create working directory
WORKDIR /app

# Copy requirement file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Expose port 3002 for FastAPI
EXPOSE 3002

# Run server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3002"]
