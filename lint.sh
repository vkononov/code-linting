#!/usr/bin/env bash

LINTERS=("ruby" "rails")

RUBOCOP_LINK='https://gitlab.com/tactica/code-linting/raw/master/linters/rubocop.yml'
RUBOCOP_CONF='.rubocop.yml'
RUBOCOP_PATH=$(pwd)
RUBOCOP_ARGS='--auto-correct'

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

echo

if ${valid}; then
	success 'All linters have completed without errors.'
else
	abort 'Some linters have completed with errors'
fi
