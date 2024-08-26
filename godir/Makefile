
PACKAGE=<docker registry>/godir
VERSION=1.0


# traditional configuration that uses Dockerfile

docker-image: .docker-image

.docker-image: Dockerfile *.go go.mod #go.sum
	docker build -t $(PACKAGE):latest .
	touch .docker-image

push: docker-image tag
	docker push $(PACKAGE):$(VERSION)

tag:
	docker tag $(PACKAGE):latest $(PACKAGE):$(VERSION)

# uses https://github.com/google/ko
# (does not use Dockerfile)

ko: 
	ko build -B .