tag := latest

all: build-container

build-container:
	docker build -t homekit-monitord:${tag} .

push:
	docker tag homekit-monitord:${tag} dzhelev/homekit-monitord:${tag}
	docker push dzhelev/homekit-monitord:${tag}

.PHONY: all push build-container
