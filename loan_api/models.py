from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings

# 1. USER TABLE (အကောင့်ဝင်ရန်နှင့် သာမန် User များအတွက် သီးသန့်)
class LoansUser(AbstractUser):
    full_name = models.CharField(max_length=150, blank=True, null=True)
    nrc_number = models.CharField(max_length=50, blank=True, null=True)
    phone_number = models.CharField(max_length=30, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    gender = models.CharField(max_length=10, choices=[('male', 'Male'), ('female', 'Female')], blank=True, null=True)
    photo = models.ImageField(upload_to='profiles/', blank=True, null=True)
    role = models.CharField(max_length=20, default='customer')
    date_of_birth = models.DateField(null=True , blank=True)
    is_verified = models.BooleanField(default=False)
    otp = models.CharField(max_length=6, null=True, blank=True)
    def save(self, *args, **kwargs):
        # 🚨 အကယ်၍ terminal ကနေ ဆောက်လိုက်တဲ့ superuser သို့မဟုတ် staff ဖြစ်ခဲ့ရင်
        # database ထဲမသိမ်းခင် role ကို 'admin' လို့ အလိုအလျောက် ပြောင်းခိုင်းတာဖြစ်ပါတယ်
        if self.is_superuser or self.is_staff:
            self.role = 'admin'
            
        super().save(*args, **kwargs)
    class Meta:
        managed = True  # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_user'

    def __str__(self):
        return self.full_name if self.full_name else self.username


# 2. CATEGORY TABLE (ချေးငွေအမျိုးအစားများနှင့် ဘဏ်ကယူမည့် အတိုးနှုန်း)
class LoansCategory(models.Model):
    category_id = models.AutoField(primary_key=True)
    category_type = models.CharField(max_length=100)
    category_name = models.CharField(max_length=150)
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2)
    image = models.ImageField(upload_to='category_images/', null=True, blank=True) # ဘဏ်က ယူမည့် အတိုးနှုန်းသက်သက်
    class Meta:
        managed = True  # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_category'
    def __str__(self):
        return self.category_name


# 3. DOCUMENT TABLE (ငွေချေးရန် တင်ရမည့် စာရွက်စာတမ်းများ)
class LoansDocument(models.Model):
    document_id = models.AutoField(primary_key=True)
    # user ကို null=True ထည့်ပေးခြင်းဖြင့် ယခင် Data အဟောင်းများနှင့် ပြဿနာမတက်စေပါ
    user = models.ForeignKey(LoansUser, on_delete=models.CASCADE, related_name='documents', null=True, blank=True)
    category = models.ForeignKey('LoansCategory', on_delete=models.CASCADE, related_name='documents') 
    amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    month = models.IntegerField(default=0)
    bank_account_phone = models.CharField(max_length=30, blank=True, null=True)
    nrc_photo_front = models.ImageField(upload_to='documents/nrc/', blank=True, null=True)
    nrc_photo_back = models.ImageField(upload_to='documents/nrc/', blank=True, null=True)
    occupation = models.CharField(max_length=150, blank=True, null=True)
    household_list_photo_front = models.ImageField(upload_to='documents/household/', blank=True, null=True)
    household_list_photo_back = models.ImageField(upload_to='documents/household/', blank=True, null=True)
    ownership_image = models.ImageField(upload_to='documents/ownership/', blank=True, null=True)
    business_license_photo_front = models.ImageField(upload_to='documents/business/', blank=True, null=True)
    business_license_photo_back = models.ImageField(upload_to='documents/business/', blank=True, null=True)
    income_average = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    face_scan_photo = models.ImageField(upload_to='documents/faces/', blank=True, null=True)
    
    class Meta:
        managed = True  # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_document'
    def __str__(self):
        return f"Docs for {self.user.full_name}"

    created_at = models.DateTimeField(
      auto_now_add=True
  )


# 4. HISTORY TABLE (ချေးငွေလျှောက်လွှာများနှင့် အာမခံကြေးမှတ်တမ်း)
class LoansHistory(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(LoansUser, on_delete=models.CASCADE, related_name='loan_histories')
    category = models.ForeignKey(LoansCategory, on_delete=models.SET_NULL, null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    amount_request = models.DecimalField(max_digits=12, decimal_places=2)
    month = models.IntegerField()
    document = models.ForeignKey(LoansDocument, on_delete=models.SET_NULL, null=True, blank=True)
    insurance_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)  # မူရင်းအတိုင်း အာမခံကြေး
    class Meta:
        managed = True  # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_history'
    def __str__(self):
        return f"Loan {self.id} - {self.user.full_name} ({self.status})"


class LoansRepaymentTransaction(models.Model):
    # 🚨 String 'LoansListTable' ဖြင့် ရေးပေးခြင်းဖြင့် Class ရေးသားသည့် Order ပြဿနာနှင့် NameError ကို ရှင်းပေးပါသည်
    loan = models.ForeignKey('LoansListTable', on_delete=models.CASCADE, related_name='transactions')
    amount_paid = models.DecimalField(
        max_digits=12, 
        decimal_places=2
    )  # ပြန်ဆပ်သည့် ပမာဏ
    mandatory_savings = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        default=0.00
    )  # မဖြစ်မနေ စုငွေ
    payment_date = models.DateField(
        auto_now_add=True
    )  # ငွေပေးချေသည့် ရက်စွဲ

    class Meta:
        managed = True
        db_table = 'loans_repayment_transaction'

    def __str__(self):
        return f"Transaction {self.id} for Loan {self.loan_id} - {self.amount_paid} MMK"
# 5. GUARANTOR TABLE (အာမခံသူများစာရင်း)
class LoansGuarantor(models.Model):
    guarantor_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(LoansUser, on_delete=models.CASCADE, related_name='guarantors')
    document = models.ForeignKey(LoansDocument, on_delete=models.CASCADE, related_name='guarantors')
    guarantor_name = models.CharField(max_length=150)
    guarantor_address = models.TextField(blank=True, null=True)
    guarantor_phone = models.CharField(max_length=30)
    nrc_front = models.ImageField(upload_to='guarantors/nrc/', blank=True, null=True)
    nrc_back = models.ImageField(upload_to='guarantors/nrc/', blank=True, null=True)
    class Meta:
        managed = True  # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_guarantor'
    def __str__(self):
        return self.guarantor_name

class LoansCompulsorySavings(models.Model):

    id = models.AutoField(primary_key=True)

    loan = models.OneToOneField(
        LoansHistory,
        on_delete=models.CASCADE,
        related_name="compulsory_saving"
    )

    user = models.ForeignKey(
        LoansUser,
        on_delete=models.CASCADE,
        related_name="compulsory_savings"
    )

    loan_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )

    saving_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=5.00
    )

    saving_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )


    STATUS_CHOICES = [
        ("holding", "Holding"),
        ("released", "Released"),
    ]

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="holding"
    )


    created_at = models.DateTimeField(
        auto_now_add=True
    )

    released_at = models.DateTimeField(
        null=True,
        blank=True
    )


    class Meta:
        db_table = "loans_compulsory_savings"


    def __str__(self):
        return f"{self.user.full_name} - {self.saving_amount}"
# 6. LIST TABLE (ပြန်ဆပ်ရမည့်ငွေနှင့် လစဉ်စုဆောင်းငွေဇယား)
class LoansListTable(models.Model):
    list_id = models.AutoField(primary_key=True)
    history = models.ForeignKey(LoansHistory, on_delete=models.CASCADE, related_name='repayments')
    amount = models.DecimalField(max_digits=12, decimal_places=2) # လစဉ်ဆပ်ရမည့် (အရင်း + အတိုး)
    monthly_savings = models.DecimalField(max_digits=12, decimal_places=2, default=0.00) # လစဉ်ထည့်ရမည့် စုဆောင်းငွေ
    date = models.DateField()
    next_payment_date = models.DateField(
    null=True,
    blank=True
    )
    remain_month = models.IntegerField(
        default=12
    )
    flag = models.BooleanField(default=False) # ငွေလာဆပ်ပြီး/မပြီး
    remain_amount = models.IntegerField(default=0)
    paid_date = models.DateField(null=True, blank=True) 
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        managed = True  # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_listtable'
    def __str__(self):
        return f"Repayment for Loan {self.history.id}"


# 7. NOTIFICATION TABLE (သတိပေးချက်များ)
class LoansNotification(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(LoansUser, on_delete=models.CASCADE, related_name='notifications')
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    sent_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        managed = True # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_notification'
    def __str__(self):
        return f"Noti to {self.user.username}"


# 8. RISK SCORE TABLE (AI အကူအညီ ခွဲခြမ်းစိတ်ဖြာမှု)
class LoansRiskScore(models.Model):
    id = models.AutoField(primary_key=True)
    application = models.ForeignKey(LoansHistory, on_delete=models.CASCADE, related_name='risk_scores')
    risk_level = models.CharField(max_length=50)
    score = models.IntegerField()
    factors = models.TextField(blank=True, null=True)
    recommendation = models.TextField(blank=True, null=True)
    generated_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        managed = True  # သို့မဟုတ် True (ဒေတာပြင်ချင်ရင် True ပေးပါ)
        db_table = 'loans_riskScore'
    def __str__(self):
        return f"Risk Score: {self.score} for Loan {self.application.id}"


# 9. 🐷 VOLUNTARY SAVINGS TABLE (ဆန္ဒအလျောက် စုငွေသက်သက် - ငွေချေးသူမဟုတ်သူများပါ ရပါသည်)
# 🎯 RiskScore ရဲ့ အပြင်ဘက် တန်းတူနေရာသို့ စနစ်တကျ ထုတ်ထားပါသည်
class LoansVoluntarySavings(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(LoansUser, on_delete=models.CASCADE, related_name='voluntary_savings')

    # max_index_digits အစား max_length ဟု အမှန်ပြင်ထားပါသည်
    account_number = models.CharField(max_length=30, unique=True, blank=True, null=True)
    total_savings = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        managed = True
        db_table = 'loans_voluntarysavings'
    def __str__(self):
        return f"{self.user.full_name if self.user.full_name else self.user.username} - {self.total_savings} MMK"


class PaymentRequest(models.Model):
    PAYMENT_METHOD_CHOICES = [
        ('kbz_pay', 'KBZ Pay'),
        ('wave_pay', 'Wave Pay'),
        ('aya_pay', 'AYA Pay'),
        ('cash', 'Cash'),
    ]

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    id = models.AutoField(primary_key=True)
    loan = models.ForeignKey(
        LoansListTable,
        on_delete=models.CASCADE,
        related_name='payment_requests'
    )
    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='payment_requests'
    )
    bank_account_or_phone = models.CharField(max_length=30, blank=True, null=True)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES)
    transaction_id = models.CharField(max_length=100, blank=True, null=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    transfer_date = models.DateField()
    payment_image = models.ImageField(upload_to='payment_requests/', blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    admin_remark = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    approved_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'loans_paymentrequest'

    def __str__(self):
        return f"PaymentRequest {self.id} - Loan {self.loan_id} ({self.status})"    