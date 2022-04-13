tag := latest

all: build-container

build-container:
	docker build -t homekit-monitord:${tag} .

push:
	docker tag homekit-monitord:${tag} clickbg/homekit-monitord:${tag}
	docker push clickbg/homekit-monitord:${tag}

.PHONY: all push build-container
