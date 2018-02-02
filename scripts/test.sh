DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/
export ROOT_DIR=$( cd "$( dirname "${DIR}../../" )" && pwd )/

if [ -d "${ROOT_DIR}bin" ]; then
    export BIN=${ROOT_DIR}bin/
else
    export BIN=""
fi


find ${ROOT_DIR}src -type f -name "*.py" -not -iwholename '*/migrations/*.py' -exec ${BIN}pep8 --ignore=E501 {} \;

find ${ROOT_DIR}src -type f -name "*.py" -not -iwholename '*/migrations/*.py' -exec ${BIN}pylint --load-plugins pylint_django --disable=line-too-long,file-ignored '{}' +
