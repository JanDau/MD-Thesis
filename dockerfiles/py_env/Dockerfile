# Use an official Python runtime as a parent image
FROM python:3.6

# The enviroment variable ensures that the python output is set straight
# to the terminal without buffering it first
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /usr/src/app

# Install the regex library with version 2023.8.8
RUN pip install regex==2023.8.8

# Set the default command for the container
CMD ["python3"]
