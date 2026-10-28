import os
from datetime import datetime
from django.apps import AppConfig
from django.core.mail import send_mail
from apscheduler.schedulers.background import BackgroundScheduler

class LoanApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'loan_api'

    def ready(self):
        # Development Server (runserver) နှစ်ခါ ရန်းခြင်းမှ ကာကွယ်ရန်
        if os.environ.get('RUN_MAIN') != 'true':
            return

        from django.apps import apps

        def check_and_send_overdue_emails():
            today = datetime.now().date()
            print(f"⏰ Auto Mail Check Started for Date: {today}")

            # 💡 LoansListTable Model ကို လှမ်းယူခြင်း
            LoansListTable = apps.get_model('loan_api', 'LoansListTable')
            
            # ရက်လွန်နေပြီး (date < today) ငွေမဆပ်ရသေးသော (flag=False) စာရင်းများကို ရှာခြင်း
            # ForeignKey တွေ တစ်ဆင့်ပြီးတစ်ဆင့် ချိတ်ထားသည့်အတွက် select_related သုံးထားပါသည်
            overdue_schedules = LoansListTable.objects.filter(
                date__lt=today,
                flag=False
            ).select_related('history__user')

            for item in overdue_schedules:
                # Relationship အတိုင်း User နဲ့ Amount ယူခြင်း
                # (history -> user အတိုင်း ချိတ်ဆက်ထားသည်ဟု ယူဆပါသည်)
                user = item.history.user
                username = getattr(user, 'username', 'အသုံးပြသူ')
                user_email = getattr(user, 'email', None)
                
                # ပြန်ဆပ်ရမည့် ပမာဏ (amount)
                amount = item.amount 
                due_date_str = item.date.strftime('%Y-%m-%d')

                subject = "⚠️ ချေးငွေပြန်ဆပ်ရန် ရက်လွန်နေကြောင်း အကြောင်းကြားစာ"
                
                # 📌 အသေသတ်မှတ်ထားသော Noti Warning စာ (Template)
                message = f"""မင်္ဂလာပါ {username}၊

                    လူကြီးမင်း၏ ချေးငွေပြန်ဆပ်ရမည့်ရက် ({due_date_str}) ကျော်လွန်သွားပြီဖြစ်ပါသဖြင့် ပြန်ဆပ်ရန်ကျန်ရှိသော ငွေပမာဏ {amount:,.2f} MMK ကို အမြန်ဆုံး ပေးသွင်းပေးပါရန် အသိပေးအကြောင်းကြားအပ်ပါသည်။

                    ကျေးဇူးတင်ပါသည်။"""

                try:
                    if user_email:
                        send_mail(
                            subject=subject,
                            message=message,
                            from_email=None,  # settings.py ထဲက DEFAULT_FROM_EMAIL ကို သုံးပါမည်
                            recipient_list=[user_email],
                            fail_silently=False,
                        )
                        print(f"✅ Email sent to {username} ({user_email}) for amount: {amount}")
                    else:
                        print(f"⚠️ User {username} does not have an email address.")
                except Exception as e:
                    print(f"❌ Failed to send email to {username}: {e}")

        # APScheduler စတင်ခြင်း
        scheduler = BackgroundScheduler()
        
        # 💡 နေ့စဉ် မနက် ၉:၀၀ နာရီတိုင်း Auto စစ်ပြီး Mail ပို့မည်
        scheduler.add_job(check_and_send_overdue_emails, 'cron', hour=9, minute=0)
        
        # 🧪 စမ်းသပ်လိုပါက အထက်ပါ cron လိုင်းကို ပိတ်ပြီး အောက်ပါ line ကို ဖွင့်စမ်းနိုင်ပါသည် (၁၀ စက္ကန့်တိုင်း run မည်)
        # scheduler.add_job(check_and_send_overdue_emails, 'interval', seconds=10)
        
        scheduler.start()