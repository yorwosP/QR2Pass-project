from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack


from django.urls import re_path
from .consumers import ConnectConsumer

# application = ProtocolTypeRouter({
#     # "http": get_asgi_application(),
#     "websocket": AuthMiddlewareStack(
#         URLRouter(
#             core.routing.websocket_urlpatterns
#         )
#     ),

# })


websocket_urlpatterns = [
    re_path(r'ws/', ConnectConsumer.as_asgi()),
]
