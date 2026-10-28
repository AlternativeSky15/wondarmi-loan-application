from django.core.management.base import BaseCommand
from django.core.mail import send_mail
from django.utils import timezone

from loan_api.models import LoansListTable


class Command(BaseCommand):

    def handle(self,*args,**kwargs):

        today = timezone.now().date()


        loans = LoansListTable.objects.filter(
            next_payment_date__lt=today,
            remain_amount__gt=0
        )


        for loan in loans:


            if loan.history and loan.history.user:

                email = loan.history.user.email


                if email:


                    send_mail(

                    subject=
                    "WONNAMI Loan Payment Reminder",


                    message=f"""

                    မင်္ဂလာပါ

                    သင်၏ ချေးငွေမှာ ဆပ်ရန်ကျန်ရှိနေပါသည်။

                    ကျန်ငွေ:
                    {loan.remain_amount} MMK


                    ကျေးဇူးပြု၍ အမြန်ဆုံး လာရောက်ပေးချေပါရန်။

                    WONNAMI Microfinance

                    """,

                    from_email=
                    "ayethuzartae@gmail.com",


                    recipient_list=[
                        email
                    ]

                    )


        self.stdout.write(
            "Overdue email sent successfully"
        )