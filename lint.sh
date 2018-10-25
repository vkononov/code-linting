#!/usr/bin/env bash

LINTERS=('haml' 'ruby' 'rails')

RAW_URL='https://raw.githubusercontent.com/vkononov/code-linting/master/linters'

RUBOCOP_CONF='.rubocop.yml'
RUBOCOP_LINK="$RAW_URL/$RUBOCOP_CONF"
RUBOCOP_PATH=$(pwd)
RUBOCOP_ARGS='--auto-correct'

HAML_CONF='.haml-lint.yml'
HAML_LINK="$RAW_URL/$HAML_CONF"
HAML_PATH=$(pwd)
HAML_ARGS=''

valid=true

validate_args() {
	for var in "$@"
	do
	    if [[ -z $(printf '%s\n' "${LINTERS[@]}" | grep -w $var) ]]; then
	  		error "linter <${var}> is undefined"
	  		warning "$(echo "Available linters: ${LINTERS[@]}")"
	  		exit 1
		fi
	done
}

lint_ruby_or_rails() {
	echo
	status '== Linting Ruby/Rails =='

    if ! type -P node > /dev/null; then
    	abort 'ruby is not installed'
	fi

	if ! gem query -i -n rubocop > /dev/null; then
		status "Installing Rubocop"
		gem install rubocop --no-ri --no-rdoc
	fi

	if [[ ! -z $(printf '%s\n' "$@" | grep -w 'rails') ]]; then
		RUBOCOP_ARGS="$RUBOCOP_ARGS --rails"
	fi

	status "Looking for local $RUBOCOP_CONF in $RUBOCOP_PATH"
	if test -e "$RUBOCOP_PATH/$RUBOCOP_CONF"; then
		echo "Found $RUBOCOP_CONF in $RUBOCOP_PATH"
		status "Linting ruby with $RUBOCOP_PATH/$RUBOCOP_CONF"
	else
		echo "Local $RUBOCOP_CONF not found in $RUBOCOP_PATH, using default"
		status "Linting ruby with $RUBOCOP_LINK"
		curl -o "/tmp/$RUBOCOP_CONF" ${RUBOCOP_LINK}
		RUBOCOP_ARGS="$RUBOCOP_ARGS --config /tmp/$RUBOCOP_CONF"
	fi

	warning "Running <bundle exec rubocop $RUBOCOP_ARGS>"
	bundle exec rubocop ${RUBOCOP_ARGS} || { valid=false; }
}

lint_haml() {
	status '== Linting HAML =='

	if ! gem query -i -n haml-lint > /dev/null; then
		status "Installing haml-lint"
		gem install haml-lint --no-ri --no-rdoc
	fi

	status "Looking for local $HAML_CONF in $HAML_PATH"
	if test -e "$HAML_PATH/$HAML_CONF"; then
		echo "Found $HAML_CONF in $HAML_PATH"
		status "Linting HAML with $HAML_PATH/$HAML_CONF"
	else
		echo "Local $HAML_CONF not found in $HAML_PATH, using default"
		status "Linting HAML with $HAML_LINK"
		curl -o "/tmp/$HAML_CONF" ${HAML_LINK}
		HAML_ARGS="$HAML_ARGS --config /tmp/$HAML_CONF"
	fi

	warning "Running <bundle exec haml-lint $HAML_ARGS>"
	bundle exec haml-lint ${HAML_ARGS} || { valid=false; }
}

abort() {
	error "$1"; exit 1
}

error() {
	tput setaf 1; echo "ERROR: $1"; tput sgr0
}

warning() {
	tput setaf 3; echo "$1"; tput sgr0
}

success() {
	tput setaf 2; echo "SUCCESS: $1"; tput sgr0
}

status() {
	tput setaf 4; echo "$1..."; tput sgr0
}

validate_args "$@"

if [[ ! -z $(printf '%s\n' "$@" | grep -w 'ruby\|rails') ]]; then
    lint_ruby_or_rails "$@"
fi

if [[ ! -z $(printf '%s\n' "$@" | grep -w 'haml') ]]; then
    lint_haml
fi

echo

if ${valid}; then
	success 'All linters have completed without errors.'
else
	abort 'Some linters have completed with errors'
fi
