"""
Django production settings for core project
"""

import os
import json
import dj_database_url

DEBUG = True if (os.environ.get("DEBUG", "true").lower() == "true") else False

SECRET_KEY = os.environ.get("SECRET_KEY")

DEFAULT_CONNECTION = dj_database_url.parse(os.environ.get("DATABASE_URL"))
DEFAULT_CONNECTION.update({"CONN_MAX_AGE": 600})
DATABASES = {"default": DEFAULT_CONNECTION}

ALLOWED_HOSTS = json.loads(os.environ.get("ALLOWED_HOSTS", "[\"*\"]"))
