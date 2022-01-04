"""
additional django settings template used for deployment 
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
SECRET_KEY =  # provide your secret here


ALLOWED_HOSTS = []  # define your allowed hosts here
APP_HOME_URL =  # the base url (e.g qr2pass.herokuapp.com)


# url identifying the web server (used to populate the "provider" field in the qr codes)
PROVIDER =


# Database
# https://docs.djangoproject.com/en/3.2/ref/settings/#databases


# you can use the following to deploy to heroku


db_from_env = dj_database_url.config(conn_max_age=500)
DATABASES['default'].update(db_from_env)


django_heroku.settings(locals())


STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
