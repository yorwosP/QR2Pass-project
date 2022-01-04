from django.db import models

"""
only user data for authentication are persistent in this app
"""

from django.contrib.auth.models import AbstractUser, AbstractBaseUser
from django.utils.translation import ugettext_lazy as _
from django.contrib.auth.base_user import BaseUserManager

from Crypto.PublicKey import RSA
from Crypto.Hash import SHA512
from base64 import b64decode
from Crypto.Signature import PKCS1_v1_5


class UserManager(BaseUserManager):
    """
    user manager for custom user
    """
    use_in_migrations = True

    def _create_user(self, email, password=None, **extra_fields):
        """
        custom create_user function       
        Creates and saves a User

        parameters:
        email: string 
            email of the user (user id)
        public_key: string 
            user's public key

        Returns: 
        the user created 
        """
        if not email:
            raise ValueError('The given email must be set')
        email = self.normalize_email(email)
        username = email
        extra_fields.setdefault('username', username)
        public_key = extra_fields.get('public_key', None)
        # !!TODO!! what to do if pubic key is not provided?
        # if not public_key:
        #     raise ValueError('a public key must be set')

        user = self.model(email=email, **extra_fields)
        user.is_admin = False

        user.save(using=self._db)
        if password:
            # only superuser will have password
            user.set_password(password)

        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_superuser', False)
        # extra_fields.setdefault('is_admin', False)
        return self._create_user(email, **extra_fields)

# !!CHECK!! the superuser probably needs a password
    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_superuser', True)
        # extra_fields.setdefault('is_staff', True)

        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self._create_user(email, password, **extra_fields)


class MyUser(AbstractUser):
    """
    MyUser:
    Custom user model
    At this point only email and public key are used
    """
    email = models.EmailField(
        _('email address'), unique=True,  primary_key=True)  # email is the user identifier

    first_name = models.CharField(_('first name'), max_length=30, blank=True)
    last_name = models.CharField(_('last name'), max_length=30, blank=True)
    date_joined = models.DateTimeField(_('date joined'), auto_now_add=True)
    is_active = models.BooleanField(_('active'), default=False)
    # is_admin = models.BooleanField(_('admin'), default=False)
    # is_staff = models.BooleanField(_('staff'), default=False)
    # user = models.OneToOneField(User, on_delete=models.CASCADE)
    # !!CHECK!! how much space needed to store a public key
    # !!CHECK!! if we need to alert the user that we have already a user with the same public key
    public_key = models.CharField(
        _('public key'), max_length=1000)
    objects = UserManager()
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        verbose_name = _('user')
        verbose_name_plural = _('users')

    def get_full_name(self):
        '''
        Returns the first_name plus the last_name, with a space in between.
        '''
        full_name = '%s %s' % (self.first_name, self.last_name)
        return full_name.strip()

    def get_short_name(self):
        '''
        Returns the short name for the user.
        '''
        return self.first_name

    # def email_user(self, subject, message, from_email=None, **kwargs):
    #     '''
    #     Sends an email to this User.
    #     '''
    #     send_mail(subject, message, from_email, [self.email], **kwargs)
    def has_perm(self, perm, obj=None):
        "Does the user have a specific permission?"
        # Simplest possible answer: Yes, always
        return True

    def has_module_perms(self, app_label):
        "Does the user have permissions to view the app `app_label`?"
        # Simplest possible answer: Yes, always
        return True

    def response_is_correct(self, challenge, response):
        """
        the main method used for authentication
        verifies if the challenge was signed by
        the private key of the user

        parameters:
        challenge: string 
            the nonce send by the server
        response: string
        the hashed challenge (signature) signed by the private key of the user

        returns: 
        True if the signature is correct, False if not
        """

        # first hash the challenge
        digest = SHA512.new()
        digest.update(challenge.encode('utf-8'))

        # create an RSA key from the public key stored for the user
        public_key = self.public_key
        rsakey = RSA.importKey(b64decode(public_key))
        signer = PKCS1_v1_5.new(rsakey)
        # validate that the signed challenge was signed by the private half of the key

        return signer.verify(digest, b64decode(response))
