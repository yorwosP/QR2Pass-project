from django.core.management.base import BaseCommand, CommandError
from api.models import MyUser


class Command(BaseCommand):
    help = 'Deletes users from DB'

    def add_arguments(self, parser):
        parser.add_argument('user_emails', nargs='*')
        parser.add_argument(
            '-a', '--all',
            action='store_true',
            help='Delete all users',
        )

    def handle(self, *args, **options):

        if options['all']:
            for user in MyUser.objects.all():
                print("will delete user:", user.email)
                user.delete()
        else:

            for user_email in options['user_emails']:
                try:
                    user = MyUser.objects.get(pk=user_email)
                    user.delete()
                    self.stdout.write(self.style.SUCCESS(
                        'Successfully deleted user "%s"' % user_email))

                except MyUser.DoesNotExist:
                    raise CommandError('User "%s" does not exist' % user_email)
