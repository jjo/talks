all:
	@echo "make compose	    # Build docker-compose.yml"
	@echo "make up              # Run docker-compose up -d"
	@echo "make logs            # Run docker-compose logs -f"
	@echo "make down            # Run docker-compose down"
	@echo "make rm              # Run docker-compose rm -f"

compose:
	jsonnet compose.jsonnet | yq -P . > docker-compose.yml

up:
	docker-compose up -d

logs:
	docker-compose logs -f

down:
	docker-compose down

rm:
	docker-compose rm -f


.PHONY: all compose up logs down rm generate-syslog example-logql-01
