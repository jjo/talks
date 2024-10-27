all:
	@echo "make compose	    # Build docker-compose.yml"
	@echo "make up              # Run docker-compose up -d"
	@echo "make logs            # Run docker-compose logs -f"
	@echo "make down            # Run docker-compose down"
	@echo "make rm              # Run docker-compose rm -f"
	@echo "make generate-syslog # Generate syslog messages"

compose:
	jsonnet -J ../../jsonnet compose.jsonnet | yq -P . > docker-compose.yml

up: compose
	docker-compose up -d

logs:
	docker-compose logs -f

down:
	docker-compose down

rm:
	docker-compose rm -f

example-logql-01:
	open "$(shell cat queries/loki-example-01.url)"

generate-syslog:
	./scripts/syslog_producer.py --host localhost --port 1514 --interval 0.5 --count 10000

.PHONY: all compose up logs down rm generate-syslog example-logql-01
