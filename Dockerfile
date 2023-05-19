FROM python:3.9-slim-buster

LABEL maintainer="nikolai.arras@accenture.com"

# Set working directory
WORKDIR /app

# Copy MLflow artifact and inference script
COPY python_model.pkl /app
COPY requirements.txt /app
COPY inference.py /app

# Install dependencies
RUN pip install -r requirements.txt

# Expose port for inference
EXPOSE 80

# Start server
ENTRYPOINT ["python", "inference.py"]
