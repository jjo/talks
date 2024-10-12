# Start from the official Golang image
FROM golang:1.17-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files
COPY go.mod ./

# Download the Go module dependencies
RUN go mod download

# Copy the source code into the container
COPY simplesrv.go .

# Build the Go app
RUN go build -o simplesrv .

# Expose port 8080
EXPOSE 8080

# Run the executable
CMD ["./simplesrv"]
