"""
Django local settings template for core project
"""

DEBUG = True

SECRET_KEY = "Zx[#c@L[Nk+HyxWqsIZ[d(I-}1g1aZXamuM5H#wl]LQYOOCm/=<jr'&aocPC"
FACEBOOK_APP_SECRET = ""
DATABASES = {"default": {
    "ENGINE": "django.db.backends.sqlite3",
    "NAME": "core.db.sqlite3",
}}

ALLOWED_HOSTS = ["*"]
