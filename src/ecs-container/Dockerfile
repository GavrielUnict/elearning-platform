# FROM python:3.11-slim # con questo stavo raggiungendo il limite di pull di Docker Hub senza autenticazione

FROM public.ecr.aws/docker/library/python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port for health check
EXPOSE 8000

# Run the application
CMD ["python", "main.py"]