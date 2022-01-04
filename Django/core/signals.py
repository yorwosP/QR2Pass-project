from django.contrib.auth import user_logged_in, user_logged_out
from django.dispatch import receiver, Signal
from api.models import MyUser
from django.contrib.sessions.models import Session
from api.signals import session_login, session_register, session_received, session_cancelled
from channels.layers import get_channel_layer
# from .models import Client
from asgiref.sync import async_to_sync

# TODO: implement a cancel


@receiver(session_cancelled)
def on_user_cancel(sender, **kwargs):
    """
    handle cancel signal
    notify the web session that processing of a request was cancelled
    """
    user_sent = sender
    session_id = kwargs.get('session_id')
    # print("SESSION LOGIN signal for {0} with {1}".format(
    #     user_sent, session_id))
    channel_layer = get_channel_layer()

    # group name for non logged-in session is group-[session_id]
    group_name = 'group-%s' % session_id
    # print('in signal will try to send to the group', group_name)

    # send a stop command to the group
    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            'type': 'command_message',
            'message': 'stop'
        }

    )


@receiver(user_logged_in)
def on_user_login(sender, **kwargs):
    """
    not currently used (not registered signal)
    """
    user_sent = kwargs.get('user')


@receiver(user_logged_out)
def on_user_logout(sender, **kwargs):
    """
    handle user logout signal
    remove all sessions for this user from session db
    notify all web sessions that this user logged out
    (will force redirect to /logout on the front end)
    """
    user_sent = str(kwargs.get('user'))
    # print('need to logout', user_sent)
    user = MyUser.objects.get(email=user_sent)

    # find all the sessions for the user and delete them
    # !!TODO!! find a more effective way to do that (e.g use django-user-sessions)
    sessions = [s.delete() for s in Session.objects.all() if s.get_decoded().get(
        '_auth_user_id') == user_sent]

    # find the group of channels that belong to that user
    channel_layer = get_channel_layer()
    group_name = 'group-%s' % user_sent.replace('@', '-')
    # send a logout command to the group
    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            'type': 'command_message',
            'message': 'logout'
        }

    )


@receiver(session_login)
def on_session_login(sender, **kwargs):
    """
    handle session login signal
    notify the specific web session that this user logged in
    (will force reload on the front end)
    """

    user_sent = sender
    session_id = kwargs.get('session_id')

    channel_layer = get_channel_layer()

    # group name for non logged-in session is group-[session_id]
    group_name = 'group-%s' % session_id

    # send a reload command to the group
    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            'type': 'command_message',
            'message': 'reload'
        }

    )


@receiver(session_register)
def on_session_register(sender, **kwargs):
    """
    handle session registration signal
    notify the specific web session that this user was succesfully registered
    (will force redirect to /login page on the front end)
    TODO: - maybe it's better to notify the user that they were registered succesfully
            and redirect them to the main page
    """

    user_sent = sender
    session_id = kwargs.get('session_id')
    # print("SESSION LOGIN signal for {0} with {1}".format(
    #     user_sent, session_id))
    channel_layer = get_channel_layer()
    # group name for non logged-in session is group-[session_id]
    group_name = 'group-%s' % session_id

    # send a redirect command to the group
    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            'type': 'command_message',
            'message': 'redirect',
            'url': '/login'
        }

    )


@receiver(session_received)
def on_session_received(sender, **kwargs):
    """
    handle session reveived signal
    notify the specific web session that a request
    was received out of band (i.e from the app)
    (front end will present a loading/processing message)
    """

    # print("session starting signal received")
    session_id = kwargs.get('session_id')
    # print("received a signal for {0}".format(session_id))
    channel_layer = get_channel_layer()

    # group name for non logged-in session is group-[session_id]
    group_name = 'group-%s' % session_id
    # print('in signal will try to send to the group', group_name)

    # send a loading command to the group
    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            'type': 'command_message',
            'message': 'loading',
            'url': '/login'
        }

    )
