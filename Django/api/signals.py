"""
custom signals
are used to notify the core app when user starts (session_received) or session
or finishes a register or login procedure via the api app
"""

from django.dispatch import Signal


session_login = Signal(providing_args=['session_id'])
session_register = Signal(providing_args=['session_id'])
session_received = Signal(providing_args=['session_id'])
session_cancelled = Signal(providing_args=['session_id'])
