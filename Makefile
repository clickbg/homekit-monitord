tag := latest

all: build-container

build-container:
	docker build -t homekit-monitord:${tag} .

push:
	docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag clickbg/homekit-monitord:${tag} .

.PHONY: all push build-container
