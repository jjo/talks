all: rebuild

DIRS=$(shell find ../ -name compose.jsonnet -printf "%h\n")

rebuild:
	@for dir in $(DIRS); do \
		echo "Rebuilding $$dir/docker-compose.yml"; \
		$(MAKE) -s -C $$dir compose; \
	done
