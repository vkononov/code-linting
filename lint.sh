#!/usr/bin/env bash

LINTERS=('coffee' 'haml' 'js' 'jsx' 'ruby' 'rails' 'sass', 'scss')

MASTER_URL='https://raw.githubusercontent.com/vkononov/code-linting/master'

IGNORE_URL="$MASTER_URL/ignore/"
LINTER_URL="$MASTER_URL/linters/"

COFFEE_EXEC='coffeelint'
COFFEE_CONF='coffeelint.json'
COFFEE_IGNR='.coffeelintignore'
COFFEE_LINK="$LINTER_URL/$COFFEE_CONF"
COFFEE_PATH=$(pwd)
COFFEE_ARGS='.'

HAML_EXEC='haml-lint'
HAML_CONF='.haml-lint.yml'
HAML_LINK="$LINTER_URL/$HAML_CONF"
HAML_PATH=$(pwd)
HAML_ARGS=''

ESLINT_EXEC='eslint'
ESLINT_CONF='.eslintrc.yml'
ESLINT_IGNR='.eslintignore'
ESLINT_LINK="$LINTER_URL/$ESLINT_CONF"
ESLINT_PATH=$(pwd)
ESLINT_ARGS='. --fix'

RUBOCOP_EXEC='rubocop'
RUBOCOP_CONF='.rubocop.yml'
RUBOCOP_LINK="$LINTER_URL/$RUBOCOP_CONF"
RUBOCOP_PATH=$(pwd)
RUBOCOP_ARGS='--auto-correct'

SASS_EXEC='sass-lint'
SASS_CONF='.sass-lint.yml'
SASS_LINK="$LINTER_URL/$SASS_CONF"
SASS_PATH=$(pwd)
SASS_ARGS='--no-exit --verbose'

NODE_BIN_PATH='node_modules/.bin'
TMP_PATH="/tmp/${PWD##*/}"

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

lint_coffee_script() {
    header 'Linting CoffeeScript'

    abort_if_yarn_is_missing

    if ! test "$NODE_BIN_PATH/$COFFEE_EXEC"; then
		status "Installing $COFFEE_EXEC"
		yarn add ${COFFEE_EXEC} --dev
	fi

    status "Looking for local $COFFEE_IGNR in $COFFEE_PATH"
    if test -e "$COFFEE_PATH/$COFFEE_IGNR"; then
		echo "Found $COFFEE_IGNR in $COFFEE_PATH"
	else
	    coffeelintignore_found=true
		echo "Local $COFFEE_IGNR not found in $COFFEE_PATH, using default"
		curl -o "$TMP_PATH@$COFFEE_IGNR" "$IGNORE_URL/$COFFEE_IGNR"
		cp "$TMP_PATH@$COFFEE_IGNR" ${COFFEE_IGNR}
	fi

	status "Looking for local $COFFEE_CONF in $COFFEE_PATH"
	if test -e "$COFFEE_PATH/$COFFEE_CONF"; then
		echo "Found $COFFEE_CONF in $COFFEE_PATH"
		status "Linting CoffeeScript with $COFFEE_PATH/$COFFEE_CONF"
	else
		echo "Local $COFFEE_CONF not found in $COFFEE_PATH, using default"
		status "Linting CoffeeScript with $COFFEE_LINK"
		curl -o "$TMP_PATH@$COFFEE_CONF" ${COFFEE_LINK}
		COFFEE_ARGS="$COFFEE_ARGS --file $TMP_PATH@$COFFEE_CONF"
	fi

	command="$NODE_BIN_PATH/$COFFEE_EXEC $COFFEE_ARGS"
	warning "Running <$command>"
	eval ${command} || { valid=false; }

	if ${coffeelintignore_found} = true; then
	    rm ${COFFEE_IGNR}
	fi
}

lint_haml() {
	header 'Linting HAML'

	if ! gem query -i -n ${HAML_EXEC} > /dev/null; then
		status "Installing $HAML_EXEC"
		gem install ${HAML_EXEC} --no-ri --no-rdoc
	fi

	status "Looking for local $HAML_CONF in $HAML_PATH"
	if test -e "$HAML_PATH/$HAML_CONF"; then
		echo "Found $HAML_CONF in $HAML_PATH"
		status "Linting ruby/rails with $HAML_PATH/$HAML_CONF"
	else
		echo "Local $HAML_CONF not found in $HAML_PATH, using default"
		status "Linting HAML with $HAML_LINK"
		curl -o "$TMP_PATH@$HAML_CONF" ${HAML_LINK}
		HAML_ARGS="$HAML_ARGS --config $TMP_PATH@$HAML_CONF"
	fi

	command="bundle exec $HAML_EXEC $HAML_ARGS"
	warning "Running <$command>"
	eval ${command} || { valid=false; }
}

lint_javascript() {
    header 'Linting JavaScript'

    abort_if_yarn_is_missing

    if ! test "$NODE_BIN_PATH/$ESLINT_EXEC"; then
        status "Installing $ESLINT_EXEC"
        yarn add ${ESLINT_EXEC} --dev
        yarn add babel-eslint --dev
        yarn add eslint-plugin-react --dev
    fi

    if [[ ! -z $(printf '%s\n' "$@" | grep -w 'js') ]]; then
		ESLINT_ARGS="$ESLINT_ARGS --ext .js"
	fi

	if [[ ! -z $(printf '%s\n' "$@" | grep -w 'jsx') ]]; then
		ESLINT_ARGS="$ESLINT_ARGS --ext .jsx"
	fi

    status "Looking for local $ESLINT_IGNR in $ESLINT_PATH"
    if test -e "$ESLINT_PATH/$ESLINT_IGNR"; then
        echo "Found $ESLINT_IGNR in $ESLINT_PATH"
    else
        eslintignore_found=true
        echo "Local $ESLINT_IGNR not found in $ESLINT_PATH, using default"
        curl -o "$TMP_PATH@$ESLINT_IGNR" "$IGNORE_URL/$ESLINT_IGNR"
		cp "$TMP_PATH@$ESLINT_IGNR" ${ESLINT_IGNR}
    fi

    status "Looking for local $ESLINT_CONF in $ESLINT_PATH"
    if test -e "$ESLINT_PATH/$ESLINT_CONF"; then
        echo "Found $ESLINT_CONF in $ESLINT_PATH"
        status "Linting JavaScript with $ESLINT_PATH/$ESLINT_CONF"
    else
        echo "Local $ESLINT_CONF not found in $ESLINT_PATH, using default"
        status "Linting JavaScript with $ESLINT_LINK"
        curl -o "$TMP_PATH@$ESLINT_CONF" ${ESLINT_LINK}
        ESLINT_ARGS="$ESLINT_ARGS --c $TMP_PATH@$ESLINT_CONF"
    fi

    command="$NODE_BIN_PATH/$ESLINT_EXEC $ESLINT_ARGS"
    warning "Running <$command>"
    eval ${command} || { valid=false; }

    if ${eslintignore_found} = true; then
        rm ${ESLINT_IGNR}
    fi
}

lint_ruby_or_rails() {
	header 'Linting Ruby/Rails'

    if ! type -P ruby > /dev/null; then
    	abort 'ruby is not installed'
	fi

	if ! gem query -i -n ${RUBOCOP_EXEC} > /dev/null; then
		status "Installing $RUBOCOP_EXEC"
		gem install ${RUBOCOP_EXEC} --no-ri --no-rdoc
	fi

	if [[ ! -z $(printf '%s\n' "$@" | grep -w 'rails') ]]; then
		RUBOCOP_ARGS="$RUBOCOP_ARGS --rails"
	fi

	status "Looking for local $RUBOCOP_CONF in $RUBOCOP_PATH"
	if test -e "$RUBOCOP_PATH/$RUBOCOP_CONF"; then
		echo "Found $RUBOCOP_CONF in $RUBOCOP_PATH"
		status "Linting ruby/rails with $RUBOCOP_PATH/$RUBOCOP_CONF"
	else
		echo "Local $RUBOCOP_CONF not found in $RUBOCOP_PATH, using default"
		status "Linting ruby/rails with $RUBOCOP_LINK"
		curl -o "$TMP_PATH@$RUBOCOP_CONF" ${RUBOCOP_LINK}
		RUBOCOP_ARGS="$RUBOCOP_ARGS --config $TMP_PATH@$RUBOCOP_CONF"
	fi

	command="bundle exec $RUBOCOP_EXEC $RUBOCOP_ARGS"
	warning "Running <$command>"
	eval ${command} || { valid=false; }
}

lint_sass_or_scss() {
    header 'Linting SASS/SCSS'

    abort_if_yarn_is_missing

    if ! test "$NODE_BIN_PATH/$SASS_EXEC"; then
		status "Installing $SASS_EXEC"
		yarn add ${SASS_EXEC} --dev
	fi

	status "Looking for local $SASS_CONF in $SASS_PATH"
	if test -e "$SASS_PATH/$SASS_CONF"; then
		echo "Found $SASS_CONF in $SASS_PATH"
		status "Linting SASS/SCSS with $SASS_PATH/$SASS_CONF"
	else
		echo "Local $SASS_CONF not found in $SASS_PATH, using default"
		status "Linting SASS/SCSS with $SASS_LINK"
		curl -o "$TMP_PATH@$SASS_CONF" ${SASS_LINK}
		SASS_ARGS="$SASS_ARGS --config $TMP_PATH@$SASS_CONF"
	fi

	command="$NODE_BIN_PATH/$SASS_EXEC $SASS_ARGS"
	warning "Running <$command>"
	eval ${command} || { valid=false; }
}

abort_if_yarn_is_missing() {
    if ! type -P yarn > /dev/null; then
        abort 'yarn is not installed'
    fi
}

abort() {
	error "$1"; exit 1
}

error() {
	tput setaf 1; echo "ERROR: $1"; tput sgr0
}

success() {
	tput setaf 2; echo "SUCCESS: $1"; tput sgr0
}

warning() {
	tput setaf 3; echo "$1"; tput sgr0
}

status() {
	tput setaf 4; echo "$1..."; tput sgr0
}

header() {
	tput setaf 5; tput bold; echo; echo "===== $1 ====="; tput sgr0
}

validate_args "$@"

if [[ ! -z $(printf '%s\n' "$@" | grep -w 'haml') ]]; then
    lint_coffee_script
fi

if [[ ! -z $(printf '%s\n' "$@" | grep -w 'haml') ]]; then
    lint_haml
fi

if [[ ! -z $(printf '%s\n' "$@" | grep -w 'js\|jsx') ]]; then
    lint_javascript "$@"
fi

if [[ ! -z $(printf '%s\n' "$@" | grep -w 'ruby\|rails') ]]; then
    lint_ruby_or_rails "$@"
fi

if [[ ! -z $(printf '%s\n' "$@" | grep -w 'sass\|scss') ]]; then
    lint_sass_or_scss
fi

echo

if ${valid}; then
	success 'All linters have completed without errors.'
else
	abort 'Some linters have completed with errors.'
fi
