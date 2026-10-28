from django.core.management.base import BaseCommand
from django.core.mail import send_mail


class Command(BaseCommand):

    help = "Send test email"

    def handle(self, *args, **kwargs):

        send_mail(
            subject="WONNAMI Test Email",

            message="""
                Hello,

                This is a test email from WONNAMI Loan System.

                Email sending is working successfully.

                Thank you.
                """,

            from_email="ayethuzartae@gmail.com",

            recipient_list=[
                "layy7520@gmail.com"
            ],

            fail_silently=False
        )


        self.stdout.write(
            self.style.SUCCESS(
                "Test email sent successfully"
            )
        )