from celery.schedules import crontab


app.conf.beat_schedule = {


    "send-overdue-email-every-morning":

    {

        "task":
        "loans.tasks.check_overdue_payment",

        "schedule":
        crontab(
            hour=9,
            minute=0
        )

    }

}