"""
django settings specific to deployment (for Heroku)
"""
from .defaults import *
import dj_database_url
import django_heroku
from pathlib import Path
import os


DEBUG = False


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/3.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('SECRET_KEY')


ALLOWED_HOSTS = ['.herokuapp.com']
APP_HOME_URL = os.environ.get('APP_HOME_URL')


PROVIDER = 'qr2pass.herokuapp.com'


# Database
# https://docs.djangoproject.com/en/3.2/ref/settings/#databases


db_from_env = dj_database_url.config(conn_max_age=500)
DATABASES['default'].update(db_from_env)


# Activate Django-Heroku.
django_heroku.settings(locals())
# STATIC_ROOT = os.path.join(BASE_DIR, 'static')

STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
