# Variables
IMAGE_NAME := simplesrv
CONTAINER_NAME := simplesrv-container

# Build the Docker image
build:
	docker build -t $(IMAGE_NAME) .

# Run the container
run:
	docker run --name $(CONTAINER_NAME) -p 8080:8080 $(IMAGE_NAME)

# Stop and remove the container
stop:
	docker stop $(CONTAINER_NAME)
	docker rm $(CONTAINER_NAME)

# Remove the image
clean:
	docker rmi $(IMAGE_NAME)

# Build and run
up: build run

# Stop, remove container, and remove image
down: stop clean

.PHONY: build run stop clean up down
