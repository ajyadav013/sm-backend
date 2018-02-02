PROJECT_NAME=core  # name of first project to be created
SRC_DIR_NAME=src  # name of directory that will house all the source code

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/  # scripts directory
ROOT_DIR=$( cd "$( dirname "${DIR}../../" )" && pwd )/  # root directory
SRC_DIR=${ROOT_DIR}${SRC_DIR_NAME}/  # path to source directory
PROJECT_DIR=${ROOT_DIR}${SRC_DIR_NAME}/${PROJECT_NAME}/  # path to first project's directory

# check if gnu sed is installed incase of osx, and install if not
if [ "$(uname)" == "Darwin" ]; then
    command -v gsed >/dev/null 2>&1 || {
	echo "I require gsed but it's not installed. Installing." >&2;
	brew install gnu-sed
    }
    SED_BINARY=`which gsed`
else
    SED_BINARY=`which sed`
fi

# check if it is a virtual env
if [ -d "${ROOT_DIR}bin" ]; then
    export BIN=${ROOT_DIR}bin/
else
    export BIN=""
fi

# exit if source directory already exists
if [ -d "${SRC_DIR}" ]; then
    exit 0
fi

# create source directory
mkdir ${SRC_DIR}

# create django project in source directory
${BIN}django-admin startproject ${PROJECT_NAME} ${SRC_DIR}

# pylint doesn't like module level variable to be in lowercase, disable the check
${SED_BINARY} -i 's/application = get_wsgi_application()/APPLICATION = get_wsgi_application()/g' ${PROJECT_DIR}wsgi.py

# add path to source code in <src dir>/<project>/wsgi.py
${SED_BINARY} -i '/import os/i\
import sys
' ${PROJECT_DIR}wsgi.py
${SED_BINARY} -i '/os\.environ\.setdefault/i\
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))
' ${PROJECT_DIR}wsgi.py

# add documentation to manage.py
${SED_BINARY} -i '2i\
\
"""\
A thin wrapper around ```django-admin```.\
It takes care of several things for us before delegating to ```django-admin```.\
\
For more information on this file, see\
https://docs.djangoproject.com/en/stable/ref/django-admin/\
"""\
\
' ${SRC_DIR}manage.py

# create settings directory
mkdir ${PROJECT_DIR}settings

# create a backup of original settings file
# cp ${PROJECT_DIR}/settings.py ${PROJECT_DIR}settings/original.py

# pylint doesnt like it when multiple files have same code, instruct pylint to skip the backup file
# ${SED_BINARY} -i '1i\
#  # pylint: skip-file\
#  ' ${PROJECT_DIR}settings/original.py

# move settings.py to settings/__init__.py
mv ${PROJECT_DIR}/settings.py ${PROJECT_DIR}settings/__init__.py

# update wsgi settings to use core.wsgi.APPLICATION instead of core.wsgi.application
${SED_BINARY} -i 's/WSGI_APPLICATION = .*/WSGI_APPLICATION = "core.wsgi.APPLICATION"/g' ${PROJECT_DIR}settings/__init__.py

# remove lines having SECRET_KEY and it's help text
${SED_BINARY} -i '/secret key used/d' ${PROJECT_DIR}settings/__init__.py
${SED_BINARY} -i '/SECRET_KEY \=/ { N; d; }' ${PROJECT_DIR}settings/__init__.py

# remove DEBUG settings and help text
${SED_BINARY} -i '/debug turned on/d' ${PROJECT_DIR}settings/__init__.py
${SED_BINARY} -i '/DEBUG \=/ { N; d; }' ${PROJECT_DIR}settings/__init__.py

# remove ALLOWED_HOSTS settings
${SED_BINARY} -i '/ALLOWED_HOSTS/ { N; N; d; }' ${PROJECT_DIR}settings/__init__.py

# remove DATABASES settings
${SED_BINARY} -i '/# Database/ { N; N; N; N; N; N; N; N; N; N; d; }' ${PROJECT_DIR}settings/__init__.py

# import settings from local/production settings file
${SED_BINARY} -i '/BASE_DIR =/i\
try:\
from .local import (DEBUG, SECRET_KEY, DATABASES, ALLOWED_HOSTS)\
except ImportError:\
from .production import (DEBUG, SECRET_KEY, DATABASES, ALLOWED_HOSTS)\
\
' ${PROJECT_DIR}settings/__init__.py
${SED_BINARY} -i -E 's/from ./    from ./g' ${PROJECT_DIR}settings/__init__.py

# add static directory path to settings
${SED_BINARY} -i '/STATIC_URL/i\
STATIC_ROOT = os.path.join(BASE_DIR, "..", "..", "assets")
' ${PROJECT_DIR}settings/__init__.py

# create a production settings file
echo "\"\"\"
Django production settings for core project
\"\"\"

import os
import json
import dj_database_url

DEBUG = True if (os.environ.get(\"DEBUG\", \"true\").lower() == \"true\") else False

SECRET_KEY = os.environ.get(\"SECRET_KEY\")

DEFAULT_CONNECTION = dj_database_url.parse(os.environ.get(\"DATABASE_URL\"))
DEFAULT_CONNECTION.update({\"CONN_MAX_AGE\": 600})
DATABASES = {\"default\": DEFAULT_CONNECTION}

ALLOWED_HOSTS = json.loads(os.environ.get(\"ALLOWED_HOSTS\", \"[\\\"*\\\"]\"))" > ${PROJECT_DIR}settings/production.py

# generate a security key for local settings template file
LOCAL_SECURITY_KEY=`\`which python3\` -c 'import random; import string; print("".join([random.SystemRandom().choice(string.digits + string.ascii_letters + string.punctuation.replace("\"", "").replace("\\\\", "")) for i in range(60)]))'`

# create a local settings template file
echo "\"\"\"
Django local settings template for core project
\"\"\"

DEBUG = True

SECRET_KEY = \"${LOCAL_SECURITY_KEY}\"

DATABASES = {\"default\": {
    \"ENGINE\": \"django.db.backends.sqlite3\",
    \"NAME\": \"core.db.sqlite3\",
}}

ALLOWED_HOSTS = [\"*\"]" > ${PROJECT_DIR}settings/local_template.py

# copy local settings template file to local settings file
cp ${PROJECT_DIR}settings/local_template.py ${PROJECT_DIR}settings/local.py

# instruct pylint to validate local settings file as it has a duplicate code from local template file
${SED_BINARY} -i '1i\
# pylint: skip-file\
' ${PROJECT_DIR}settings/local.py

# add settings to server files in production mode
echo "if not settings.DEBUG:
    urlpatterns += [url(r'^static/(?P<path>.*)$', serve, {'document_root': settings.STATIC_ROOT}), ]" >> ${PROJECT_DIR}urls.py

# import settings from local/production settings file
${SED_BINARY} -i '/import admin/i\from django.views.static import serve\
from django.conf import settings' ${PROJECT_DIR}urls.py

# collect static
${BIN}python ${SRC_DIR}manage.py collectstatic --noinput
