# Use the official Python image as a parent image
FROM python:3.9-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install libs dependencies
RUN apt-get update && apt-get -y install mariadb-client build-essential libmariadb3 libmariadb-dev gunicorn

# Install any needed packages specified in requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV FLASK_APP=app.py

# Run the command to start the Flask app
#CMD ["flask", "run", "--host=0.0.0.0"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
