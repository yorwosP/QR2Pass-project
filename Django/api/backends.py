from django.contrib.auth.backends import BaseBackend
from django.contrib.auth.models import User
from .models import MyUser


class MyBackend(BaseBackend):
    """
    Custom authentication backend
    """

    def get_user(self, email):
        try:
            return MyUser.objects.get(pk=email)
        except MyUser.DoesNotExist:
            return None

    def authenticate(self, request, **kwargs):
        email = kwargs['email']

        # the challenge received should match one sent before (and not expired)
        # this is checked in api.login function
        challenge = kwargs['challenge']
        response = kwargs['response']

        try:
            user = MyUser.objects.get(email=email)
            if user.response_is_correct(challenge, response) is True:
                return user
        except MyUser.DoesNotExist:
            pass
