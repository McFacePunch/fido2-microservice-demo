.PHONY: help clean clean-pyc clean-build list test coverage release

help:
	@echo "  clean-build -          Remove build artifacts"
	@echo "  clean-pyc -            Remove Python file artifacts"
	@echo "  install-requirements - install the requirements for development"
	@echo "  build                  Builds the docker images for the docker-compose setup"
	@echo "  docker-rm              Stops and removes all docker containers"
	@echo "  shell                  Opens a Bash shell"

clean: clean-build clean-pyc docker-rm

clean-build:
	rm -fr build/
	rm -fr dist/
	rm -fr *.egg-info

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +

install-requirements:
	pip install -r requirements/requirements.txt

build:
	docker-compose build

docker-rm: stop
	docker-compose rm -f

shell:
	docker-compose run --entrypoint "/bin/bash" app

stop:
	docker-compose down
	docker-compose stop

hello-world:
	docker-compose run app python-application hello-world
