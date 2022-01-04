"""
ASGI config for QR2Pass project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/howto/deployment/asgi/
"""


# import os
# import django
# from channels.routing import get_default_application
# os.environ.setdefault("DJANGO_SETTINGS_MODULE", "qr2pass.settings")
# django.setup()
# application = get_default_application()

import os


from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack


from channels.layers import get_channel_layer

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'qr2pass.settings')
#need to instatiate before importing models (which is done in core.routing)
#from channels documentation:
# Initialize Django ASGI application early to ensure the AppRegistry
# is populated before importing code that may import ORM models.
django_asgi_app = get_asgi_application()

import core.routing

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(
            core.routing.websocket_urlpatterns
        )
    ),

})

# import os
# import django
# from channels.layers import get_channel_layer
# from channels.routing import get_default_application

# os.environ.setdefault("DJANGO_SETTINGS_MODULE", "qr2pass.settings")
# django.setup()
# application = get_default_application()
# print("application:", application)
# channel_layer = get_channel_layer()
