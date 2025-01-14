all: rebuild

# Rebuild docker-compose.yml in every directory that contains a `compose.jsonnet` file
DIRS=$(shell find ../ -name compose.jsonnet -printf "%h\n")

rebuild: update-images
	@for dir in $(DIRS); do \
		echo "Rebuilding $$dir/docker-compose.yml"; \
		$(MAKE) -s -C $$dir compose; \
	done

update-images:
	./scripts/update-images.sh jsonnet/lib/containers/images.libsonnet

.PHONY: all rebuild update-images
