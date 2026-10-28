from django.contrib.auth import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from .views import update_delete_category_api,get_customers_api,get_approved_history_api
from .views import get_user_loan_full_detail_api
from .views import get_combined_repayment_schedule
# from .views import pay_loan,repayment_schedule_detail
from .views import voluntary_savings_list,deposit_savings,withdraw_savings,get_categories
from . import views
from .views import update_profile, user_history_api
from .views import calculate_loan
from django.conf import settings
from django.conf.urls.static import static
from .views import get_documents_review_list_api
from .views import create_payment_request
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from django.urls import re_path
from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from .views import check_loan


def cors_serve(request, path, document_root=None, show_indexes=False):
    response = serve(request, path, document_root, show_indexes)
    response["Access-Control-Allow-Origin"] = "*"
    response["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    response["Access-Control-Allow-Headers"] = "ngrok-skip-browser-warning, Content-Type"
    return response

from .views import (
    register_user, 
    login_user, 
    verify_otp, 
    resend_otp,
    admin_login_api, 
    add_category_api, 
    admin_dashboard_data,
    # loan_categories_api,
    withdraw_voluntary_savings_api,
    deposit_voluntary_savings_api,
    open_savings_account_api,
    get_loan_categories_api,
    user_profile_api,
    loan_summary_report,
    process_loan_decision,
    loan_payment_and_schedule,
    home_summary_api,
    notification_list,
    notification_count,
    create_notification,
    
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v2/check-user-status/<str:user_id>/', views.check_user_loan_status, name='check_user_status'),
    # User API များ
    path("api/home-summary/",home_summary_api,name="home_summary",),
    path('api/check-loan/',views.check_loan,name='check_loan',),

    path('api/notifications/', notification_list,name='notification_list',),
    path('api/notification-count/', notification_count,name='notification_count',),
    path("api/create-notification/",create_notification,name="create_notification",),
    # path("api/payment-request/",create_payment_request,name="create_payment_request"),
    path("api/mark-notifications-read/",views.mark_notifications_read),
    path('api/register/', register_user, name='register'),
    path('api/login/', login_user, name='login'),
    path('api/verify-otp/', verify_otp, name='verify_otp'),
    path('api/resend-otp/', resend_otp, name='resend_otp'),
    path('api/admin-login/', admin_login_api, name='admin_login_api'),
    path('api/admin-dashboard-data/', admin_dashboard_data, name='admin_dashboard_data'),
    path('api/payment-request/', views.create_payment_request, name='create_payment_request'),
    # path('api/loan-categories/', loan_categories_api, name='loan_categories_api'),
    path('api/add-category/', add_category_api, name='add_category_api'),
    path('api/withdraw-savings/<int:saving_id>/', withdraw_voluntary_savings_api, name='withdraw_voluntary_savings_api'),
    path('api/deposit-savings/<int:saving_id>/', deposit_voluntary_savings_api, name='deposit_voluntary_savings_api'),
    path('api/open-savings/', open_savings_account_api, name='open_savings_account_api'),
    path('api/loan-categories/', get_loan_categories_api, name='get_loan_categories_api'),
    path('api/category/<int:cat_id>/', update_delete_category_api, name='update_delete_category_api'),
    path('api/customers/', get_customers_api, name='get_customers'),
    path('api/approved-history/',get_approved_history_api,name='get_approved_history'),
    # path('api/user-loan-detail/<int:user_id>/', get_user_loan_full_detail_api, name='get_approved_loan_full_detail'),
    path('api/user-loan-detail/<int:loan_id>/', get_user_loan_full_detail_api, name='get_approved_loan_full_detail'),
    path('api/repayment-schedule/', get_combined_repayment_schedule, name='repayment_schedule'),
    path('api/payment-request/create/', views.create_payment_request, name='create_payment_request'),
    path('api/admin/payment-requests/', views.admin_payment_requests, name='admin_payment_requests'),
    path('api/payment-request/reject/', views.reject_payment_request, name='reject_payment_request'),
    path('api/notification-count/', views.home_summary_api, name='notification-count'),

    path('api/pending-payment-requests/', views.pending_payment_requests_api, name='pending_payment_requests_api'),
    path('api/confirm-payment-request/<int:id>/', views.confirm_payment_request_api, name='confirm_payment_request_api'),
    path('api/reject-payment-request/<int:id>/', views.reject_payment_request_api, name='reject_payment_request_api'),

    # path('api/repayment-schedule-detail/<int:id>/', repayment_schedule_detail, name='repayment_schedule_detail'),
    # path('api/pay_loan/', pay_loan, name='pay_loan'),
    path('api/voluntary-savings/', voluntary_savings_list),
    path('api/deposit/', deposit_savings),
    path('api/withdraw/', withdraw_savings),
    path('api/loan_payment_and_schedule/', loan_payment_and_schedule),
    path('api/user_category/',get_categories, name='user_category'),
    path('api/v2/verify-kyc', views.submit_loan_form, name='verify_kyc'),
    path('api/v2/validate-nrc', views.validate_nrc_only, name='validate_nrc_only'),
    path('api/v2/validate-household', views.validate_household_only, name='validate_household_only'),
    path("api/calculate/", calculate_loan, name="calculate_loan"),
    path('api/update-profile/', update_profile, name='update_profile'),
    path('api/history/', user_history_api, name='user_history'),
    path('api/user-profile/', user_profile_api, name='user_profile'),
    path('api/documents-review-list/', get_documents_review_list_api, name='get_documents_review_list_api'),
    path('api/process-loan-decision/', process_loan_decision, name='process_loan_decision_api'),
    path('api/v2/validate-license-ocr', views.validate_business_license_only, name='validate_business_license'),
    path('api/v2/loan-details/<int:document_id>', views.get_loan_details, name='get_loan_details'),
    path('api/v2/verify-kyc', views.submit_loan_form, name='verify_kyc'),
    path('api/v2/validate-nrc', views.validate_nrc_only, name='validate_nrc_only'),
    path('api/v2/validate-household', views.validate_household_only, name='validate_household_only'),
    path('api/v2/loan-details/<int:document_id>', views.get_loan_details, name='get_loan_details'),
    path('api/calculate/', views.calculate_loan, name='calculate_loan'),
    path('api/v2/validate-license-ocr', views.validate_business_license_only, name='validate_business_license'),
    path('api/loan-summary-report/', loan_summary_report, name='loan-summary-report'),
    path("api/payment-history/",views.payment_history_api,name="payment_history_api",),
    re_path(r'^media/(?P<path>.*)$', cors_serve, {'document_root': settings.MEDIA_ROOT}),
    
 ]
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)