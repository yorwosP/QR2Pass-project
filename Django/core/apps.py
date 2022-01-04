from django.apps import AppConfig


class CoreConfig(AppConfig):
    name = 'core'


# connect signal receivers

    def ready(self):
        print("ready connect signal receivers")
        import core.signals
