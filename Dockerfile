# Dockerfile References: https://docs.docker.com/engine/reference/builder/

# Start from golang v1.11 base image
FROM golang:latest

# Add Maintainer Info
LABEL maintainer="Antonio Escalera <aj@angelofdeauth.host>"

# Set the Current Working Directory inside the container
WORKDIR $GOPATH/src/github.com/angelofdeauth/testapp

# Copy everything from the current directory to the PWD(Present Working Directory) inside the container
RUN git clone https://github.com/angelofdeauth/testapp.git .

# Download all the dependencies
# https://stackoverflow.com/questions/28031603/what-do-three-dots-mean-in-go-command-line-invocations
RUN go get -d -v ./...

# Install the package
RUN go install -v ./...

# This container exposes port 8080 to the outside world
EXPOSE 8080

# Run the executable
CMD ["testapp"]