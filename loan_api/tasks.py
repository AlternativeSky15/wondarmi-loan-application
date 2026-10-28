from celery import shared_task
from django.core.mail import send_mail
from datetime import date

from .models import RepaymentSchedule


@shared_task
def check_overdue_payment():


    today = date.today()


    payments = RepaymentSchedule.objects.filter(
        due_date__lt=today,
        status="pending"
    )


    for payment in payments:


        customer = payment.loan.customer


        send_mail(

            subject="ချေးငွေဆပ်ရန်ကျန်ရှိကြောင်း အသိပေးခြင်း",

            message=f"""
                မင်္ဂလာပါ {customer.name}

                သင်၏ချေးငွေကို သတ်မှတ်ရက်တွင် 
                မဆပ်ရသေးပါ။

                ကျန်ရှိငွေ :
                {payment.amount} MMK

                ကျေးဇူးပြု၍ အမြန်ဆုံး လာရောက်ပေးချေပါရန်
                အသိပေးအပ်ပါသည်။
                """,

            from_email="ayethuzartae@gmail.com",

            recipient_list=[
                customer.email
            ]

        )


        payment.status="overdue"
        payment.save()