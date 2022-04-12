tag := latest

all: build-container

build-container:
	docker build -t homekit-monitord:${tag} .

push:

.PHONY: all push build-container
