import json
from channels.generic.websocket import WebsocketConsumer

# from .models import Client
from asgiref.sync import async_to_sync
from django.contrib.sessions.models import Session


class ConnectConsumer(WebsocketConsumer):

    def connect(self):
        """
        accept the websocket connection 
        and add all web sessions of the same
        user in the same channels group
        """

        # create a new group based on the session key of this session
        user = str(self.scope['user'])
        my_session = self.scope['session']
        nonce = self.scope['session']['nonce']

        self.group_name = 'group-%s' % my_session.session_key
        if user == 'AnonymousUser':
            print("DEBUG: this is an anonymous user")
            async_to_sync(self.channel_layer.group_add)(
                self.group_name, self.channel_name)
            self.accept()

        else:
            # if user is already logged in then move them to
            # the user group (all sessions of that user belong to that group)

            # discard the temporary group
            async_to_sync(self.channel_layer.group_discard)(
                self.group_name,
                self.channel_name
            )
            # !!!CHECK!!! ensure  unique group names (maybe add a field in the model and do the checks there)
            # group name now based on the userid (common for all the sessions of the user)
            group_name = 'group-%s' % user.replace('@', '-')
            self.group_name = group_name
            async_to_sync(self.channel_layer.group_add)(
                self.group_name, self.channel_name)
            self.accept()

    def disconnect(self, close_code):
        """
        remove the channel from the DB
        and remove this channel from the group
        """

        print("disconnected session with code", close_code)

        # Client.objects.filter(channel_name=self.channel_name).delete()
        async_to_sync(self.channel_layer.group_discard)(
            self.group_name,
            self.channel_name
        )

    def receive(self, text_data):
        """
        messages from the client - not used currently
        """
        text_data_json = json.loads(text_data)
        message = text_data_json['message']

    def chat_message(self, event):
        """
        send messages to the websocket
        """
        self.send(text_data=event["text"])

    def command_message(self, event):
        """
        send commands to the websocket
        """

        command = event['message']

        # Send message to WebSocket
        self.send(text_data=json.dumps({
            'command': command
        }))
