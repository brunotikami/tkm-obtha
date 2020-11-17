$(eval CURRENT_VERSION=`bumpversion --allow-dirty --list --dry-run release| grep current_version | cut -d= -f2`)
CURRENT_PACKAGE=$(shell grep "^NAME = '" setup.py | awk -F "'" '{print $2}')

# If the first argument is "build-package"...
ifeq (build-package,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  VERSION_TYPE := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(VERSION_TYPE):;@:)
endif

ifndef PYENV_HOME
	ifdef VIRTUAL_ENV
		PYENV_HOME=${VIRTUAL_ENV}
	else
		PYENV_HOME ?=.venv
	endif
endif

MAKEFLAGS += -s

help: ## help: Show this help message.
	@echo "usage: make [target] ..."
	@echo ""
	@echo "targets:"
	@grep -Eh '^.+:(\w+)?\ ##\ .+' ${MAKEFILE_LIST} | cut -d ' ' -f '3-' | column -t -s ':'

build-package: ## build-package: Generate a new version based on .bumpversion.cfg settings and push the newly created tag
	${PYENV_HOME}/bin/bumpversion ${VERSION_TYPE};
	echo "Created version ${CURRENT_VERSION}"
	#python setup.py sdist upload -r pypi.prod 
	git push origin ${CURRENT_VERSION}
	echo ${CURRENT_PACKAGE}

clean: ## clean: Cleanup.
	find . -name *.pyc -delete
	find . -name *.pyo -delete
	rm -Rf htmlcov/
	rm .coverage

coverage: ## coverage: Coverage.
	CONFIG_FILE=config/test.ini py.test --cov=obtha --cov-report term-missing


coverage-html: ## coverage-html: Coverage with HTML report.
	CONFIG_FILE=config/test.ini py.test --cov=obtha --cov-report html
	xdg-open htmlcov/index.html &

test:  ## Run tests.
	make unit
	make coverage

unit: ## unit: Unit tests.
	CONFIG_FILE=config/test.ini py.test -v -x

ci: ## ci: Run CI tests.
	CONFIG_FILE=config/ci.ini ${PYENV_HOME}/bin/py.test
	CONFIG_FILE=config/test.ini ${PYENV_HOME}/bin/py.test --cov obtha/ --cov-report term-missing --cov-report xml --cov-report html 
	${PYENV_HOME}/bin/pylint obtha tests > pylint.out || exit 0
