from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import LoansUser, LoansCategory, LoansDocument, LoansHistory, LoansGuarantor, LoansListTable, LoansNotification, LoansRiskScore, LoansVoluntarySavings,LoansRepaymentTransaction

from .models import PaymentRequest
# 1. User Admin Configuration
class CustomUserAdmin(UserAdmin):
    list_display = ['username', 'email', 'full_name', 'phone_number', 'photo']
    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('full_name', 'nrc_number', 'phone_number', 'address', 'gender', 'photo')}),
    )

admin.site.register(LoansUser, CustomUserAdmin)
admin.site.register(LoansVoluntarySavings)

# 2. အခြား မော်ဒယ်များကို Admin Panel တွင် မြင်ရအောင် Register ပြုလုပ်ခြင်း
@admin.register(LoansCategory)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['category_id', 'category_name', 'category_type', 'interest_rate']

@admin.register(LoansDocument)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ['document_id', 'user', 'occupation', 'income_average']

@admin.register(LoansHistory)
class HistoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'category', 'amount_request', 'month', 'status']
    list_filter = ['status', 'category']
    list_editable = ['status'] # Admin ကနေ Approved/Rejected တန်းပြောင်းနိုင်ရန်
@admin.register(LoansRepaymentTransaction)
class LoansRepaymentTransactionAdmin(admin.ModelAdmin):
  list_display = ('id', 'loan', 'amount_paid', 'mandatory_savings', 'payment_date')
  list_filter = ('payment_date',)
@admin.register(LoansGuarantor)
class GuarantorAdmin(admin.ModelAdmin):
    list_display = ['guarantor_id', 'user', 'guarantor_name', 'guarantor_phone']

@admin.register(LoansListTable)
class ListTableAdmin(admin.ModelAdmin):
    list_display = ['list_id', 'history', 'amount', 'date', 'flag', 'remain_amount']
    list_filter = ['flag']

@admin.register(LoansNotification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'message', 'is_read', 'sent_at']

@admin.register(LoansRiskScore)
class RiskScoreAdmin(admin.ModelAdmin):
    list_display = ['id', 'application', 'risk_level', 'score', 'generated_at']

@admin.register(PaymentRequest)
class PaymentRequestAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'loan',
        'amount',
        'payment_method',
        'status',
        'created_at',
    )

    list_filter = (
        'status',
    )

    search_fields = (
        'loan__id',
        'phone_number',
    )
