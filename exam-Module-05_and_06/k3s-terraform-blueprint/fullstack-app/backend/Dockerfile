#Step 1: Build the Docker image
FROM python:3.9-slim
# Set the working directory
WORKDIR /app
# Copy the requirements file and install dependencies
COPY requirements.txt .
# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt
# Copy the rest of the application code
COPY . .
# Expose the port the app runs on
EXPOSE 5000
# Start the app
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]