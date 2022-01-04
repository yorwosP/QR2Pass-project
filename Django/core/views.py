from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.conf import settings
from django.contrib.auth.decorators import login_required
import json
import redis
import os
import base64
import math
import datetime
from django.core.validators import validate_email
from django.core.exceptions import ValidationError


from django.contrib.auth import login as dj_login, get_user_model, logout
from api.models import MyUser

HOME_URL = settings.APP_HOME_URL

# !!CHECK!!  in ios if we need App Transport Security Settings when using here https


# connect to  Redis instance
# !!TODO!! handle connection issues!

redis_instance = redis.from_url(settings.REDIS_URL)


def logout_view(request):
    """
    logout view: 
    remove the user_id from the session and
    logout the user
    """
    if request.user.is_authenticated:
        user_id = request.session.pop('user_id')
        logout(request)

    return redirect('loginPage')


def register(request):
    """
    register view:
    get user's details (currently only email needed to register)
    and redirect to a page showing the QR code (create_registration_response)
    to complete the registration process
    """

    email = ""
    if not request.session.exists(request.session.session_key):
        request.session.create()

    if request.method == "POST":
        # !! TODO!! find a clean way to check if the user already
        # exists in the database (currently the user database is handled by api application)

        email = request.POST['your_email']

        # check if this username (email) already exists in the DB
        user_model = get_user_model()
        is_taken = user_model.objects.filter(
            username__iexact=email).exists()
        if is_taken:
            # user(name) already exists
            return render(request, "core/register.html", context={'error': 'User already exists in the database'})
        else:

            data = json.dumps(
                create_registration_response(email, request.session))
            context = {'data': data}

            return render(request, "core/register.html", context=context)
    elif request.method == "GET":
        pass

    return render(request, "core/register.html", {'email': email})


def main_page(request):
    """
    main view:
    either initial page, or user page (if authenticated)
    """

    if request.user.is_authenticated:
        return redirect('userPage')
    else:
        return render(request, "core/firstpage.html")


def login(request):
    """
    login view:
    create and store (redis) a nonce, response data
    (will be used to construct the QR code)

    actual authentication is done in api login
    and if succesful we persist the user id in this 
    request (to keep user authenticated)
    """
    user_model = get_user_model()

    if 'user_id' in request.session:

        # find the user
        # !!CHECK!! maybe a double check that the user actually exists
        # we want to remove it so it won't mess up things when we log out
        # user_id = request.session.pop('user_id')
        user_id = request.session['user_id']
        user = user_model.objects.get(pk=user_id)
        # now persist in the session (so they stay authenticated)
        dj_login(request, user)

    if request.user.is_authenticated:
        return redirect('userPage')

    if not request.session.exists(request.session.session_key):
        request.session.create()

    if request.method == 'GET':
        # create a nonce which expires in 60 seconds
        valid_till = int((datetime.datetime.now() +
                          datetime.timedelta(0, 60)).timestamp())
        nonce = generate_nonce()

        """
        construct the response (will be used to create the QR code in the front end)

        {
            "version": Int, //ignored for now
            "challenge": String,
            "validTill": Date, // till when the nonce is valid for 
            "provider": URL, //base url for the site (this is the identifier for the site),
            "action": action.login //action.login ("login")
        }


        """

        response = {

            'version': settings.API_VERSION,
            # !!CHECK!! generate_nonce takes email as an argument. Now using session id instead
            'challenge': nonce,
            'valid_till': valid_till,
            'provider': settings.PROVIDER,
            'action': 'login',
            'respond_to': HOME_URL + '/api/login/'

        }

        # store the nonce for the session in redis
        store_session(request.session.session_key, nonce)

        request.session.session_key
        # add the nonce to the session (will be used to retrieve the channel group)
        request.session['nonce'] = nonce

        # send the data back to the client
        # print("send back the response", response)
        data = json.dumps(response)
        context = {'data': data}
        return render(request, "core/login.html", context=context)

    else:
        pass


def user_page(request):
    """
    user page view: 
    just the username (email) if authenticated
    else redirect to main page 
    """
    if request.user.is_authenticated:
        return render(request, "core/userpage.html")
    else:
        return render(request, 'core/firstpage.html')


def create_registration_response(email, session):
    """
    create a json object that is used by the
    frontend to create the registration QR code
    store also the email:nonce and session_key:nonce in redis

    """

    nonce = generate_nonce()

    """
    RESPONSE SCHEMA
    {
        "version": Int, //ignored for now
        "username": String,
        "email: String
        "provider": URL, //base url for the site (this is the identifier for the site),
        "respondTo": URL,
        "action": action enum //action.register ("register")
    }
    """

    response = {
        'version': settings.API_VERSION,
        'email': email,
        'nonce': nonce,
        'respond_to': HOME_URL + '/api/register/',
        'provider': settings.PROVIDER,
        'action': 'register'
    }
    store_email(email, nonce)
    store_session(session.session_key, nonce)
    return response


def validate_username(request):
    """
    ajax request to validate the username (already exists, valid email etc)
    """

    # first verify that this is an ajax request
    if request.is_ajax and request.method == "GET":
        username = request.GET.get('username', None)
        is_taken = False
        data = {'is_taken': False, 'is_valid': False}
        is_valid_email = False
        # validate email
        try:
            validate_email(username)
            is_valid_email = True
        except ValidationError:
            is_valid_email = False
        user_model = get_user_model()
        is_taken = user_model.objects.filter(
            username__iexact=username).exists()
        data = {'is_taken': is_taken, 'is_valid': is_valid_email}

        # data = {
        #     'is_taken': user_model.objects.filter(username__iexact=username).exists()
        # }
        return JsonResponse(data)
    return JsonResponse({}, status=400)


def generate_nonce(length=8):
    """ 
    Generates a random string of bytes, base64 encoded 
    to be used as nonce 
    """
    if length < 1:
        return ''
    string = base64.b64encode(os.urandom(length), altchars=b'-_')
    b64len = 4*math.floor(length)
    if length % 3 == 1:
        b64len += 2
    elif length % 3 == 2:
        b64len += 3
    nonce = string[0:b64len].decode()

    return nonce


def store_email(email, nonce):
    """
    stores a "email"+email:nonce record in redis
    expires in 60 seconds
    """

    key = "email:"+email
    value = nonce
    # check if a token already exists for this user
    current_token = redis_instance.get(email)
    # !!TODO!! do something useful if token already exists
    if current_token != None:
        print("token already exists for user {0}".format(email))
    else:
        print("will add:", key, value)
        # write to redis with a expiry of 60 seconds
        redis_instance.setex(key, 60, value)


def store_session(session_key, nonce):
    """
    stores a "nonce"+nonce:session_key record in redis
    expires in 60 seconds
    """
    key = "nonce:"+nonce
    value = session_key
    redis_instance.setex(key, 60, value)
