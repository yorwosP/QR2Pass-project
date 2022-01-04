"""
api app
handle all the requests coming outband (i.e from iphone app)
therefore no csrf token can be used
"""

from django.shortcuts import render
from django.contrib.auth import authenticate, login as dj_login
from django.contrib.sessions.models import Session
from django.views.decorators.http import require_http_methods
from .models import MyUser
from .signals import session_login, session_register, session_received, session_cancelled
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.conf import settings
import redis
import json
import time


# connect to  Redis instance
# !!TODO!! handle connection issues!
redis_instance = redis.from_url(settings.REDIS_URL)


@csrf_exempt
def register(request):
    """
    register function: 
    receives the register request (email, sent back nonce and public key) 
    checks if the request has the correct format and the nonce 
    is still valid and adds the user in the DB
    sends a signal when the session is received (and is valid)
    and another signal when the registration is complete 

    returns: 
        an ok/nok response
    """
    name = ""
    # only post method allowed
    if request.method == "POST":
        body = ''
        email = ''
        nonce = ''
        key = ''
        public_key = ''

        # decode the json request
        try:
            body = json.loads(request.body.decode('utf-8'))
            email = body["email"]
            nonce = body["nonce"]
            key = 'email:'+email
            public_key = body["public_key"]

        except:
            # no valid schema
            response = create_response(
                'null', 'nok', 'invalid request')
            return JsonResponse(response)

        # check if a valid nonce exists for this user
        redis_token = redis_instance.get(key)

        if redis_token == None:
            # print("no token exists, or token has expired  for", email)
            response = create_response(
                email, 'nok', 'no token exists, or token has expired  for {0}'.format(email))

        else:
            token = redis_token.decode("utf-8")
            # check if nonce sent by the client is the one stored
            if token == nonce:
                # ok
                session_key = 'nonce:'+nonce
                redis_session_key = redis_instance.get(session_key)

                # extract the corresponding web session from redis
                session_token = redis_session_key.decode("utf-8")

                # send a signal to the corresponding session that we've received a message
                # and we are processing it
                # ( used to update the GUI)
                session_received.send(sender=email, session_id=session_token)
                # !!CHECK!! the following
                # retrieve the session from the session database
                web_session = Session.objects.get(pk=session_token)

                # !!TODO: - do not add the user yet in the DB
                #  store it temporarily (in Redis?) until is logged in

                # create a user and add them to the DB
                user = MyUser.objects.create_user(
                    email=email, public_key=public_key)
                user.save()
                # return a response to client
                response = create_response(
                    email, 'ok', 'succesfully created user')
                # send a signal that register was done succesfully
                session_register.send(
                    sender=user.email, session_id=web_session.session_key)

            else:
                # the nonce received is not the nonce sent initially
                # nonce has expired or
                # someone is doing something nasty (replay a request)
                print("invalid token. Stored in redis:{0}, received:{1}".format(
                    redis_token, nonce))
                response = create_response(email, 'nok', 'invalid token')

    else:
        # only expecting POST methods
        response = create_response(
            'null', 'nok', 'invalid ({0}) request'.format(request.method))

    return JsonResponse(response)


"""
login request schema
{
    "username": "saas@dsj.com",
    "response": "ej2O5+e3NKs1fp+K5cNAiq1sVUMufQJmrfFbAmcndRdf0vst3/zfALMA6VVshlljFrx17bLNaE1k4zeLiJNTABFwzd0EYBgxMD+yx3a1/q43ZZrK8jDy0vOoRiDgg9GHTA+kQBfbBmDGKrczBkpbsiBESjWU3dFBNdXVQtGilPoOnhq89wY25yxXcAR3BFCRvrRStVQcldTw77XkhFV5OBfD8VbjgVIYn0YxYmB3DsmjKVY4SUdrdUVSFRuElVq0KVFxn+N8Vz4uDfakE5pm8c8m4lR/oCHOlr13auZzKHvGlSf8QjYMXi+7Q2w5M5lTDjFU4eBHodX9zfIMnJS58A==",
    "challenge": "7vZ-tUBuzws=",
    "version": 1
}
"""


@csrf_exempt
def login(request):
    """
    login function: 
    receives the login request (email, sent back nonce and public key) 
    1. checks if:
        -  the request has the correct format and the nonce is still valid
        -  the claimed user exists in the DB (has previously registered)
    2. Authenticates the user
    3. Adds the user_id in the corresponding web session (so the user can be logged in web)
    4. Sends a signal when the session is received and when the authentication process
       has finished

    returns: (JsonResponse)
        an ok/nok response
    """

    name = ""
    # only POST methods are allowed
    if request.method == "POST":
        body = ''
        username = ''
        challenge = ''
        response = ''
        key = ''

        try:
            body = json.loads(request.body.decode('utf-8'))
            username = body["username"]
            challenge = body["challenge"]
            response = body["response"]
            key = 'nonce:'+challenge

        except:
            # not valid schema
            response = create_response(
                'null', 'nok', 'invalid request')
            return JsonResponse(response)

        # check if a nonce exists for this user
        redis_token = redis_instance.get(key)

        if redis_token == None:
            # nok
            response = create_response(
                username, 'nok', 'no token exists, or token has expired')
        else:
            # ok
            # delete the token from redis (don't allow other user to replay the request)
            redis_instance.delete(key)
            # !!TODO!! token exists but is it for this specific user?
            session_key = redis_token.decode("utf-8")
            # find the corresponding web session
            web_session = Session.objects.get(pk=session_key)
            # and send a signal to it that the login procedure has started
            session_received.send(
                sender="Anonymous", session_id=web_session.session_key)
            # does the user exist in the DB (i.e already registered)?
            try:
                user = MyUser.objects.get(pk=username)
                # user exists, can it be authenticated based on the signed challenge
                user = authenticate(
                    email=username, challenge=challenge, response=response)
                if user is not None:
                    # user authenticated, logging in (!!CHECK!! do we actually need to do that? )
                    dj_login(request, user)
                    current_session = request.session
                    # store the user id in the corresponding web session(used to login the session itself)
                    d = web_session.get_decoded()
                    d['user_id'] = user.email
                    web_session.session_data = Session.objects.encode(d)
                    web_session.save()

                    # send a signal to the corresponding web session
                    # that the user was logged in
                    session_login.send(sender=user.email,
                                       session_id=web_session.session_key)
                    response = create_response(
                        username, 'ok', 'user authenticated')

                else:
                    # user authentication failed
                    # TODO: notify core

                    response = create_response(
                        username, 'nok', 'authentication failure')

            except MyUser.DoesNotExist:
                # user is not registered
                # notify core
                session_cancelled.send(
                    sender="Anonymous", session_id=web_session.session_key)
                response = create_response(
                    username, 'nok', 'user not registered')

    else:
        # only POST methods are allowed
        response = create_response(
            'null', 'nok', 'invalid ({0}) request'.format(request.method))

    return JsonResponse(response)


@csrf_exempt
def logout(request):
    """
    logout from ios app 
    not used at this point
    """
    name = ""
    print("method is:", request.method)
    if request.method == "POST":
        # !!TODO!!: check for invalid request
        # maybe create a session secret exchanged at login (and invalidated in logout)
        # that user has to present and sign with its private key

        # in this case the nonce is created by the client - this is not safe because a captured message can be replayed
        # for now we will not use the nonce (!!CHECK!! anyone can claim to be this user and logout)
        body = json.loads(request.body.decode('utf-8'))
        username = body["username"]
        challenge = body["challenge"]
        response = body["response"]
        key = 'logout-nonce:'+challenge

        # check if a nonce exists for this user
        redis_token = redis_instance.get(key)
        print("want to authenticate session:", redis_token)

        if redis_token == None:
            print("no token exists, or token has expired  for", challenge)
            response = create_response(
                username, 'nok', 'no token exists, or token has expired')
        else:
            # there is a token. Authenticate user
            token = redis_token.decode("utf-8")
            print("token exists, moving on", token)
            user = authenticate(
                email=username, challenge=challenge, response=response)
            if user is not None:
                print("user {0} authenticated! and its id is: {1}".format(
                    user, user.email))
                dj_login(request, user)
                current_session = request.session

                web_session = Session.objects.get(pk=token)
                # web_session['user_id'] = user.email
                d = web_session.get_decoded()
                d['user_id'] = user.email

                # print('set user to', d.user_id)
                web_session.session_data = Session.objects.encode(d)
                web_session.save()
                # web_session.get_decoded()['user_id'] = user

                print("web session", web_session.get_decoded())
                print("current session", current_session.session_key)
                print("request:{0}, user:{1}, meta{2}".format(
                    request, request.user, request.META))
                # send a signal that the user was logged in
                session_login.send(sender=user.email,
                                   session_id=web_session.session_key)

                response = create_response(
                    username, 'ok', 'user authenticated')
            else:
                print("authentication failed for", user)
                response = create_response(
                    username, 'nok', 'authentication failure')

    else:
        print("not expecting a get method here")
        response = create_response(
            'null', 'nok', 'invalid ({0}) request'.format(request.method))

    return JsonResponse(response)


def create_response(user, status, message=''):
    """
    create response:
    formats the response based on the following schema
    {
        "version": Int //ignored for now
        "email": String,
        "status": status, // enum (ok/nok)
        "response_text": String // (optional) -> more info if the register/login failed.
    }
    """

    response = {
        'version': settings.API_VERSION,
        'email': user,
        'status': status,
        'response_text': message

    }
    return response
