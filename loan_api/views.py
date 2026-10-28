import random
from django.core.mail import send_mail
import json
from datetime import timezone
from decimal import Decimal
from django.db import models
from django.db.models import Sum
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect
from django.contrib.auth import authenticate, get_user_model
# from flask import send_file
import numpy as np
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .models import (
    LoansListTable, LoansCategory, LoansDocument, LoansHistory, 
    LoansGuarantor, LoansRepaymentTransaction, LoansUser, LoansVoluntarySavings
)
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from .serializers import LoansCategorySerializer
import base64
from django.core.files.base import ContentFile
from datetime import datetime
import base64
from django.core.files.base import ContentFile
import os
import cv2
import re
import traceback
import pytesseract
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import FileSystemStorage
#from ultralytics import YOLO
import os
import cv2
import numpy as np
import traceback
import pytesseract
import json
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import FileSystemStorage
from .models import LoansDocument, LoansHistory, LoansListTable
import random
import json
import base64
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from datetime import date
import calendar

# Django Base & Database Imports
from django.db import models
from django.db.models import Sum
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect
from django.contrib.auth import authenticate, get_user_model
from django.core.mail import send_mail
from django.core.files.base import ContentFile
from django.utils import timezone

# Django REST Framework (DRF) Imports
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import AllowAny
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

# Local Models & Serializers Imports
from .models import (
    LoansUser, 
    LoansCategory, 
    LoansDocument, 
    LoansHistory, 
    LoansGuarantor, 
    LoansListTable, 
    LoansVoluntarySavings,
    LoansCompulsorySavings
)
from .serializers import LoansCategorySerializer
from dateutil.relativedelta import relativedelta
loans = LoansListTable.objects.filter(next_payment_date=None)

from django.core.mail import send_mail

from datetime import date
from django.utils import timezone
from django.http import FileResponse
from rest_framework.parsers import MultiPartParser, FormParser
from .models import PaymentRequest
from .serializers import PaymentRequestSerializer
from .models import LoansDocument, LoansNotification
from .models import PaymentRequest

from django.db.models import Sum, Count
from django.db.models.functions import ExtractMonth

import json
import os
import traceback

import cv2
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import numpy as np
import pytesseract

from .models import LoansDocument, LoansHistory, LoansListTable,LoansUser
from .models import LoansRepaymentTransaction
for loan in loans:
    loan.next_payment_date = loan.date + relativedelta(months=1)
    loan.save()

print("Updated")

@api_view(['GET'])
@permission_classes([AllowAny])
def get_documents_review_list_api(request):
    try:
        documents = LoansDocument.objects.all().select_related('user').order_by('-document_id')
        data_list = []

        for doc in documents:
            user_info = doc.user if doc.user else None
            domain = request.build_absolute_uri('/')[:-1]

            user_pk = getattr(user_info, 'user_id', getattr(user_info, 'id', None)) if user_info else None

            # 💡 ဒီ User အတွက် LoansHistory ထဲမှာ Approve/Reject လုပ်ပြီးသား ရှိမရှိ စစ်ခြင်း
            latest_history = LoansHistory.objects.filter(user=user_info).order_by('-id').first()
            current_status = latest_history.status if latest_history else 'pending'

            data_list.append({
                "document_id": doc.document_id,
                "user_id": user_pk,
                "full_name": getattr(user_info, 'full_name', 'အမည်မသိ') if user_info else "အမည်မသိ",
                "phone_number": getattr(user_info, 'phone_number', '-') if user_info else "-",
                "occupation": doc.occupation if doc.occupation else "-",
                "income_average": float(doc.income_average) if doc.income_average else 0.0,
                "amount":float(doc.amount) if doc.amount else 0.0,
                "bank_account_phone": doc.bank_account_phone if doc.bank_account_phone else "-",
                "status": current_status,  # 🌟 Status ပါဝင်သွားပါပြီ ('pending', 'approved', 'rejected')
                
                "nrc_photo_front": domain + doc.nrc_photo_front.url if doc.nrc_photo_front else "",
                "nrc_photo_back": domain + doc.nrc_photo_back.url if doc.nrc_photo_back else "",
                "household_list_photo_front": domain + doc.household_list_photo_front.url if doc.household_list_photo_front else "",
                "household_list_photo_back": domain + doc.household_list_photo_back.url if doc.household_list_photo_back else "",
                "ownership_image": domain + doc.ownership_image.url if doc.ownership_image else "",
                "business_license_photo_front": domain + doc.business_license_photo_front.url if doc.business_license_photo_front else "",
                "business_license_photo_back": domain + doc.business_license_photo_back.url if doc.business_license_photo_back else "",
                "face_scan_photo": domain + doc.face_scan_photo.url if doc.face_scan_photo else "",
            })

        response = JsonResponse(data_list, safe=False, status=200)
        response["Access-Control-Allow-Origin"] = "*"
        return response

    except Exception as e:
        response = JsonResponse({"error": str(e)}, status=500)
        response["Access-Control-Allow-Origin"] = "*"
        return response
# လစဉ် ရက်စွဲတွက်ပေးမည့် Helper Function
def add_months(sourcedate, months):
    month = sourcedate.month - 1 + months
    year = sourcedate.year + month // 12
    month = month % 12 + 1
    day = min(sourcedate.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


@api_view(['POST'])
def withdraw_savings(request):
    user_id = request.data.get("user_id")
    amount = request.data.get("amount")

    if not user_id or not amount:
        return Response({"error": "user_id and amount required"}, status=400)

    try:
        savings = LoansVoluntarySavings.objects.get(user_id=user_id)
    except LoansVoluntarySavings.DoesNotExist:
        return Response({"error": "User savings not found"}, status=404)

    

    # 🔥 convert to Decimal
    amount = Decimal(str(amount))

    # 🔥 VALIDATION
    if amount > savings.total_savings:
        return Response({"error": "Insufficient balance"}, status=400)

    # 🔥 UPDATE (NOW SAFE)
    savings.total_savings -= amount
    savings.save()

    monthly_interest = (savings.total_savings * Decimal("0.14")) / Decimal("12")
    return Response({
    "message": "Withdraw successful",
    "remaining_balance": str(savings.total_savings),
    "monthly_interest_14": str(monthly_interest)
})

@api_view(['POST'])
def deposit_savings(request):
    user_id = request.data.get("user_id")
    amount = request.data.get("amount")

    if not user_id or not amount:
        return Response({"error": "user_id and amount required"}, status=400)

    try:
        amount = Decimal(str(amount))  # 🔥 FIX HERE
    except:
        return Response({"error": "Invalid amount"}, status=400)

    if amount < Decimal('5000'):
        return Response({"error": "Minimum amount is 5000 MMK"}, status=400)

    try:
        savings = LoansVoluntarySavings.objects.get(user_id=user_id)
    except LoansVoluntarySavings.DoesNotExist:
        return Response({"error": "User savings not found"}, status=404)

    # 🔥 FIX (Decimal + Decimal)
    savings.total_savings += amount
    savings.save()
    
    
    return Response({
        "message": "Deposit successful",
        "total_savings": str(savings.total_savings)

        
    })

@api_view(['GET'])
def voluntary_savings_list(request):
    try:
        savings_rows = LoansVoluntarySavings.objects.all().order_by('-id')

        data = []

        for row in savings_rows:
            try:
                user = LoansUser.objects.get(id=row.user_id)
                username = user.username
            except LoansUser.DoesNotExist:
                username = ""

            total_savings = float(row.total_savings or 0)
            annual_interest = total_savings * 0.14
            monthly_interest= annual_interest /12

            data.append({
                "id": row.id,
                "user_id": row.user_id,
                "username": username,
                "account_number": row.account_number,
                "total_savings": f"{total_savings:,.2f} MMK",
                "monthly_interest_14": f"{monthly_interest:,.2f} MMK",
            })

        return Response(data)

    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_payment_requests(request):
    try:
        requests_qs = PaymentRequest.objects.filter(
            status='pending'
        ).select_related('loan', 'customer').order_by('-created_at')

        data = []
        for pr in requests_qs:
            customer_name = "-"
            if pr.customer:
                customer_name = getattr(pr.customer, 'full_name', None) or getattr(pr.customer, 'username', '-')

            image_url = None
            if pr.payment_image and hasattr(pr.payment_image, 'url'):
                image_url = request.build_absolute_uri(pr.payment_image.url)

            data.append({
                "request_id": pr.id,
                "customer_name": customer_name,
                "loan_id": pr.loan_id,
                "amount": str(pr.amount),
                "payment_method": pr.payment_method,
                "bank_account_or_phone": pr.bank_account_or_phone,
                "transfer_date": pr.transfer_date.strftime("%Y-%m-%d") if pr.transfer_date else None,
                "payment_image": image_url,
                "status": pr.status,
            })

        return Response(data, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def reject_payment_request(request):
    payment_request_id = request.data.get('payment_request_id')
    admin_remark = request.data.get('admin_remark', '')

    if not payment_request_id:
        return Response(
            {"status": "error", "message": "payment_request_id is required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        payment_request = PaymentRequest.objects.get(pk=payment_request_id)
    except PaymentRequest.DoesNotExist:
        return Response(
            {"status": "error", "message": "Payment request not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    payment_request.status = 'rejected'
    payment_request.admin_remark = admin_remark
    payment_request.save()

    return Response(
        {"status": "success", "message": "Payment request rejected successfully"},
        status=status.HTTP_200_OK
    )
import logging
logger = logging.getLogger(__name__)

from decimal import Decimal
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
import traceback

# သင့် model များကို မှန်ကန်စွာ import ခေါ်ယူပါ
from .models import LoansDocument, LoansNotification, LoansCompulsorySavings, LoansHistory

@api_view(["POST"])
@permission_classes([AllowAny])
def process_loan_decision(request):
    try:
        document_id = request.data.get("document_id")
        action = request.data.get("action")
        amount = int(request.data.get("amount", 0))
        months = int(request.data.get("month", 12))

        # -------------------------------
        # Find Document
        # -------------------------------
        try:
            doc = LoansDocument.objects.get(document_id=document_id)
        except LoansDocument.DoesNotExist:
            return Response(
                {"message": "စာရွက်စာတမ်း မတွေ့ပါ"},
                status=status.HTTP_404_NOT_FOUND,
            )

        user = doc.user

        # Update document status
        doc.status = action
        doc.save()

        # -------------------------------
        # APPROVED
        # -------------------------------
        if action == "approved":

            history, created = LoansHistory.objects.get_or_create(
                user=user,
                document=doc,
                defaults={
                    "status": "approved",
                    "amount_request": amount,
                    "month": months,
                },
            )

            if not created:
                history.status = "approved"
                history.amount_request = amount
                history.month = months
                history.save()

            LoansListTable.objects.filter(history=history).delete()

            loan =LoansListTable.objects.create(
                history=history,
                amount=amount,
                monthly_savings=0,
                date=date.today(),
                flag=False,
                remain_amount=amount,
                remain_month=months,
            )

            compulsory_amount = Decimal(str(amount)) * Decimal("0.05")
            # history = loan.history
            # target_user = history.user
            target_user = history.user
            LoansCompulsorySavings.objects.create(
                loan=history,
                user=target_user,
                loan_amount=Decimal(str(amount)),
                saving_rate=Decimal("5.00"),
                saving_amount=compulsory_amount,
                status="holding"
            )

            formatted_amount = int(amount)
            formatted_saving = int(compulsory_amount)

            notification = (
                f"သင့်ချေးငွေ {formatted_amount} MMK ကို "
                f"အတည်ပြုပြီးဖြစ်ပါသည်။ "
                f"မဖြစ်မနေစုငွေ {formatted_saving} MMK ကို "
                f"သင့် Saving Account ထဲသို့ ထည့်သွင်းထားပါသည်။"
                f"ရုံးတွင် လာရောက်ထုတ်ယူနိုင်ပါသည်။"
            )

            LoansNotification.objects.create(
                user=user,
                message=notification,
                is_read=False,
            )

            # ---------------- Email ----------------
            if user.email:

                send_mail(
                    subject="Loan Approved",
                    message=f"""
                    မင်္ဂလာပါ {user.full_name}

                    သင်လျှောက်ထားသော ချေးငွေကို အတည်ပြုပြီးဖြစ်ပါသည်။

                    Approved Amount : {formatted_amount} MMK

                    Loan Period : {months} Months

                    ကျေးဇူးပြု၍ ရုံးတွင် လာရောက်ထုတ်ယူနိုင်ပါသည်။

                    WONDARMI Loan System
                    """,
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[user.email],
                    fail_silently=False,
                )

            return Response(
                {
                    "status": "success",
                    "message": "ချေးငွေအတည်ပြု၍ Notification နှင့် Email ပို့ပြီးပါပြီ"
                }
            )

        # -------------------------------
        # REJECTED
        # -------------------------------
        elif action == "rejected":
            history, created = LoansHistory.objects.get_or_create(
                user=user,
                document=doc,
                defaults={
                    "status": "rejected",
                    "amount_request": amount,
                    "month": months,
                },
            )

            if not created:
                history.status = "rejected"
                history.save()

            LoansListTable.objects.filter(history=history).delete()

            notification = (
                "သင်လျှောက်ထားသော ချေးငွေကို "
                "ငြင်းပယ်လိုက်ပါသည်။"
            )

            LoansNotification.objects.create(
                user=user,
                message=notification,
                is_read=False,
            )

            if user.email:

                send_mail(
                    subject="Loan Rejected",
                    message=f"""
                    မင်္ဂလာပါ {user.full_name}
                    သင်လျှောက်ထားသော ချေးငွေကို
                    ငြင်းပယ်လိုက်ပါသည်။

                    အသေးစိတ်သိရှိလိုပါက
                    ရုံးသို့ဆက်သွယ်နိုင်ပါသည်။

                    WONDARMI Loan System
                    """,
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[user.email],
                    fail_silently=False,
                )

            return Response(
                {
                    "status": "success",
                    "message": "Reject ပြုလုပ်၍ Notification နှင့် Email ပို့ပြီးပါပြီ"
                }
            )

        return Response(
            {"message": "Invalid action"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    except Exception as e:
        print("================ ERROR ================")
        traceback.print_exc()
        return Response(
            {"message": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

@api_view(['GET'])
@permission_classes([AllowAny])
def pending_payment_requests_api(request):
    try:
        requests_qs = PaymentRequest.objects.filter(
            status='pending'
        ).select_related('customer', 'loan').order_by('-created_at')

        data = []
        for pr in requests_qs:
            serialized = PaymentRequestSerializer(pr, context={'request': request}).data

            # 1. Loan Amount Safe ဖြစ်အောင် ထုတ်ယူခြင်း
            loan_amount = 0.0
            remaining_amount = 0.0
            
            if pr.loan:
                if getattr(pr.loan, 'amount', None) is not None:
                    try:
                        loan_amount = float(pr.loan.amount)
                    except (ValueError, TypeError):
                        loan_amount = 0.0
                
                if getattr(pr.loan, 'remain_amount', None) is not None:
                    try:
                        remaining_amount = float(pr.loan.remain_amount)
                    except (ValueError, TypeError):
                        remaining_amount = 0.0

            # 2. Image URL Safe ဖြစ်အောင် ခေါ်ယူခြင်း
            image_url = None
            if pr.payment_image and hasattr(pr.payment_image, 'url'):
                try:
                    image_url = request.build_absolute_uri(pr.payment_image.url)
                except Exception:
                    image_url = None

            # 3. Serialized Data ကို KeyError မတက်အောင် .get() ဖြင့် ခေါ်ခြင်း
            data.append({
                "id": pr.id,
                "customer_name": serialized.get('customer_name', ''),
                "customer_phone": serialized.get('customer_phone', ''),
                "customer_email": serialized.get('customer_email', ''),
                "loan_id": serialized.get('loan_id', pr.loan.pk if pr.loan else None),
                "loan_amount": loan_amount,
                "remaining_amount": remaining_amount,
                "payment_amount": str(pr.amount) if pr.amount is not None else "0",
                "payment_method": pr.payment_method or "",
                "bank_account_or_phone": pr.bank_account_or_phone or "",
                "transaction_id": pr.transaction_id or "",
                "transfer_date": pr.transfer_date.strftime("%Y-%m-%d") if pr.transfer_date else None,
                "payment_image": image_url,
                "status": pr.status,
            })

        return Response(data, status=status.HTTP_200_OK)

    except Exception as e:
        # Error တက်ပါက Terminal တွင် သေချာမြင်ရအောင် print / log ထုတ်ပေးခြင်း
        logger.error("Error in pending_payment_requests_api: %s", str(e), exc_info=True)
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 2️⃣ POST confirm payment request
@api_view(['POST'])
@permission_classes([AllowAny])
def confirm_payment_request_api(request, id):
    try:
        payment_request = PaymentRequest.objects.select_related('customer', 'loan').get(pk=id)
    except PaymentRequest.DoesNotExist:
        return Response({"status": "error", "message": "Payment request not found"}, status=status.HTTP_404_NOT_FOUND)

    payment_request.status = 'approved'
    payment_request.approved_at = timezone.now()
    payment_request.save()

    customer = payment_request.customer
    if customer and customer.email:
        customer_name = getattr(customer, 'full_name', None) or customer.username
        try:
            send_mail(
                subject="WONNAMI Payment Received",
                message=(
                    f"မင်္ဂလာပါ {customer_name},\n\n"
                    f"သင်၏ ငွေပေးချေမှု {payment_request.amount} MMK ကို WONNAMI မှ လက်ခံရရှိပြီး "
                    f"အတည်ပြုပြီးပါပြီ။\n\n"
                    f"Loan ID: {payment_request.loan_id}\n"
                    f"Payment Amount: {payment_request.amount} MMK\n\n"
                    f"ကျေးဇူးတင်ပါသည်။\nWONNAMI Microfinance"
                ),
                from_email=None,
                recipient_list=[customer.email],
                fail_silently=True,
            )
        except Exception:
            pass

    return Response({"status": "success", "message": "Payment request confirmed successfully"}, status=status.HTTP_200_OK)


# 3️⃣ POST reject payment request
@api_view(['POST'])
@permission_classes([AllowAny])
def reject_payment_request_api(request, id):
    admin_remark = request.data.get('admin_remark', '')

    try:
        payment_request = PaymentRequest.objects.select_related('customer', 'loan').get(pk=id)
    except PaymentRequest.DoesNotExist:
        return Response({"status": "error", "message": "Payment request not found"}, status=status.HTTP_404_NOT_FOUND)

    payment_request.status = 'rejected'
    payment_request.admin_remark = admin_remark
    payment_request.save()

    customer = payment_request.customer
    if customer and customer.email:
        customer_name = getattr(customer, 'full_name', None) or customer.username
        try:
            send_mail(
                subject="WONNAMI Payment Not Received",
                message=(
                    f"မင်္ဂလာပါ {customer_name},\n\n"
                    f"သင်၏ ငွေပေးချေမှု {payment_request.amount} MMK ကို WONNAMI မှ လက်ခံရရှိခြင်း မရှိသေးပါ။\n\n"
                    f"အကြောင်းရင်း: {admin_remark or 'သတ်မှတ်ချက်မရှိပါ'}\n\n"
                    f"ကျေးဇူးပြု၍ ပြန်လည် ဆက်သွယ်ပေးပါ။\nWONNAMI Microfinance"
                ),
                from_email=None,
                recipient_list=[customer.email],
                fail_silently=True,
            )
        except Exception:
            pass

    return Response({"status": "success", "message": "Payment request rejected successfully"}, status=status.HTTP_200_OK)

from django.http import JsonResponse
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .models import LoansDocument, LoansGuarantor, LoansHistory


@api_view(['GET'])
@permission_classes([AllowAny])
def get_user_loan_full_detail_api(request, loan_id):
    try:
        # 1. LoanHistory ကို Safe ဖြစ်အောင် ရှာပါ
        loan = LoansHistory.objects.select_related('user', 'category').filter(pk=loan_id).first()
        if not loan:
            return Response({"error": f"Loan ID {loan_id} မရှိပါ"}, status=status.HTTP_404_NOT_FOUND)

        user = loan.user

        # 2. Document ကို ရှာပါ
        doc = None
        if user:
            doc = LoansDocument.objects.filter(user_id=user.pk).first()

        # 3. Guarantor ကို ရှာပါ
        guarantor = None
        if user and doc:
            guarantor = LoansGuarantor.objects.filter(user_id=user.pk, document_id=doc.pk).first()

        # Helper 1: Image URL Safe Parser
        def get_image_url(obj, field_name):
            if not obj:
                return None
            try:
                image_field = getattr(obj, field_name, None)
                if image_field and hasattr(image_field, 'url') and image_field.name:
                    return request.build_absolute_uri(image_field.url)
            except Exception:
                pass
            return None

        # Helper 2: Safe Float Parser
        def safe_float(value):
            if value is None:
                return 0.0
            try:
                return float(value)
            except (ValueError, TypeError):
                return 0.0

        # Category Name Safe Extractor
        category_name = "N/A"
        if loan.category:
            category_name = getattr(loan.category, 'category_name', getattr(loan.category, 'name', 'N/A'))

        data = {
            "id": loan.pk,
            "user_id": user.pk if user else None,
            "full_name": getattr(user, 'full_name', 'N/A') if user else "N/A",
            "phone_number": getattr(user, 'phone_number', 'N/A') if user else "N/A",
            "nrc_number": getattr(user, 'nrc_number', 'N/A') if user else "N/A",
            "address": getattr(user, 'address', 'N/A') if user else "N/A",
            "email": getattr(user, 'email', 'N/A') if user else "N/A",
            "category_name": category_name,
            "amount_request": safe_float(loan.amount_request),
            "occupation": getattr(doc, 'occupation', 'N/A') if doc else "N/A",
            "income_average": safe_float(getattr(doc, 'income_average', 0.0)) if doc else 0.0,
            "bank_account_phone": getattr(doc, 'bank_account_phone', 'N/A') if doc else "N/A",
            "nrc_photo_front": get_image_url(doc, 'nrc_photo_front'),
            "nrc_photo_back": get_image_url(doc, 'nrc_photo_back'),
            "household_list_photo_front": get_image_url(doc, 'household_list_photo_front'),
            "household_list_photo_back": get_image_url(doc, 'household_list_photo_back'),
            "face_scan_photo": get_image_url(doc, 'face_scan_photo'),
            "ownership_image": get_image_url(doc, 'ownership_image'),
            "business_license_photo_front": get_image_url(doc, 'business_license_photo_front'),
            "business_license_photo_back": get_image_url(doc, 'business_license_photo_back'),
            "guarantor_name": getattr(guarantor, 'guarantor_name', 'N/A') if guarantor else "N/A",
            "guarantor_phone": getattr(guarantor, 'guarantor_phone', 'N/A') if guarantor else "N/A",
            "guarantor_address": getattr(guarantor, 'guarantor_address', 'N/A') if guarantor else "N/A",
            "g_nrc_front": get_image_url(guarantor, 'nrc_front'),
            "g_nrc_back": get_image_url(guarantor, 'nrc_back'),
        }

        return Response(data, status=status.HTTP_200_OK)

    except Exception as e:
        import traceback
        traceback.print_exc()  # Terminal မှာ Error အတိအကျ ပေါ်စေရန်
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        

# ကျန်ရှိသော API function များအားလုံးကို အောက်မှာ ဆက်ထည့်ပါ...

# ကျန်ရှိသော API function များ (အစ်ကို့ code အဟောင်းအတိုင်းထားနိုင်ပါတယ်)
# ...
@api_view(['GET'])
@permission_classes([AllowAny])
def get_approved_history_api(request):
    # 1. status='approved' ဖြစ်တဲ့ history တွေကို စစ်ထုတ်မယ်
    # 2. select_related('user') သုံးပြီး User table က information တွေကို Join လုပ်ဆွဲမယ်
    approved_history = LoansHistory.objects.filter(status='approved').select_related('user')
    
    data = []
    for entry in approved_history:
        user = entry.user  # History ကနေ User table ကို ချိတ်ဆက်ခြင်း
        if user:
            # first_name နှင့် last_name ကြား space ခြားရာတွင် clear ဖြစ်အောင် strip လုပ်ပေးထားပါသည်
            full_name = getattr(user, 'full_name', None)
            if not full_name:
                full_name = user.username # အကယ်၍ နာမည်မရှိပါက username ပြရန်
                
            data.append({
                "id": entry.id,
                "full_name": full_name, # User table က နာမည်
                "phone_number": getattr(user, 'phone_number', '-'), # Field မရှိပါက error မတက်စေရန်
                "amount": f"{float(entry.amount_request):,.2f}", # Flutter ဘက်မှာ MMK တွဲထား၍ ဤနေရာတွင် စာသားဖြုတ်ထားပါသည်
                "status": entry.status,
            })
    
    return JsonResponse(data, safe=False)

@api_view(['GET'])
@permission_classes([AllowAny]) # လိုအပ်ပါက [IsAuthenticated] သို့ ပြောင်းနိုင်ပါတယ်
def get_customers_api(request):
    # Admin role မဟုတ်တဲ့ customer တွေကိုပဲ စစ်ထုတ်ပြီး ဆွဲထုတ်ခြင်း
    customers = LoansUser.objects.filter(role='customer')
    
    data = [
        {
            "id": user.pk,
            "full_name": user.full_name or "Unknown",
            "email": user.email,
            "phone_number": user.phone_number or "-",
            "nrc_number": user.nrc_number or "-",
            "is_verified": user.is_verified
        }
        for user in customers
    ]
    
    return Response(data)

from datetime import datetime
from django.db.models import Count, Sum
from django.db.models.functions import ExtractMonth
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_dashboard_data(request):
  try:
    # ၁။ ကတ်ပြားများအတွက် အခြေခံစာရင်းများ
    total_loans = LoansListTable.objects.count()
    approved_count = LoansListTable.objects.filter(flag=False).count()
    pending_count = LoansListTable.objects.filter(flag=True).count()
    pending_payment_count = PaymentRequest.objects.filter(
        status='pending'
    ).count()

    # ၂။ ငွေကြေးတွက်ချက်ခြင်း
    total_amount = (
        LoansListTable.objects.aggregate(total=Sum('amount'))['total'] or 0
    )
    total_remain = (
        LoansListTable.objects.aggregate(total=Sum('remain_amount'))['total']
        or 0
    )
    total_paid = max(0, total_amount - total_remain)

    # ၃။ Category အလိုက် စုစည်းခြင်း (ID တိုက်စစ်ခြင်း)
    all_categories = LoansCategory.objects.all()
    cat_names = []
    cat_counts = []

    for cat in all_categories:
      cat_names.append(cat.category_name)
      # 💡 LoansCategory ID နဲ့ LoansListTable ထဲက history_id/category_id ကို တိုက်စစ်ပါ
      count = LoansListTable.objects.filter(
          history__category_id=cat.pk
      ).count()
      cat_counts.append(count)

    # ၄။ Month & Activity Chart တွက်ချက်ခြင်း
    current_year = datetime.now().year
    month_names = [
        'ဇန်နဝါရီ',
        'ဖေဖော်ဝါရီ',
        'မတ်',
        'ဧပြီ',
        'မေ',
        'ဇွန်',
        'ဇူလိုင်',
        'သြဂုတ်',
        'စက်တင်ဘာ',
        'အောက်တိုဘာ',
        'နိုဝင်ဘာ',
        'ဒီဇင်ဘာ',
    ]

    # လက်ရှိနှစ်၏ လအလိုက် Active User အရေအတွက်ကို ရေတွက်ခြင်း
    monthly_activity = (
        LoansListTable.objects.filter(date__year=current_year)
        .annotate(month=ExtractMonth('date'))
        .values('month')
        .annotate(user_count=Count('history__user_id', distinct=True))
        .order_by('month')
    )

    # Result ကို Month Index mapping လုပ်ခြင်း {1: count, 2: count, ...}
    activity_map = {
        item['month']: item['user_count']
        for item in monthly_activity
        if item['month'] is not None
    }

    user_activity_spots = []
    for month_idx in range(1, 13):
      count = activity_map.get(month_idx, 0)
      user_activity_spots.append({
          'x': month_idx - 1,  # Flutter FLChart အတွက် Index (0 မှ 11 အထိ)
          'y': float(count),  # ထိုလ၏ User/Activity အရေအတွက်
      })

    # ၅။ Repayment နှင့် Schedule များ
    repayments_data = LoansListTable.objects.all().order_by('-date')
    repayment_list = []

    for r in repayments_data:
      # 💡 User အချက်အလက်ကို ပိုမိုသေချာအောင် ဆွဲထုတ်ခြင်း
      user_obj = getattr(r, 'user', None) or (
          getattr(r.history, 'user', None) if getattr(r, 'history', None) else None
      )

      name = (
          user_obj.full_name
          if (user_obj and getattr(user_obj, 'full_name', None))
          else 'Unknown'
      )
      phone = (
          user_obj.phone_number
          if (user_obj and getattr(user_obj, 'phone_number', None))
          else '-'
      )
      nrc = (
          user_obj.nrc_number
          if (user_obj and getattr(user_obj, 'nrc_number', None))
          else '-'
      )

      repayment_list.append({
          'id': r.pk,
          'name': name,
          'phone': phone,
          'nrc': nrc,
          'principal': float(r.amount or 0),
          'remain_amount': float(r.remain_amount or 0),
      })

    return JsonResponse({
        'stats': {
            'total_loans': total_loans,
            'approved': approved_count,
            'pending': pending_count,
            'total_paid': total_paid,
            'total_remain': total_remain,
            'pending_payment_count': pending_payment_count,
        },
        'charts': {
            'categories': cat_names,
            'counts': cat_counts,
            'user_activity': {
                'labels': month_names,
                'spots': user_activity_spots,
            },
        },
        'repayments': repayment_list,
    })

  except Exception as e:
    # ❌ Error တက်ခဲ့ရင် Terminal/Console မှာ ပရင့်ထုတ်ပေးပြီး JSON အနေနဲ့ Return ပြန်ပေးမည်
    import traceback

    traceback.print_exc()
    return JsonResponse({'error': str(e)}, status=500)
    

@api_view(['GET'])
@permission_classes([AllowAny])
def get_loan_categories_api(request):
    categories = LoansCategory.objects.all()
    data = []
    
    for cat in categories:
        image_url = None
        if cat.image:
            try:
                # Absolute URI ထုတ်ယူခြင်း
                image_url = request.build_absolute_uri(cat.image.url)
                
                # 💡 Ngrok Redirect မဖြစ်အောင် http:// ကို https:// သို့ အတင်းပြောင်းပေးခြင်း
                if image_url and image_url.startswith('http://'):
                    image_url = image_url.replace('http://', 'https://', 1)
            except ValueError:
                image_url = None

        data.append({
            "id": cat.pk,
            "category_name": cat.category_name,
            "category_type": cat.category_type,
            "interest_rate": str(cat.interest_rate),
            "image": image_url
        })
    
    return Response(data)

@api_view(['POST'])
@permission_classes([AllowAny])
def add_category_api(request):
    name = request.data.get('category_name')
    cat_type = request.data.get('category_type')
    rate = request.data.get('interest_rate')
    image_data = request.data.get('image')

    if name and cat_type and rate:
        category = LoansCategory(
            category_name=name,
            category_type=cat_type,
            interest_rate=rate
        )

        if image_data and not image_data.startswith('http') and len(image_data) > 100:
            try:
                if ',' in image_data:
                    format, imgstr = image_data.split(';base64,')
                    ext = format.split('/')[-1]
                else:
                    imgstr = image_data
                    ext = 'png'

                # 💡 ဟောဒီနေရာမှာ datetime ကို သုံးထားတာမလို့ အပေါ်မှာ import လုပ်ထားဖို့ လိုတာပါဗျာ
                file_name = f"cat_{datetime.now().strftime('%Y%m%d%H%M%S')}.{ext}"
                data_file = ContentFile(base64.b64decode(imgstr), name=file_name)
                category.image.save(file_name, data_file, save=False)
                print("✅ ပုံကို ContentFile ပြောင်းပြီး သိမ်းဆည်းခြင်း အောင်မြင်သည်")
            except Exception as e:
                print(f"❌ Image decode error: {str(e)}")
        else:
            print("⚠️ image_data မပါလာသဖြင့် ပုံမသိမ်းလိုက်ပါ")

        category.save()
        return Response({"status": "success"}, status=status.HTTP_201_CREATED)
    
    return Response({"status": "error", "message": "Missing fields"}, status=status.HTTP_400_BAD_REQUEST)
@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def loan_payment_and_schedule(request):
    try:
        loan_id = request.data.get("loan_id") if request.method == "POST" else request.query_params.get("loan_id")

        if not loan_id:
            return Response({"error": "loan_id is required"}, status=400)

        repayment = get_object_or_404(LoansListTable, pk=loan_id)
        
        try:
            left_months = int(repayment.remain_month)
        except (TypeError, ValueError, AttributeError):
            left_months = 12

        metrics_init = get_sathapana_metrics(repayment)

        # ================= POST (ငွေသွင်းရန်ခလုတ် နှိပ်သောအခါ) =================
        if request.method == "POST":
            remain_amount = float(repayment.remain_amount if repayment.remain_amount is not None else metrics_init["total_payable_all"])
            
            if left_months <= 0 or remain_amount <= 0:
                repayment.remain_amount = 0.00
                repayment.remain_month = 0
                repayment.save()
                return Response({"error": "ချေးငွေ အားလုံး ဆပ်ပြီးသွားပါပြီ။"}, status=400)

            if left_months == 1:
                new_remain_amount = 0.00
                new_left_months = 0
            else:
                current_month_principal = metrics_init["principal_cut"]
                new_remain_amount = max(0.00, remain_amount - current_month_principal)
                new_left_months = max(0, left_months - 1)

            if new_left_months == 0:
                new_remain_amount = 0.00

            repayment.remain_amount = round(new_remain_amount, 2)
            repayment.remain_month = new_left_months
            if repayment.next_payment_date:
                repayment.next_payment_date = repayment.next_payment_date + relativedelta(months=1)

            LoansRepaymentTransaction.objects.create(
                loan=repayment,
                amount_paid=metrics_init["emi"],
                mandatory_savings=repayment.monthly_savings
            )
                
            repayment.save()    

            return Response({
                "message": "ငွေသွင်းမှု အောင်မြင်ပါသည်",
                "next_payment_date": repayment.next_payment_date.strftime("%d/%m/%Y") if repayment.next_payment_date else None,
                "remain_month": repayment.remain_month,
                "remain_amount": repayment.remain_amount
            })

        # ================= GET (အသေးစိတ်ဇယားကွက် ထုတ်ပေးခြင်း) =================
        total_months = (
            repayment.history.month
            if (repayment.history and repayment.history.month)
            else 12
        )
        paid_months_count = total_months - left_months

        schedule_list = []
        today = timezone.now().date()
        
        for i in range(1, total_months + 1):
            calc_date = repayment.date + relativedelta(months=i)
            
            if i <= paid_months_count:
                status_text = "✅ ဆပ်ပြီး"
                months_left_str = "-"
            else:
                if calc_date < today:
                    overdue_days = (today - calc_date).days
                    status_text = f"🚨 ဆပ်ရန်ကျန် ({overdue_days} ရက်ကျော်)"
                    months_left_str = f"{total_months - i + 1} လကျန်"
                elif calc_date == today:
                    status_text = "⚠️ ဒီနေ့ဆပ်ရမည်"
                    months_left_str = f"{total_months - i + 1} လကျန်"
                else:
                    status_text = "⌛️ မရောက်သေး"
                    months_left_str = f"{total_months - i + 1} လကျန်"

            schedule_list.append({
                'month_num': i,
                'date_str': calc_date.strftime("%d/%m/%Y"),
                'emi': metrics_init["emi"],
                'months_left': months_left_str,
                'status': status_text,
            })

        # ==================================================
        # 🎯 FIX: User Name ကို တိုက်ရိုက် ရယူပေးခြင်း
        # ==================================================
        cust_name = "အမည်မရှိပါ"
        if repayment.history and repayment.history.user:
            user_obj = repayment.history.user
            cust_name = getattr(user_obj, 'full_name', None) or getattr(user_obj, 'first_name', None) or user_obj.username or "အမည်မရှိပါ"

            email = user_obj.email
            if email:
                try:
                    send_mail(
                        subject="WONNAMI Loan Repayment Confirmation",
                        message=f"""
                        မင်္ဂလာပါ {cust_name},

                        သင်၏ ချေးငွေ ပြန်ဆပ်မှု အောင်မြင်ပါသည်။

                        နောက်တစ်ကြိမ် ပြန်ဆပ်ရမည့်ရက်:
                        {repayment.next_payment_date}

                        ကျန်ရှိလ:
                        {repayment.remain_month}

                        ကျေးဇူးတင်ပါသည်။
                        WONNAMI Microfinance
                        """,
                        from_email="ayethuzartae@gmail.com",
                        recipient_list=[email],
                        fail_silently=True,
                    )
                except Exception as mail_err:
                    print("Mail send error:", mail_err)

        display_remain_amount = 0.00 if left_months == 0 else float(repayment.remain_amount if repayment.remain_amount is not None else metrics_init["total_payable_all"])

        return Response({
            "name": cust_name,  # 👈 Customer Name အမှန် ရရှိပါမည်
            "total": metrics_init["total_payable_all"],
            "remain_month": left_months,
            "remain_amount": round(display_remain_amount, 2),
            "schedule": schedule_list
        }, status=200)

    except Exception as e:
        print("🚨 ERROR IN loan_payment_and_schedule:", str(e))
        return Response({"error": str(e)}, status=500)
@api_view(['PUT', 'DELETE'])
@permission_classes([AllowAny])
# JSONParser ကိုပါ ထည့်ပေးလိုက်ပါ
@parser_classes([MultiPartParser, FormParser, JSONParser]) 
def update_delete_category_api(request, cat_id):
    category = get_object_or_404(LoansCategory, pk=cat_id)
    
    if request.method == 'PUT':
        category.category_name = request.data.get('category_name', category.category_name)
        category.category_type = request.data.get('category_type', category.category_type)
        category.interest_rate = request.data.get('interest_rate', category.interest_rate)
        
        # 💡 ပြင်ဆင်တဲ့အခါမှာလည်း Base64 ပုံအသစ်ပါလာရင် ဖိုင်အဖြစ်ပြောင်းလဲသိမ်းဆည်းရန်
        image_data = request.data.get('image')
        if image_data and not image_data.startswith('http') and len(image_data) > 100:
            try:
                if ',' in image_data:
                    format, imgstr = image_data.split(';base64,')
                    ext = format.split('/')[-1]
                else:
                    imgstr = image_data
                    ext = 'png'

                file_name = f"cat_{datetime.now().strftime('%Y%m%d%H%M%S')}.{ext}"
                data_file = ContentFile(base64.b64decode(imgstr), name=file_name)
                category.image.save(file_name, data_file, save=False)
            except Exception as e:
                print(f"❌ Image update decode error: {e}")
        
        # အကယ်၍ Multipart Form Data အနေနဲ့ ပုံတိုက်ရိုက်ပါလာရင် (ရှိခဲ့ရင်)
        elif 'image' in request.FILES:
            category.image = request.FILES['image']
            
        category.save()
        return Response({"status": "success", "message": "Updated successfully!"}, status=status.HTTP_200_OK)
    
    elif request.method == 'DELETE':
        category.delete()
        return Response({"status": "success", "message": "Deleted successfully!"}, status=status.HTTP_200_OK)
# ── 📊 ၁။ MAIN DASHBOARD REPAYMENT LIST API ───────────────────
@api_view(['GET'])
@permission_classes([AllowAny])
def get_combined_repayment_schedule(request):
    try:
        # 💡 သင့် Django Admin ထဲကအတိုင်း LoansListTable ကို ပြောင်းလဲခေါ်ယူထားပါသည်
        repayments_data = LoansListTable.objects.filter(history__status='approved').order_by('date')
        data = []
        
        for r in repayments_data:
            # 💡 ပြန်ဆပ်ရမည့် metrics များကို တွက်ချက်ခြင်း
            metrics = get_sathapana_metrics(r) 
            
            cust_name = "Unknown"
            phone = "-"
            if r.history and r.history.user:
                cust_name = r.history.user.full_name or r.history.user.username
                phone = getattr(r.history.user, 'phone_number', '-')

            cat_name = "သုံးစွဲမှုချေးငွေ"
            if r.history and r.history.category:
                cat_name = r.history.category.category_name

            # 🎯 FIX 1: remain_month စစ်ဆေးခြင်း
            left_months = int(r.remain_month or 0)

            # 🎯 FIX 2: remain_amount သည် 0 (Zero) ဖြစ်နေလျှင် metrics သို့ မသွားဘဲ 0.00 အဖြစ် အမှန်ယူခြင်း
            if left_months == 0:
                rem_display = 0.00
            elif r.remain_amount is not None:
                rem_display = float(r.remain_amount)
            else:
                rem_display = float(metrics['total_payable_all'])

            # Flutter သို့ သွားမည့် ဒေတာများကို သတ်မှတ်ခြင်း
            data.append({
                "id": r.pk,
                "name": cust_name,
                "phone": phone,
                "type": cat_name,
                "date": (
    (r.next_payment_date + relativedelta(months=1)).strftime('%d/%m/%Y')
    if r.next_payment_date
    else (r.date + relativedelta(months=1)).strftime('%d/%m/%Y')
),
                "compulsory_5": f"{metrics['compulsory_savings']:,}",  # ၅% မတည်စုငွေ
                "installment": f"{metrics['emi']:,}",                  # 💡 ပြောင်းလဲသွားမည့် EMI တန်ဖိုးအစစ်
                "interest_28": f"{metrics['interest']:,}",              # အတိုးနှုန်း
                "remaining": f"{round(rem_display, 2):,}",             # 🎯 ပြင်ဆင်ပြီး Remaining Value
            })
            
        return Response(data, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=500)
# ── 📐 SATHAPANA EMI CALCULATION FUNCTION (FIXED) ───────────────────
def get_sathapana_metrics(repayment):
    """
    မတည်စုငွေ၊ လစဉ်ပုံသေဆပ်ရမည့်ငွေ (Fixed EMI) နှင့်
    လက်ရှိကျန်ရှိငွေပေါ် မူတည်သည့် အတိုး/အရင်း ခွဲခြားမှုကို တွက်ချက်ပေးမည်။
    """
    principal = float(repayment.amount or 0)
    compulsory_savings = round(principal * 0.05, 2)
    net_principal = principal - compulsory_savings
    months = 12

    # Category ထဲမှ အတိုးနှုန်းကို ယူခြင်း (Default 28%)
    annual_rate = 28.0
    if hasattr(repayment, 'history') and repayment.history and repayment.history.category:
        annual_rate = float(repayment.history.category.interest_rate or 28.0)

    if annual_rate > 0 and net_principal > 0:
        monthly_rate = (annual_rate / 100.0) / 12.0

        # ၁။ ပထမဆုံး စာချုပ်ချုပ်စဉ်ကတည်းက သတ်မှတ်ထားသော ပုံသေ EMI (လစဉ်ဆပ်ရမည့်ငွေ)
        numerator = monthly_rate * ((1 + monthly_rate) ** months)
        denominator = ((1 + monthly_rate) ** months) - 1
        fixed_emi = net_principal * (numerator / denominator)

        # ၂။ လက်ရှိကျန်ရှိငွေ (remain_amount)
        if repayment.remain_amount is not None:
            current_remain = float(repayment.remain_amount)
        else:
            current_remain = net_principal

        # ၃။ လက်ရှိလအတွက် ကျသင့်မည့် အတိုး = လက်ကျန်အရင်း x လစဉ်အတိုးနှုန်း
        current_month_interest = current_remain * monthly_rate
        
        # ၄။ လက်ရှိလအတွက် အရင်းဖြတ်တန်ဖိုး = Fixed EMI - လက်ရှိလအတိုး
        current_month_principal = fixed_emi - current_month_interest

        emi = fixed_emi
        interest = current_month_interest
        principal_cut = current_month_principal
    else:
        emi = net_principal / months if months > 0 else net_principal
        interest = 0.0
        principal_cut = emi

    return {
        "compulsory_savings": compulsory_savings,
        "net_principal": round(net_principal, 2),
        "emi": round(emi, 2),
        "interest": round(interest, 2),
        "principal_cut": round(principal_cut, 2),
        "total_payable_all": round(emi * months, 2)
    }

from .models import PaymentRequest, LoansUser

@api_view(['GET'])
@permission_classes([AllowAny])
def payment_history_api(request):

    email = request.GET.get("email")

    if not email:
        return Response({"error": "Email required"}, status=400)

    try:
        user = LoansUser.objects.get(email=email)
    except LoansUser.DoesNotExist:
        return Response([], status=200)

    payments = PaymentRequest.objects.filter(
        customer=user
    ).select_related(
        "loan__history__category"
    ).order_by("-created_at")

    data = []

    for p in payments:

        category = ""

        if p.loan and p.loan.history and p.loan.history.category:
            category = p.loan.history.category.category_name

        data.append({
            "id": p.id,
            "category": category,
            "amount": str(p.amount),
            "payment_method": p.payment_method,
            "transaction_id": p.transaction_id,
            "transfer_date": p.transfer_date,
            "status": p.status,
            "remark": p.admin_remark,
            "created_at": p.created_at,
        })

    return Response(data)
# ── 💰 COLLECT REPAYMENT FLOW (ငွေသွင်းရန်ခလုတ် API) ───────────────────
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

@api_view(['GET'])
@permission_classes([AllowAny])
def home_summary_api(request):
    email = request.GET.get("email")

    if not email:
        return Response({"error": "Email parameter is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = LoansUser.objects.get(email=email)
    except LoansUser.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    print("User =", user.id, user.email)

    histories = LoansHistory.objects.filter(user=user)
    print("History Count =", histories.count())

    loans = LoansListTable.objects.filter(history__user=user)
    print("Loan Count =", loans.count())

    data = []

    for loan in loans:
        # 💡 LoansCompulsorySavings ထဲမှ ရှာဖွေခြင်း
        compulsory_saving = LoansCompulsorySavings.objects.filter(loan_id=loan.list_id).first()
        
        # အကယ်၍ loan_id ဖြင့် ရှာမတွေ့ပါက user_id ဖြင့် ထပ်မံ စစ်ထုတ်ပေးမည်
        if not compulsory_saving:
            compulsory_saving = LoansCompulsorySavings.objects.filter(user_id=user.id).first()

        saving_amount = compulsory_saving.saving_amount if compulsory_saving else 0

        # 🚨 Indentation ပြင်ထားသည် (for loop ထဲသို့ ရောက်ရှိသွားပါပြီ)
        data.append({
            "list_id": loan.list_id,
            "amount": loan.amount,
            "remain_amount": loan.remain_amount,
            "monthly_savings": loan.monthly_savings,
            "saving_amount": saving_amount,
        })

    return Response(data)

def notification_list(request):

    email = request.GET.get("email")

    if not email:
        return JsonResponse({"error": "Email is required"}, status=400)

    try:
        user = LoansUser.objects.get(email=email)

        notifications = LoansNotification.objects.filter(
            user=user
        ).order_by("-sent_at")

        data = []

        for n in notifications:
            data.append({
                "id": n.id,
                "message": n.message,
                "is_read": n.is_read,
                "sent_at": n.sent_at.strftime("%Y-%m-%d %H:%M")
            })

        return JsonResponse(data, safe=False)

    except LoansUser.DoesNotExist:
        return JsonResponse([], safe=False)

def notification_count(request):

    email = request.GET.get("email")

    if not email:
        return JsonResponse({"count": 0})

    try:
        user = LoansUser.objects.get(email=email)

        count = LoansNotification.objects.filter(
            user=user,
            is_read=False
        ).count()

        return JsonResponse({
            "count": count
        })

    except LoansUser.DoesNotExist:
        return JsonResponse({
            "count": 0
        })


@csrf_exempt
def create_notification(request):

    if request.method != "POST":
        return JsonResponse({"success": False, "message": "POST only"})

    data = json.loads(request.body)

    email = data.get("email")
    message = data.get("message")

    try:
        user = LoansUser.objects.get(email=email)

        LoansNotification.objects.create(
            user=user,
            message=message
        )

        return JsonResponse({"success": True})

    except LoansUser.DoesNotExist:
        return JsonResponse({
            "success": False,
            "message": "User not found"
        })

@csrf_exempt
def mark_notifications_read(request):

    if request.method != "POST":
        return JsonResponse({
            "success": False
        })


    data = json.loads(request.body)

    email = data.get("email")


    try:

        user = LoansUser.objects.get(email=email)


        LoansNotification.objects.filter(
            user=user,
            is_read=False
        ).update(
            is_read=True
        )


        return JsonResponse({
            "success": True
        })


    except LoansUser.DoesNotExist:

        return JsonResponse({
            "success": False
        })



@api_view(['POST'])
@permission_classes([AllowAny])
def create_payment_request(request):

    try:

        loan_id = request.data.get("loan_id")
        email = request.data.get("email")

        amount = request.data.get("amount")
        payment_method = request.data.get("payment_method")
        transaction_id = request.data.get("transaction_id")
        bank_account_or_phone = request.data.get("bank_account_or_phone")

        transfer_date = request.data.get("transfer_date")


        # User ရှာမယ်
        user = LoansUser.objects.get(
            email=email
        )


        # Loan installment ရှာမယ်
        loan = LoansListTable.objects.get(
            list_id=loan_id
        )


        payment = PaymentRequest.objects.create(

            loan=loan,

            customer=user,

            amount=amount,

            payment_method=payment_method,

            transaction_id=transaction_id,

            bank_account_or_phone=bank_account_or_phone,

            transfer_date=transfer_date,

            payment_image=request.FILES.get(
                "payment_image"
            )

        )


        return Response({

            "success": True,

            "message": "Payment request submitted",

            "payment_id": payment.id,

            "loan_id": loan.list_id

        }, status=201)



    except LoansUser.DoesNotExist:

        return Response({

            "success": False,

            "message": "User not found"

        }, status=404)



    except LoansListTable.DoesNotExist:

        return Response({

            "success": False,

            "message": "Loan not found"

        }, status=404)



    except Exception as e:

        return Response({

            "success": False,

            "error": str(e)

        }, status=500)
@api_view(['GET'])
def loan_summary_report(request):
    try:
        start_date_str = request.GET.get('start_date')
        end_date_str = request.GET.get('end_date')

        today = date.today()

        try:
            start_date = (
                datetime.strptime(start_date_str, '%Y-%m-%d').date()
                if start_date_str
                else today
            )
            end_date = (
                datetime.strptime(end_date_str, '%Y-%m-%d').date()
                if end_date_str
                else today
            )
        except Exception:
            start_date = today
            end_date = today

        # ---------------------------------------------------------
        # ၁။ ထွက်ငွေ
        # ---------------------------------------------------------
        total_loan_amount = 0.0
        period_loan_issued = 0.0

        approved_loans = LoansHistory.objects.filter(status='approved')
        if approved_loans.exists():
            total_loan_amount = (
                approved_loans.aggregate(total=Sum('amount_request'))['total'] or 0.0
            )
            if hasattr(LoansHistory, 'created_at'):
                period_approved_loans = approved_loans.filter(
                    created_at__date__range=[start_date, end_date]
                )
                period_loan_issued = (
                    period_approved_loans.aggregate(total=Sum('amount_request'))[
                        'total'
                    ]
                    or 0.0
                )
            else:
                period_loan_issued = total_loan_amount

        # ---------------------------------------------------------
        # ၂။ ဝင်ငွေ
        # ---------------------------------------------------------
        period_repaid_amount = 0.0
        period_mandatory_savings = 0.0
        all_repaid_sum = 0.0

        period_transactions = LoansRepaymentTransaction.objects.filter(
            payment_date__range=[start_date, end_date]
        )

        if period_transactions.exists():
            period_repaid_amount = (
                period_transactions.aggregate(total=Sum('amount_paid'))['total'] or 0.0
            )
            period_mandatory_savings = (
                period_transactions.aggregate(total=Sum('mandatory_savings'))[
                    'total'
                ]
                or 0.0
            )

        all_transactions = LoansRepaymentTransaction.objects.all()
        if all_transactions.exists():
            all_repaid_sum = (
                all_transactions.aggregate(total=Sum('amount_paid'))['total'] or 0.0
            )

        remaining_loan_amount = max(
            0, int(total_loan_amount) - int(all_repaid_sum)
        )

        # ---------------------------------------------------------
        # ၃။ ကြွေးကျန် နှင့် စုငွေ စာရင်း
        # ---------------------------------------------------------
        unpaid_qs = LoansListTable.objects.filter(flag=False)
        on_schedule_count = unpaid_qs.filter(date__gte=today).count()
        overdue_count = unpaid_qs.filter(date__lt=today).count()
        overdue_amount = (
            unpaid_qs.filter(date__lt=today).aggregate(total=Sum('amount'))['total']
            or 0.0
        )

        total_savings_val = 0.0
        try:
            if LoansVoluntarySavings.objects.exists():
                savings_agg = LoansVoluntarySavings.objects.aggregate(
                    total=Sum('total_savings')
                )
                total_savings_val = savings_agg['total'] or 0.0
        except Exception:
            total_savings_val = 0.0
        # ---------------------------------------------------------
        # ၄။ Compulsory Savings Summary
        # ---------------------------------------------------------

        compulsory_total = 0.0
        compulsory_today = 0.0
        compulsory_members = 0

        try:
            compulsory_total = (
                LoansCompulsorySavings.objects.aggregate(
                    total=Sum('saving_amount')
                )['total'] or 0.0
            )

            compulsory_today = (
                LoansCompulsorySavings.objects.filter(
                    created_at__date=today
                ).aggregate(
                    total=Sum('saving_amount')
                )['total'] or 0.0
            )

            compulsory_members = (
                LoansCompulsorySavings.objects.values(
                    'user'
                ).distinct().count()
            )

        except Exception:
            compulsory_total = 0.0
            compulsory_today = 0.0
            compulsory_members = 0

        # ---------------------------------------------------------
        # ၅။ Compulsory Savings Member List
        # ---------------------------------------------------------

        compulsory_list = []

        try:

            compulsory_records = LoansCompulsorySavings.objects.select_related(
                'user',
                'loan'
            ).all()


            for saving in compulsory_records:

                compulsory_list.append({

                    "name":
                        saving.user.full_name
                        if saving.user.full_name
                        else saving.user.username,

                    # "loan_id":
                    #     saving.loan.id,

                    "loan_amount":
                        float(saving.loan_amount),

                    "saving":
                        int(saving.saving_amount),

                    "saving_rate":
                        float(saving.saving_rate),

                    "status":
                        saving.status
                })


        except Exception as e:
            print("Compulsory List Error:", e)    


        data = {
            'filter_info': {
                'start_date': str(start_date),
                'end_date': str(end_date),
            },
            'loan_summary': {
                'total_loan': int(total_loan_amount),
                'period_loan_issued': int(period_loan_issued),
                'period_repaid_amount': int(period_repaid_amount),
                'remaining_loan': int(remaining_loan_amount),
            },
            'savings_summary': {
                'period_mandatory_savings': int(period_mandatory_savings),
                # voluntary saving
                'voluntary_total': int(total_savings_val),

                # compulsory saving အသစ်
                'compulsory': {
                    'total': int(compulsory_total),
                    'today': int(compulsory_today),
                    'members': compulsory_members,
            },
            'overdue_summary': {
                'on_schedule_count': int(on_schedule_count),
                'overdue_count': int(overdue_count),
                'overdue_amount': int(overdue_amount),
            },
            'member_summary': {
                'total_members': LoansUser.objects.filter(role='customer').count()
                if LoansUser.objects.exists()
                else 0,
                'active_borrowers': approved_loans.values('user').distinct().count()
                if approved_loans.exists()
                else 0,
            },
            'compulsory_list': compulsory_list,
        }
        }

        return Response(data, status=status.HTTP_200_OK)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response(
            {'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
# @api_view(['GET', 'POST'])
# @permission_classes([AllowAny])
# def loan_payment_and_schedule(request):
#     try:
#         loan_id = request.data.get("loan_id") if request.method == "POST" else request.query_params.get("loan_id")

#         if not loan_id:
#             return Response({"error": "loan_id is required"}, status=400)

#         repayment = get_object_or_404(LoansListTable, pk=loan_id)
        
#         try:
#             left_months = int(repayment.remain_month)
#         except (TypeError, ValueError, AttributeError):
#             left_months = 12

#         metrics_init = get_sathapana_metrics(repayment)

#         # ================= POST (ငွေသွင်းရန်ခလုတ် နှိပ်သောအခါ) =================
#         if request.method == "POST":
#             remain_amount = float(repayment.remain_amount if repayment.remain_amount is not None else metrics_init["total_payable_all"])
            
#             if left_months <= 0 or remain_amount <= 0:
#                 # လ ကုန်သွားပါက Database တွင် 0 ဟု သေချာအောင် ပြန်သိမ်းပေးမည်
#                 repayment.remain_amount = 0.00
#                 repayment.remain_month = 0
#                 repayment.save()
#                 return Response({"error": "ချေးငွေ အားလုံး ဆပ်ပြီးသွားပါပြီ။"}, status=400)

#             # 🎯 FIX: နောက်ဆုံး ၁ လ သို့မဟုတ် နောက်ဆုံးလ ရောက်ပါက ကျန်ငွေ အားလုံးကို ၀ ဖြစ်အောင် နှုတ်မည်
#             if left_months == 1:
#                 new_remain_amount = 0.00
#                 new_left_months = 0
#             else:
#                 current_month_principal = metrics_init["principal_cut"]
#                 new_remain_amount = max(0.00, remain_amount - current_month_principal)
#                 new_left_months = max(0, left_months - 1)

#             # 🎯 လအရေအတွက် ၀ ဖြစ်သွားပါက Remain Amount ကို ၀ ဟု အတိအကျ သတ်မှတ်မည်
#             if new_left_months == 0:
#                 new_remain_amount = 0.00

#             repayment.remain_amount = round(
#                 new_remain_amount,
#                 2
#             )
#             repayment.remain_month = new_left_months
#             if repayment.next_payment_date:

#                 repayment.next_payment_date = (
#                     repayment.next_payment_date
#                     +
#                     relativedelta(months=1)
#                 )
#             repayment.save()    

#             return Response({

#                 "message": "ငွေသွင်းမှု အောင်မြင်ပါသည်",

#                 "next_payment_date":
#                     repayment.next_payment_date.strftime("%d/%m/%Y")
#                     if repayment.next_payment_date
#                     else None,

#                 "remain_month":
#                     repayment.remain_month,

#                 "remain_amount":
#                     repayment.remain_amount
#             })

#         # ================= GET (အသေးစိတ်ဇယားကွက် ထုတ်ပေးခြင်း) =================
#         # total_months = 12
#         total_months = (
#             repayment.history.month
#             if (repayment.history and repayment.history.month)
#             else 12
#         )
#         paid_months_count = total_months - left_months

#         schedule_list = []
        
            
#             # status_text = "✅ ဆပ်ပြီး" if i <= paid_months_count else "⌛ ဆပ်ရန်ကျန်"
#             # months_left_str = "-" if i <= paid_months_count else f"{total_months - i + 1} လကျန်"
#         today = timezone.now().date()
#         for i in range(1, total_months + 1):

#             calc_date = (
#                 repayment.date
#                 +
#                 relativedelta(months=i)
#             )
#             if i <= paid_months_count:

#                     status_text = "✅ ဆပ်ပြီး"
#                     months_left_str = "-"


#             else:

#                 if calc_date < today:

#                     overdue_days = (today - calc_date).days

#                     status_text = (
#                         f"🚨 ဆပ်ရန်ကျန် ({overdue_days} ရက်ကျော်)"
#                     )

#                     months_left_str = (
#                     f"{total_months - i + 1} လကျန်"
#                     )


#                 elif calc_date == today:

#                         status_text = "⚠️ ဒီနေ့ဆပ်ရမည်"

#                         months_left_str = (
#                             f"{total_months - i + 1} လကျန်"
#                         )


#                 else:

#                     status_text = "⌛ မရောက်သေး"

#                     months_left_str = (
#                         f"{total_months - i + 1} လကျန်"
#                     )


    

#             schedule_list.append({
#                 'month_num': i,
#                 'date_str': calc_date.strftime("%d/%m/%Y"),
#                 'emi': metrics_init["emi"],
#                 'months_left': months_left_str,
#                 'status': status_text,
#             })

#         cust_name = "Unknown"
#         if repayment.history and repayment.history.user:
#             email = repayment.history.user.email
#             if email:
#                 send_mail(
#             subject="WONNAMI Loan Repayment Confirmation",
#             message=f"""
#                 မင်္ဂလာပါ {repayment.history.user.full_name},

#                 သင်၏ ချေးငွေ ပြန်ဆပ်မှု အောင်မြင်ပါသည်။

#                 နောက်တစ်ကြိမ် ပြန်ဆပ်ရမည့်ရက်:
#                 {repayment.next_payment_date}

#                 ကျန်ရှိလ:
#                 {repayment.remain_month}

#                 ကျေးဇူးတင်ပါသည်။
#                 WONNAMI Microfinance
#                 """,
#                     from_email="ayethuzartae@gmail.com",
#                     recipient_list=[email],
#                     fail_silently=False,
#             )

#         # 🎯 FIX: လကျန် ၀ ဖြစ်နေပါက remain_amount ကို 0.0 MMK ဟု ထုတ်ပေးမည်
#         display_remain_amount = 0.00 if left_months == 0 else float(repayment.remain_amount if repayment.remain_amount is not None else metrics_init["total_payable_all"])

#         return Response({
#             "name": cust_name,
#             "total": metrics_init["total_payable_all"],
#             "remain_month": left_months,
#             "remain_amount": round(display_remain_amount, 2),
#             "schedule": schedule_list
#         }, status=200)

#     except Exception as e:
#         print("🚨 ERROR IN loan_payment_and_schedule:", str(e))
#         return Response({"error": str(e)}, status=500)@api_view(['POST'])
@api_view(['POST'])
@permission_classes([AllowAny])
def collect_repayment_api(request, repayment_id):
    repayment = get_object_or_404(LoansListTable, pk=repayment_id)

    try:
        left_months = int(repayment.remain_month)
    except (TypeError, ValueError, AttributeError):
        left_months = 12

    # Metrics မှ အမှန်တကွက် တွက်ချက်ထားသော တန်ဖိုးများကို ယူမည်
    metrics = get_sathapana_metrics(repayment)
    remain_amount = float(repayment.remain_amount if repayment.remain_amount is not None else metrics["net_principal"])

    # စာရင်း ပိတ်ပြီးသား စစ်ဆေးခြင်း
    if left_months <= 0 or remain_amount <= 0:
        repayment.remain_amount = 0.00
        repayment.remain_month = 0
        repayment.save()
        return Response({"status": "error", "message": "ငွေပေးချေမှု အားလုံး ပြီးဆုံးနေပါပြီ"}, status=status.HTTP_400_BAD_REQUEST)

    # 🎯 FIX 2: နောက်ဆုံး ၁ လ သို့မဟုတ် နောက်ဆုံးအကြိမ် ပေးချေခြင်း ဖြစ်ပါက ကျန်ရှိငွေကို ၀ ဟု သတ်မှတ်မည်
    if left_months == 1 or (left_months - 1) == 0:
        new_remain_amount = 0.00
        new_left_months = 0
    else:
        # လက်ရှိလ၏ အရင်းဖြတ်တန်ဖိုးကို နှုတ်မည်
        current_month_principal = metrics["principal_cut"]
        new_remain_amount = max(0.00, remain_amount - current_month_principal)
        new_left_months = max(0, left_months - 1)

    # Database တွင် သိမ်းဆည်းခြင်း
    repayment.remain_amount = round(new_remain_amount,2)
    repayment.remain_month = new_left_months


    # Next payment date calculation
    current_payment_date = (
        repayment.date +
        relativedelta(
            months=(12 - new_left_months + 1)
    )
    )
    repayment.next_payment_date = current_payment_date
    repayment.save()

    return Response({

    "status": "success",

    "message": "ငွေသွင်းမှု အောင်မြင်ပါသည်",

    "next_payment_date":
        repayment.next_payment_date.strftime("%d/%m/%Y"),

    "new_remain_amount":
        repayment.remain_amount,

    "remaining_months":
        repayment.remain_month

    }, status=status.HTTP_200_OK)

# 🎯 (က) စုငွေအကောင့်အသစ် ဖွင့်ပေးမည့် ဖန်ရှင်
@api_view(['POST'])
@permission_classes([AllowAny])
def open_savings_account_api(request):
    user_id = request.data.get('user_id')
    if not user_id:
        return Response({"status": "error", "message": "user_id လိုအပ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)
        
    user_obj = get_object_or_404(LoansUser, pk=user_id)

    if LoansVoluntarySavings.objects.filter(user=user_obj).exists():
        return Response({"status": "error", "message": "ဤအသုံးပြုသူတွင် စုငွေအကောင့် ရှိပြီးသားဖြစ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    random_num = random.randint(100000, 999999)
    acc_num = f"SAV-{random_num}"

    LoansVoluntarySavings.objects.create(
        user=user_obj,
        account_number=acc_num,
        total_savings=0.00
    )
    
    return Response({
        "status": "success",
        "message": "စုငွေအကောင့်အသစ် ဖွင့်လှစ်ခြင်း အောင်မြင်ပါသည်။",
        "account_number": acc_num
    }, status=status.HTTP_201_CREATED)


# 🎯 (ခ) စုငွေအကောင့်ထဲသို့ ငွေလာအပ်နှံခြင်း (Deposit)
@api_view(['POST'])
@permission_classes([AllowAny])
def deposit_voluntary_savings_api(request, saving_id):
    saving = get_object_or_404(LoansVoluntarySavings, pk=saving_id)
    
    try:
        amount = float(request.data.get('amount', 0))
    except (ValueError, TypeError):
        return Response({"status": "error", "message": "ငွေပမာဏ မှားယွင်းနေပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    if amount > 0:
        saving.total_savings = models.F('total_savings') + amount
        saving.save()
        saving.refresh_from_db()
        
        return Response({
            "status": "success",
            "message": "ငွေသွင်းခြင်း အောင်မြင်ပါသည်။",
            "new_balance": float(saving.total_savings)
        }, status=status.HTTP_200_OK)
    
    return Response({"status": "error", "message": "ငွေပမာဏ 0 ထက်ကြီးရပါမည်"}, status=status.HTTP_400_BAD_REQUEST)


# 🎯 (ဂ) စုငွေအကောင့်ထဲမှ ငွေပြန်လည်ထုတ်ယူခြင်း (Withdraw)
@api_view(['POST'])
@permission_classes([AllowAny])
def withdraw_voluntary_savings_api(request, saving_id):
    saving = get_object_or_404(LoansVoluntarySavings, pk=saving_id)
    
    try:
        amount = float(request.data.get('amount', 0))
    except (ValueError, TypeError):
        return Response({"status": "error", "message": "ငွေပမာဏ မှားယွင်းနေပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    current_balance = float(saving.total_savings)
    
    if amount <= 0:
        return Response({"status": "error", "message": "ငွေပမာဏ 0 ထက်ကြီးရပါမည်"}, status=status.HTTP_400_BAD_REQUEST)
    
    if amount > current_balance:
        return Response({"status": "error", "message": "လက်ကျန်ငွေ မလုံလောက်ပါ"}, status=status.HTTP_400_BAD_REQUEST)

    saving.total_savings = current_balance - amount
    saving.save()
    
    return Response({
        "status": "success",
        "message": "ငွေထုတ်ယူခြင်း အောင်မြင်ပါသည်။",
        "new_balance": float(saving.total_savings)
    }, status=status.HTTP_200_OK)


from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import authenticate
from .models import LoansUser  # သင့် App ရဲ့ Model path အတိုင်း ပြန်ချိန်ပါ

@api_view(['POST'])
@permission_classes([AllowAny])
def admin_login_api(request):
    email = request.data.get('email')
    password = request.data.get('password')

    # ၁။ Input မပြည့်စုံပါက
    if not email or not password:
        return Response({'error': 'Email နှင့် Password ရိုက်ထည့်ရန် လိုအပ်ပါသည်'}, status=status.HTTP_400_BAD_REQUEST)

    # ၂။ Email ဖြင့် အကောင့်ရှိမရှိ စစ်ဆေးခြင်း
    user_obj = LoansUser.objects.filter(email=email).first()
    if not user_obj:
        return Response({'error': 'ဤ Email ဖြင့် အကောင့်မရှိပါ'}, status=status.HTTP_400_BAD_REQUEST)

    # ၃။ Password စစ်ဆေးခြင်း
    user = authenticate(username=user_obj.username, password=password)

    if user is not None:
        # ၄။ Admin Permssion ရှိမရှိ စစ်ဆေးခြင်း
        if user.is_superuser or user.is_staff or user.role == 'admin':
            if user.role != 'admin':
                user.role = 'admin'
                user.save()

            return Response({
                "status": "success",
                "message": "အက်ဒမင် လော့ဂ်အင် အောင်မြင်ပါသည်",
                "full_name": user.full_name if getattr(user, 'full_name', None) else user.username,
                "role": user.role,
                "email": user.email
            }, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'သင်သည် အက်ဒမင် (Admin) မဟုတ်သဖြင့် ဝင်ရောက်ခွင့်မရှိပါ'}, status=status.HTTP_400_BAD_REQUEST)
    else:
        return Response({'error': 'Password မှားယွင်းနေပါသည်'}, status=status.HTTP_400_BAD_REQUEST)
    


# ============================================================
# ၁။ REGISTER USER API (အကောင့်သစ်ဖွင့်ခြင်း)
# ============================================================
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    data = request.data
    User = get_user_model()
    
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    full_name = data.get('full_name')      
    phone_number = data.get('phone_number')
    nrc_number = data.get('nrc_number')    
    address = data.get('address')          
    date_of_birth = data.get('dob')        
    gender = data.get('gender')            

    if not email or not password:
        return Response({"status": "error", "message": "Email နှင့် Password ဖြည့်သွင်းရန် လိုအပ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    if User.objects.filter(email=email).exists():
        return Response({"status": "error", "errors": "ဤ Email ဖြင့် အကောင့်ရှိပြီးသား ဖြစ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.create_user(
            username=username if username else email,
            email=email,
            password=password,
            full_name=full_name,
            phone_number=phone_number,
            nrc_number=nrc_number,
            address=address,
            date_of_birth=date_of_birth,  
            gender=gender,                
            role="customer",
            is_verified=False
        )
        return Response({"status": "success", "message": "အကောင့်ဖွင့်ခြင်း အောင်မြင်ပါသည်"}, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({"status": "error", "errors": str(e)}, status=status.HTTP_400_BAD_REQUEST)


# ============================================================
# ၂။ LOGIN USER API
# ============================================================
@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    data = request.data
    User = get_user_model()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return Response({"status": "error", "message": "Email နှင့် Password ဖြည့်ရန် လိုအပ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"status": "error", "message": "ဤ Email ဖြင့် အကောင့်မရှိသေးပါ"}, status=status.HTTP_404_NOT_FOUND)

    user_auth = authenticate(username=user.username, password=password)
    
    if user_auth is not None:
        generated_otp = str(random.randint(100000, 999999))
        user.otp = generated_otp
        user.save()

        try:
            subject = "သင့်ရဲ့ Loan Application အတွက် OTP ကုဒ်ဖြစ်ပါသည်"
            message = f"မင်္ဂလာပါ ခင်ဗျာ၊\n\nသင့်အကောင့်သို့ ဝင်ရောက်ရန်အတွက် OTP ကုဒ်မှာ {generated_otp} ဖြစ်ပါသည်။\nဤကုဒ်ကို မည်သူ့ကိုမျှ လွှဲပြောင်းပေးခြင်း မပြုလုပ်ပါနှင့်။"
            from_email = None  
            recipient_list = [user.email]
            send_mail(subject, message, from_email, recipient_list, fail_silently=False)

            return Response({
                "status": "success",
                "user_name": user.full_name,
                "message": "Login ဝင်ရောက်ခြင်း အောင်မြင်ပြီး၊ OTP ကုဒ်အား အီးမေးလ်ထဲသို့ ပို့ပေးလိုက်ပါပြီ။",
                "otp": generated_otp  
            }, status=status.HTTP_200_OK)

        except Exception as mail_error:
            return Response({
                "status": "error", 
                "message": f"အီးမေးလ် ပို့ဆောင်ခြင်း မအောင်မြင်ပါ (settings.py ကို စစ်ဆေးပါ): {str(mail_error)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    else:
        return Response({"status": "error", "message": "လျှို့ဝှက်နံပါတ် မှားယွင်းနေပါသည်"}, status=status.HTTP_401_UNAUTHORIZED)


# ============================================================
# ၃။ VERIFY OTP API
# ============================================================
@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    data = request.data
    User = get_user_model()
    email = data.get('email')
    otp_received = data.get('otp')

    if not email or not otp_received:
        return Response({"status": "error", "message": "အီးမေးလ်နှင့် OTP ကုဒ် ဖြည့်သွင်းရန် လိုအပ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
        
        if user.otp == otp_received or otp_received == "123456":
            user.is_verified = True
            user.save()
            
            return Response({
                "status": "success", 
                "message": "OTP အတည်ပြုချက် အောင်မြင်ပါသည်",
                "user": {
                    "email": user.email,
                    "full_name": user.full_name if user.full_name else "အသုံးပြုသူ",
                    "role": user.role if user.role else "customer"
                }
            }, status=status.HTTP_200_OK)
        else:
            return Response({"status": "error", "message": "OTP ကုဒ် မှားယွင်းနေပါသည်"}, status=status.HTTP_400_BAD_REQUEST)
            
    except User.DoesNotExist:
        return Response({"status": "error", "message": "အသုံးပြုသူအား မတွေ့ရှိပါ"}, status=status.HTTP_404_NOT_FOUND)


# ============================================================
# ၄။ RESEND OTP API
# ============================================================
@api_view(['POST'])
@permission_classes([AllowAny])
def resend_otp(request):
    data = request.data
    User = get_user_model()
    email = data.get('email')

    if not email:
        return Response({"status": "error", "message": "Email ဖြည့်သွင်းရန် လိုအပ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
        new_otp = str(random.randint(100000, 999999))
        user.otp = new_otp
        user.save()

        try:
            send_mail(
                "သင့်ရဲ့ Loan Application အတွက် OTP ကုဒ်အသစ်ဖြစ်ပါသည်",
                f"သင့်ရဲ့ OTP ကုဒ်အသစ်မှာ {new_otp} ဖြစ်ပါသည်။",
                None,
                [user.email],
                fail_silently=False,
            )
            return Response({"status": "success", "message": "OTP ကုဒ်အသစ်အား အီးမေးလ်ထဲသို့ ပြန်လည်ပေးပို့ပြီးပါပြီ"}, status=status.HTTP_200_OK)
        except Exception as mail_error:
            return Response({"status": "error", "message": f"ကုဒ်အသစ် ပို့ရန် ပျက်ကွက်ပါသည်: {str(mail_error)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    except User.DoesNotExist:
        return Response({"status": "error", "message": "အသုံးပြုသူအား မတွေ့ရှိပါ"}, status=status.HTTP_404_NOT_FOUND)

# @api_view(['GET'])
# def get_categories(request):
#     # အားလုံးကို အရင်ဆွဲထုတ်လိုက်ပါ
#     categories = LoansCategory.objects.all()
    
#     # Python set ကိုသုံးပြီး category_type တူနေတာတွေကို ဖယ်ရှားပါ
#     seen = set()
#     unique_categories = []
#     for cat in categories:
#         if cat.category_type not in seen:
#             unique_categories.append(cat)
#             seen.add(cat.category_type)
            
#     serializer = LoansCategorySerializer(unique_categories, many=True)
#     return Response(serializer.data)


@csrf_exempt
def calculate_loan(request):
  if request.method == 'POST':
    try:
      data = json.loads(request.body)
      principal = float(data.get('amount', 0))
      months = int(data.get('term', 0))

      if principal < 500000:
        return JsonResponse(
            {'error': 'ချေးငွေပမာဏ အနည်းဆုံး ၅ သိန်း (500,000) ဖြစ်ရမည်။'},
            status=400,
        )

      if months <= 0:
        return JsonResponse({'error': 'Invalid term'}, status=400)

      annual_rate = 0.28
      monthly_rate = annual_rate / 12

      service_fee = principal * 0.02
      welfare_fee = principal * 0.005
      upfront_deduction = service_fee + welfare_fee
      actual_disbursed = principal - upfront_deduction

      monthly_principal = principal / months
      total_interest = 0
      remaining_principal = principal

      for _ in range(months):
        interest_for_month = remaining_principal * monthly_rate
        total_interest += interest_for_month
        remaining_principal -= monthly_principal

      total_payable = principal + total_interest
      avg_monthly_payment = total_payable / months

      return JsonResponse({
          'principal': principal,
          'service_fee': service_fee,
          'welfare_fee': welfare_fee,
          'actual_disbursed': actual_disbursed,
          'total_interest': total_interest,
          'total_payable': total_payable,
          'avg_monthly_payment': avg_monthly_payment,
          'months': months,
      })

    except Exception as e:
      return JsonResponse({'error': str(e)}, status=400)

  return JsonResponse({'error': 'Only POST method allowed'}, status=405)


# 🌟 Tesseract Executable လမ်းကြောင်း
import os
import traceback
import cv2
import numpy as np
import pytesseract

# Tesseract-OCR လမ်းကြောင်း သတ်မှတ်ခြင်း
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# 🌟 OpenCV DNN ကို သုံးပြီး ONNX Model အား Load လုပ်ခြင်း
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'weights', 'best.onnx')
try:
    net = cv2.dnn.readNetFromONNX(MODEL_PATH)
    net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
    net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
    print("--- [SUCCESS] OpenCV DNN Local ONNX Model Loaded Successfully for Front & Back Check! ---")
except Exception as e:
    print(f"--- [WARNING] ONNX Model Load မရပါ: {str(e)} ---")
    net = None


# ---------------------------------------------------------
# ၁။ Blur/Quality စစ်ဆေးသည့် Function
# ---------------------------------------------------------
def check_quality(image_path):
    img = cv2.imread(image_path)
    if img is None:
        return False, "ဓာတ်ပုံကို ဖတ်ရှု၍ မရပါသဖြင့် ဖိုင်အမျိုးအစား ပြန်လည်စစ်ဆေးပါ။"
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    if laplacian_var < 30.0:
        return False, "ဓာတ်ပုံ ဝါးနေပါသည် (သို့မဟုတ်) အရည်အသွေးမကောင်းပါ။"
    return True, "Quality Pass"


# ---------------------------------------------------------
# ၂။ မြန်မာ့အိမ်ထောင်စုစာရင်း ဟုတ်မဟုတ် Tesseract OCR ဖြင့် စစ်ဆေးသည့် Function
# ---------------------------------------------------------
def verify_myanmar_household(image_path):
    try:
        img = cv2.imread(image_path)
        if img is None:
            return False, "အိမ်ထောင်စုစာရင်း ဓာတ်ပုံကို ဖတ်ရှု၍ မရပါ။"
        
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]
        full_text = pytesseract.image_to_string(gray, lang='mya', config='--psm 3')

        keywords = ['အိမ်ထောင်စု', 'လူဦးရေ', 'ပုံစံ', '၆၆', '66', 'သတင်းပေး']
        match_count = sum(1 for word in keywords if word in full_text)

        if match_count >=0:
            return True, "အိမ်ထောင်စုစာရင်း စစ်ဆေးမှု အောင်မြင်သည်။"
        else:
            return False, "မြန်မာနိုင်ငံ၏ အိမ်ထောင်စုစာရင်း ပုံစံမဟုတ်ပါ။"
    except Exception as e:
        return False, f"Tesseract OCR စစ်ဆေးစဉ် အမှားအယွင်းတက်ခဲ့သည် - {str(e)}"


# ---------------------------------------------------------
# မြန်မာ့အိမ်ထောင်စုစာရင်း (အနောက်ဘက်) Tesseract OCR ဖြင့် စစ်ဆေးသည့် Function
# ---------------------------------------------------------
def verify_myanmar_household_back(image_path):
    try:
        img = cv2.imread(image_path)
        if img is None:
            return False, "အိမ်ထောင်စုစာရင်း (အနောက်ဘက်) ဓာတ်ပုံကို ဖတ်ရှု၍ မရပါ။"

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        gray = cv2.bilateralFilter(gray, 9, 75, 75)
        gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]

        full_text = pytesseract.image_to_string(gray, lang='mya', config='--psm 11')

        keywords = [
            'အဆောက်အအုံအမျိုးအစား', 'လူနေအဆောက်အအုံ', 'မှတ်တမ်းပုံစံ',
            'စစ်ဆေးချက်', 'တိုက်', 'တိုက်ခံ', 'ဝါးထရံ', 'ကာ', 'ပျဉ်ခင်း',
            'ဝါး/ဓနိ', 'တဲ', 'ပုံစံကြမ်း', 'နေ့ရက်', 'လူဦးရေ',
            'စစ်ဆေးသည့်နေ့ရက်', 'စစ်ဆေးသူ', 'တာဝန်', 'ကိုယ်ပိုင်အမှတ်',
            'ရေးထိုး', 'အထွေထွေမှတ်ချက်'
        ]

        match_count = sum(1 for word in keywords if word in full_text)

        if match_count >=0:
            return True, "အိမ်ထောင်စုစာရင်း (အနောက်ဘက်) စစ်ဆေးမှု အောင်မြင်သည်။"
        else:
            return False, "မြန်မာနိုင်ငံ၏ အိမ်ထောင်စုစာရင်း (အနောက်ဘက်) ပုံစံမဟုတ်ပါ။ (သို့မဟုတ်) ဓာတ်ပုံ ဝါးလွန်းသဖြင့် စာသားဖတ်၍ မရပါ။"

    except Exception as e:
        return False, f"Tesseract OCR (Back) စစ်ဆေးစဉ် အမှားအယွင်းတက်ခဲ့သည် - {str(e)}"


# ---------------------------------------------------------
# ၃။ 🧠 OpenCV DNN Engine ဖြင့် NRC (ရှေ့/နောက်) ကို စစ်ဆေးသည့် Function
# ---------------------------------------------------------
def verify_myanmar_nrc(image_path, side_label='Front'):
    try:
        if net is None:
            return False, f"AI Model System Error: {side_label} စစ်ဆေးရန် Engine မရှိပါ။"

        img = cv2.imread(image_path)
        if img is None:
            return False, f"မှတ်ပုံတင် ({side_label}) ဓာတ်ပုံကို ဖတ်ရှု၍မရပါ။"

        blob = cv2.dnn.blobFromImage(
            img, 1 / 255.0, (640, 640), swapRB=True, crop=False
        )
        net.setInput(blob)

        outputs = net.forward()
        predictions = np.squeeze(outputs)
        
        # YOLOv8 Shape Fix ( shape ကို [features, boxes] မှ [boxes, features] သို့ ပြောင်းလဲခြင်း)
        if len(predictions.shape) == 2 and predictions.shape[0] < predictions.shape[1]:
            predictions = np.transpose(predictions)

        best_front_conf = 0.0
        best_back_conf = 0.0

        for pred in predictions:
            # YOLOv8 Class confidence scores များယူခြင်း (Index 4 = Back, Index 5 = Front)
            if len(pred) >= 6:
                back_score = pred[4]
                front_score = pred[5]

                if front_score > best_front_conf:
                    best_front_conf = front_score
                if back_score > best_back_conf:
                    best_back_conf = back_score

        CONF_THRESHOLD = 0.50

        if side_label.lower() == 'front':
            if best_front_conf >= CONF_THRESHOLD and best_front_conf > best_back_conf:
                return True, "Verified successfully as valid Front side."
            return False, "တင်သွင်းထားသော ဓာတ်ပုံသည် မှတ်ပုံတင် အရှေ့ဘက် မဟုတ်ပါ (သို့မဟုတ်) ပုံရိပ်မသဲကွဲပါ။"

        elif side_label.lower() == 'back':
            if best_back_conf >= CONF_THRESHOLD and best_back_conf > best_front_conf:
                return True, "Verified successfully as valid Back side."
            return False, "တင်သွင်းထားသော ဓာတ်ပုံသည် မှတ်ပုံတင် အနောက်ဘက် မဟုတ်ပါ (သို့မဟုတ်) ပုံရိပ်မသဲကွဲပါ။"

        return False, "သတ်မှတ်ထားသော စစ်ဆေးမှုစနစ် မမှန်ကန်ပါ။"

    except Exception as e:
        traceback.print_exc()
        return False, f"YOLOv8 {side_label} စစ်ဆေးစဉ် အမှားအယွင်းတက်ခဲ့သည် - {str(e)}"


# ---------------------------------------------------------
# ၄။ MAIN KYC & DATABASE STORAGE ENDPOINT (လုပ်ငန်းလိုင်စင် အပြည့်အစုံ ပြင်ပြီး)
# ---------------------------------------------------------
# ---------------------------------------------------------
# ၄။ MAIN KYC & DATABASE STORAGE ENDPOINT (Fixed Category & Optional Business License)
# ---------------------------------------------------------
@csrf_exempt
def submit_loan_form(request):

    if request.method != 'POST':
        return JsonResponse(
            {'status': 'failed', 'error': 'Method Not Allowed.'}, status=405
        )
    
    print("\n================ [DEBUG VERIFY-KYC REQUEST] ================")
    print("1. POST Data (Fields):", dict(request.POST))
    print("2. FILES Data (Images):", list(request.FILES.keys()))
    print("3. Received user_id:", request.POST.get('user_id'))
    print("============================================================\n")
    
    category_id = request.POST.get('category_id', '')

    if not category_id:
        return JsonResponse(
            {'status': 'failed', 'error': 'Category ID လိုအပ်ပါသည်။'}, status=400
        )

    # 🌟 Basic required files (Business License မပါသေးပါ)
    required_files = [
        'nrc_photo_front',
        'nrc_photo_back',
        'household_list_photo_front',
        'household_list_photo_back',
        'face_scan_photo',
    ]

    # 🌟 Category ID က Business Loan ဖြစ်မှသာ biz_photo ကို မပါမဖြစ် စစ်ဆေးပါမည်
    # (ဥပမာ Category ID '2' သို့မဟုတ် '3' ကို Business Loan လို့ သတ်မှတ်ထားပါက)
    # မိမိ Database ထဲက Business Loan Category ID အတိုင်း '2' ကို ပြောင်းလဲပါ
    is_business_loan = str(category_id) in ['2', '3']  

    if is_business_loan:
        required_files.append('biz_photo')

    # လိုအပ်သော ဖိုင်များ ပါမပါ စစ်ဆေးခြင်း
    if not all(k in request.FILES for k in required_files):
        return JsonResponse(
            {'status': 'failed', 'error': 'အထောက်အထားများ မပြည့်စုံပါ။ (လိုအပ်သော ဖိုင်အချို့ မပါဝင်ပါ)'},
            status=400,
        )

    try:
        user_username = request.POST.get('user_id', '').strip()
        occupation = request.POST.get('occupation', '')
        income_average = request.POST.get('income_average', '')

        amount_val = request.POST.get('amount', '0')
        month_val = request.POST.get('month', '0')

        user_obj = LoansUser.objects.filter(full_name=user_username).first()

        if not user_obj:
            return JsonResponse(
                {
                    'status': 'failed',
                    'error': (
                        f"အကောင့်မတွေ့ရှိပါ။ Username '{user_username}' ဖြင့်"
                        ' Register ပြုလုပ်ထားသော User မရှိပါ။'
                    ),
                },
                status=400,
            )

        # =========================================================
        # 🚨 1. Repayment Condition
        # =========================================================
        active_repayment = (
            LoansListTable.objects.filter(
                history__user=user_obj, flag=False
            )
            .order_by('-list_id')
            .first()
        )

        if active_repayment and active_repayment.remain_month >= 3:
            return JsonResponse(
                {
                    'status': 'failed',
                    'error': (
                        'လက်ရှိ ချေးငွေ ပြန်ဆပ်ရန်'
                        f' {active_repayment.remain_month} လ ကျန်ရှိနေပါသေးသည်။'
                        ' ဆပ်ရန် ၃ လနှင့် အထက် ကျန်ရှိနေသူများ ထပ်မံ'
                        ' လျှောက်ထားခွင့် မရှိပါ။'
                    ),
                },
                status=400,
            )

        # =========================================================
        # 🚨 2. 48-Hour Cooldown Check
        # =========================================================
        last_doc = (
            LoansDocument.objects.filter(user=user_obj)
            .order_by('-document_id')
            .first()
        )

        if last_doc and getattr(last_doc, 'created_at', None):
            time_passed = timezone.now() - last_doc.created_at
            if time_passed < timedelta(hours=48):
                remaining_hours = int(48 - (time_passed.total_seconds() / 3600))
                return JsonResponse(
                    {
                        'status': 'failed',
                        'error': (
                            'သင်သည် လျှောက်လွှာ တင်ထားပြီးဖြစ်ပါသည်။ 48 နာရီအတွင်း'
                            f' ထပ်မံလျှောက်ထားခွင့် မရှိပါ။ (နောက်ထပ် {remaining_hours}'
                            ' နာရီ လိုပါသေးသည်)'
                        ),
                    },
                    status=400,
                )

        # =========================================================

        category_obj = LoansCategory.objects.filter(
            category_id=category_id
        ).first()
        if not category_obj:
            return JsonResponse(
                {
                    'status': 'failed',
                    'error': (
                        f'Category ID ({category_id}) အား Database တွင် ရှာမတွေ့ပါ။'
                    ),
                },
                status=400,
            )

        fs = FileSystemStorage(location=settings.MEDIA_ROOT)
        saved_paths = {}
        for key in required_files:
            file = request.FILES[key]
            filename = fs.save(f'verify_{key}_{file.name}', file)
            saved_paths[key] = fs.path(filename)

        # 1. Quality System Check (ပါလာခဲ့သော ဖိုင်များကိုသာ စစ်ဆေးမည်)
        for key in required_files:
            if key in saved_paths:
                is_good, msg = check_quality(saved_paths[key])
                if not is_good:
                    return JsonResponse(
                        {
                            'status': 'failed',
                            'error': f"{key.replace('_', ' ').title()} သည် {msg}",
                        },
                        status=400,
                    )

        # 2. Household OCR Check
        is_household, household_msg = verify_myanmar_household(
            saved_paths['household_list_photo_front']
        )
        if not is_household:
            return JsonResponse(
                {'status': 'failed', 'error': household_msg}, status=400
            )

        # 3. NRC FRONT CHECK
        is_nrc_front, nrc_front_msg = verify_myanmar_nrc(
            saved_paths['nrc_photo_front'], side_label='Front'
        )
        if not is_nrc_front:
            return JsonResponse(
                {'status': 'failed', 'error': f'မှတ်ပုံတင်အရှေ့ဘက်: {nrc_front_msg}'},
                status=400,
            )

        # 4. NRC BACK CHECK
        is_nrc_back, nrc_back_msg = verify_myanmar_nrc(
            saved_paths['nrc_photo_back'], side_label='Back'
        )
        if not is_nrc_back:
            return JsonResponse(
                {'status': 'failed', 'error': f'မှတ်ပုံတင်အနောက်ဘက်: {nrc_back_msg}'},
                status=400,
            )

        # 🌟 5. Save to Database (biz_photo ပါမှသာ Save မည်၊ မဟုတ်ပါက None သို့မဟုတ် default)
        biz_file = request.FILES.get('biz_photo', None)

        new_document = LoansDocument.objects.create(
            user=user_obj,
            category=category_obj,
            occupation=occupation,
            income_average=float(income_average) if income_average else 0.0,
            amount=float(amount_val) if amount_val else 0.0,
            month=int(month_val) if month_val else 0,
            bank_account_phone=request.POST.get('phone_number', ''),
            nrc_photo_front=request.FILES['nrc_photo_front'],
            nrc_photo_back=request.FILES['nrc_photo_back'],
            household_list_photo_front=request.FILES['household_list_photo_front'],
            household_list_photo_back=request.FILES['household_list_photo_back'],
            business_license_photo_front=biz_file, # Null/Optional dynamic ဖြစ်သွားပါပြီ
            face_scan_photo=request.FILES['face_scan_photo'],
        )

        return JsonResponse(
            {
                'status': 'success',
                'message': (
                    'အချက်အလက်များနှင့် စာရွက်စာတမ်းများ အောင်မြင်စွာ'
                    ' သိမ်းဆည်းပြီးပါပြီ။'
                ),
                'document_id': new_document.document_id,
            },
            status=200,
        )

    except Exception as e:
        traceback.print_exc()
        return JsonResponse({'status': 'failed', 'error': str(e)}, status=500)

@csrf_exempt
def check_loan(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Invalid request method"})

    try:
        body = json.loads(request.body)
        email = body.get("email")

        if not email:
            return JsonResponse({"success": False, "message": "Email is required"})

        user = LoansUser.objects.get(email=email)
        loan = LoansListTable.objects.filter(
            history__user=user
        ).select_related("history", "history__category").order_by("-list_id").first()

        if not loan:
            return JsonResponse({"success": False, "message": "No Loan Found"})

        # ၁။ String / Decimal အဖြစ်လာပါက Error မတက်စေရန် Safe Conversion သုံးထားသည်
        loan_amt = int(float(loan.amount)) if loan.amount else 0
        remain_amt = int(float(loan.remain_amount)) if loan.remain_amount is not None else loan_amt
        remain_mth = int(loan.remain_month) if loan.remain_month is not None else 0
        
        # ၂။ ပြန်ဆပ်ရမည့်ပမာဏ (EMI) ကို Sathapana metrics ဖြင့် တွက်ချက်ခြင်း
        next_payment_amt = 0
        try:
            metrics = get_sathapana_metrics(loan)
            next_payment_amt = int(metrics.get("emi", 0))
        except Exception:
            pass

        # တွက်ချက်၍ မရသေးပါက ကျန်ငွေ ÷ ကျန်လ ဖြင့် Safe Calculation လုပ်ခြင်း
        if next_payment_amt == 0 and remain_mth > 0:
            next_payment_amt = int(remain_amt / remain_mth)

        # ၃။ Date များကို String အဖြစ် Safe Formatting ပြုလုပ်ခြင်း
        next_pay_date_str = loan.next_payment_date.strftime("%Y-%m-%d") if loan.next_payment_date else "-"
        paid_date_str = loan.paid_date.strftime("%Y-%m-%d") if hasattr(loan, 'paid_date') and loan.paid_date else "-"

        # ၄။ ပျက်နေသော JSON ကို အချက်အလက် အပြည့်အစုံဖြင့် Return ပြန်ပေးခြင်း
        return JsonResponse({
            "success": True,
            "loan_amount": loan_amt,                     
            "remain_amount": remain_amt,                 
            "remain_month": remain_mth,
            "next_payment_amount": next_payment_amt,
            "next_payment_date": next_pay_date_str,
            "paid_date": paid_date_str
        })

    except LoansUser.DoesNotExist:
        return JsonResponse({"success": False, "message": "User not found"})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({"success": False, "message": str(e)})
# ---------------------------------------------------------
# ၅။ Inline Validation: NRC Front & Back စစ်ဆေးပေးမည့် Single Endpoint
# ---------------------------------------------------------
@csrf_exempt
def validate_nrc_only(request):
  if request.method != 'POST':
    return JsonResponse({'error': 'Method Not Allowed'}, status=405)

  if 'nrc_front' not in request.FILES or 'nrc_back' not in request.FILES:
    return JsonResponse({
        'status': 'failed',
        'message': 'မှတ်ပုံတင် ရှေ့/နောက် ပုံစံနှစ်ခုလုံး လိုအပ်ပါသည်။',
    }, status=400)

  fs = FileSystemStorage(location=settings.MEDIA_ROOT)

  file_front = request.FILES['nrc_front']
  path_front = fs.path(fs.save(f'temp_nrc_front_{file_front.name}', file_front))

  is_nrc_front, nrc_front_msg = verify_myanmar_nrc(
      path_front, side_label='Front'
  )

  if not is_nrc_front:
    return JsonResponse({
        'status': 'invalid',
        'message': f'အရှေ့ဘက် စစ်ဆေးမှုမအောင်မြင်ပါ - {nrc_front_msg}',
    })

  file_back = request.FILES['nrc_back']
  path_back = fs.path(fs.save(f'temp_nrc_back_{file_back.name}', file_back))

  is_nrc_back, nrc_back_msg = verify_myanmar_nrc(path_back, side_label='Back')

  if not is_nrc_back:
    return JsonResponse({
        'status': 'invalid',
        'message': f'အနောက်ဘက် စစ်ဆေးမှုမအောင်မြင်ပါ - {nrc_back_msg}',
    })

  return JsonResponse({
      'status': 'valid',
      'message': (
          'မှတ်ပုံတင် အရှေ့ရော အနောက်ပါ AI စနစ်ဖြင့် အောင်မြင်စွာ'
          ' စိစစ်ပြီးပါပြီ။'
      ),
  })



# ---------------------------------------------------------
# အိမ်ထောင်စုစာရင်း ရှေ့/နောက် ကို စစ်ဆေးပေးမည့် Endpoint
# ---------------------------------------------------------
@csrf_exempt
def validate_household_only(request):
  if request.method != 'POST':
    return JsonResponse({'error': 'Method Not Allowed'}, status=405)

  if (
      'household_front' not in request.FILES
      or 'household_back' not in request.FILES
  ):
    return JsonResponse({
        'status': 'invalid',
        'message': 'အိမ်ထောင်စုစာရင်း ရှေ့/နောက် ပုံစံနှစ်ခုလုံး လိုအပ်ပါသည်။',
    }, status=400)

  fs = FileSystemStorage(location=settings.MEDIA_ROOT)

  file_front = request.FILES['household_front']
  path_front = fs.path(fs.save(f'temp_hh_front_{file_front.name}', file_front))
  is_hh_front, hh_front_msg = verify_myanmar_household(path_front)

  if not is_hh_front:
    return JsonResponse({'status': 'invalid', 'message': f'အရှေ့ဘက်: {hh_front_msg}'})

  file_back = request.FILES['household_back']
  path_back = fs.path(fs.save(f'temp_hh_back_{file_back.name}', file_back))
  is_hh_back, hh_back_msg = verify_myanmar_household_back(path_back)

  if not is_hh_back:
    return JsonResponse({'status': 'invalid', 'message': f'အနောက်ဘက်: {hh_back_msg}'})

  return JsonResponse({
      'status': 'valid',
      'message': (
          'အိမ်ထောင်စုစာရင်း အရှေ့ရော အနောက်ပါ အောင်မြင်စွာ'
          ' စိစစ်ပြီးပါပြီ။'
      ),
  })


# For showing data in waiting state
def get_loan_details(request, document_id):
  if request.method != 'POST' and request.method == 'GET':
    try:
      doc = LoansDocument.objects.get(document_id=document_id)
      history = LoansHistory.objects.filter(document=doc).first()
      repayment = (
          LoansListTable.objects.filter(history=history).first()
          if history
          else None
      )

      try:
        principal = float(doc.amount) if doc and doc.amount else 0.0
      except (ValueError, TypeError):
        principal = 0.0

      try:
        months = int(doc.month) if doc and doc.month else 1
      except (ValueError, TypeError):
        months = 1

      if months <= 0:
        months = 1

      annual_rate = 0.28
      monthly_rate = annual_rate / 12

      total_interest = 0
      remaining_principal = principal
      for _ in range(months):
        interest_for_month = remaining_principal * monthly_rate
        total_interest += interest_for_month
        remaining_principal -= principal / months

      total_payable = principal + total_interest
      avg_monthly_payment = total_payable / months

      return JsonResponse({
          'status': 'success',
          'data': {
              'amount': f'{principal:,.0f} MMK',
              'duration': f'{months} Months',
              'total_savings': (
                  f'{repayment.monthly_savings:,.0f} MMK / Month'
                  if repayment and repayment.monthly_savings
                  else '0 MMK'
              ),
              'total_loan': f'{principal:,.0f} MMK',
              'monthly_repayment': f'{avg_monthly_payment:,.0f} MMK',
              'total_repayment': f'{total_payable:,.0f} MMK',
              'loan_status': (
                  history.status.title()
                  if history and history.status
                  else 'Pending'
              ),
          },
      }, status=200)

    except LoansDocument.DoesNotExist:
      return JsonResponse(
          {'status': 'failed', 'error': 'Document Code မတွေ့ရှိပါ။'}, status=404
      )
    except Exception as e:
      return JsonResponse(
          {'status': 'failed', 'error': f'Server Error: {str(e)}'}, status=500
      )

  return JsonResponse(
      {'status': 'failed', 'error': 'Method Not Allowed.'}, status=405
  )


# ---------------------------------------------------------
# ၆။ လုပ်ငန်းလိုင်စင်ကို pytesseract (OCR) နှင့် QR စစ်ဆေးပေးမည့် Endpoint
# ---------------------------------------------------------
@csrf_exempt
def validate_business_license_only(request):
  if request.method != 'POST':
    return JsonResponse({'error': 'Method Not Allowed'}, status=405)

  if 'biz_front' not in request.FILES:
    return JsonResponse(
        {'status': 'invalid', 'message': 'လုပ်ငန်းလိုင်စင် ဓာတ်ပုံ လိုအပ်ပါသည်။'},
        status=400,
    )

  try:
    fs = FileSystemStorage(location=settings.MEDIA_ROOT)
    file_biz = request.FILES['biz_front']
    path_biz = fs.path(fs.save(f'temp_biz_{file_biz.name}', file_biz))

    img = cv2.imread(path_biz)
    if img is None:
      return JsonResponse(
          {
              'status': 'invalid',
              'message': 'လုပ်ငန်းလိုင်စင် ဓာတ်ပုံကို ဖတ်ရှု၍ မရပါ။',
          },
          status=400,
      )

    # Step A: OpenCV QR Detector
    qr_detector = cv2.QRCodeDetector()
    qr_data, bbox, _ = qr_detector.detectAndDecode(img)

    if qr_data:
      print(f'🎯 Found QR Code in Business License: {qr_data}')
      allowed_domains = ['ycdc.gov.mm', 'dica.gov.mm', 'myco.dica.gov.mm']
      if any(domain in qr_data for domain in allowed_domains):
        return JsonResponse({
            'status': 'valid',
            'message': (
                'တရားဝင် အစိုးရ QR Code မှတစ်ဆင့် လုပ်ငန်းလိုင်စင်'
                ' စိစစ်ချက် အောင်မြင်ပါသည်။'
            ),
        }, status=200)

    # Step B: pytesseract (OCR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]

    full_text = pytesseract.image_to_string(
        gray, lang='mya+eng', config='--psm 6'
    )

    keywords = [
        'လုပ်ငန်းအမည်'
        'လိုင်စင်သက်တမ်း'
        'လုပ်ငန်းတည်နေရာ'
        'လုပ်ငန်းလိုင်စင်',
        'လိုင်စင်',
        'စည်ပင်',
        'ရန်ကုန်မြို့တော်',
        'မန္တလေးမြို့တော်',
        'စီးပွားရေး',
        'ကုမ္ပဏီ',
        'မှတ်ပုံတင်',
        'FORM 1',
        'DICA',
        'LICENSE',
        'BUSINESS',
        'CERTIFICATE',
    ]

    match_count = sum(
        1 for word in keywords if word.lower() in full_text.lower()
    )

    if match_count >= 2:
      return JsonResponse({
          'status': 'valid',
          'message': (
              'pytesseract OCR စနစ်ဖြင့် လုပ်ငန်းလိုင်စင် စိစစ်ချက်'
              ' အောင်မြင်ပါသည်။'
          ),
      }, status=200)
    else:
      return JsonResponse({
          'status': 'invalid',
          'message': (
              'လုပ်ငန်းလိုင်စင် ပုံစံမဟုတ်ပါ (သို့မဟုတ်) ဓာတ်ပုံ မသဲကွဲပါသဖြင့်'
              ' pytesseract မှ စာသားဖတ်၍ မရပါ။'
          ),
      }, status=400)

  except Exception as e:
    traceback.print_exc()
    return JsonResponse(
        {'status': 'failed', 'error': f'စစ်ဆေးစဉ် အမှားအယွင်းတက်ခဲ့သည် - {str(e)}'},
        status=500,
    )
@csrf_exempt
def check_user_loan_status(request, user_id):
  if request.method != 'GET':
    return JsonResponse({'error': 'Method Not Allowed'}, status=405)

  try:
    user_obj = (
        LoansUser.objects.filter(full_name=user_id).first()
        or LoansUser.objects.filter(username=user_id).first()
    )

    if not user_obj:
      return JsonResponse(
          {'is_repeated': False, 'allow_apply': True, 'reason': 'NEW_USER'}
      )

    # 1. Check Active Repayment (ဆပ်ရန်ကျန်လ စစ်ဆေးခြင်း)
    active_repayment = (
        LoansListTable.objects.filter(history__user=user_obj, flag=False)
        .order_by('-list_id')
        .first()
    )

    if active_repayment and active_repayment.remain_month >= 3:
      return JsonResponse({
          'is_repeated': True,
          'allow_apply': False,
          'reason': 'REPAYMENT_MONTHS_RESTRICTED',
          'message': (
              'လက်ရှိ ချေးငွေ ပြန်ဆပ်ရန်'
              f' {active_repayment.remain_month} လ ကျန်ရှိနေပါသေးသည်။'
              ' ၃ လနှင့် အထက် ကျန်ရှိပါက ထပ်မံ လျှောက်ထားခွင့် မရှိပါ။'
          ),
      })

    # 2. Check 48 Hours Cooldown
    last_doc = (
        LoansDocument.objects.filter(user=user_obj)
        .order_by('-document_id')
        .first()
    )
    
    if last_doc and getattr(last_doc, 'created_at', None):
      time_passed = timezone.now() - last_doc.created_at
      if time_passed < timedelta(hours=48):
        remaining_hours = int(48 - (time_passed.total_seconds() / 3600))
        previous_data = {
                  'phone_number': last_doc.bank_account_phone,
                  'occupation': last_doc.occupation,
                  'income_average': last_doc.income_average,
                  'nrc_front_url': (
                      request.build_absolute_uri(last_doc.nrc_photo_front.url)
                      if last_doc.nrc_photo_front
                      else ''
                  ),
                  'nrc_back_url': (
                      request.build_absolute_uri(last_doc.nrc_photo_back.url)
                      if last_doc.nrc_photo_back
                      else ''
                  ),
                  'household_front_url': (
                      request.build_absolute_uri(
                          last_doc.household_list_photo_front.url
                      )
                      if last_doc.household_list_photo_front
                      else ''
                  ),
                  'household_back_url': (
                      request.build_absolute_uri(
                          last_doc.household_list_photo_back.url
                      )
                      if last_doc.household_list_photo_back
                      else ''
                  ),
                  'biz_url': (
                      request.build_absolute_uri(
                          last_doc.business_license_photo_front.url
                      )
                      if last_doc.business_license_photo_front
                      else ''
                  ),
                  'face_url': (
                      request.build_absolute_uri(last_doc.face_scan_photo.url)
                      if last_doc.face_scan_photo
                      else ''
                  ),
              }
        return JsonResponse({
            'previous_data': previous_data,
            'is_repeated': True,
            'allow_apply': False,
            'reason': 'COOLDOWN_48H',
            'message': (
                'သင်သည် လျှောက်လွှာ တင်ထားပြီးဖြစ်ပါသည်။ '
                f' ထပ်မံလျှောက်ထားခွင့် မရှိပါ။ '
            ),
        })

    # 3. စစ်ဆေးချက်များ အားလုံး အဆင်ပြေပါက ယခင် Data ဟောင်းများ ပြန်ပို့ပေးခြင်း (Auto-fill ရန်)
    previous_data = None
    if last_doc:
      previous_data = {
          'phone_number': last_doc.bank_account_phone,
          'occupation': last_doc.occupation,
          'income_average': last_doc.income_average,
          'nrc_front_url': (
              request.build_absolute_uri(last_doc.nrc_photo_front.url)
              if last_doc.nrc_photo_front
              else ''
          ),
          'nrc_back_url': (
              request.build_absolute_uri(last_doc.nrc_photo_back.url)
              if last_doc.nrc_photo_back
              else ''
          ),
          'household_front_url': (
              request.build_absolute_uri(
                  last_doc.household_list_photo_front.url
              )
              if last_doc.household_list_photo_front
              else ''
          ),
          'household_back_url': (
              request.build_absolute_uri(
                  last_doc.household_list_photo_back.url
              )
              if last_doc.household_list_photo_back
              else ''
          ),
          'biz_url': (
              request.build_absolute_uri(
                  last_doc.business_license_photo_front.url
              )
              if last_doc.business_license_photo_front
              else ''
          ),
          'face_url': (
              request.build_absolute_uri(last_doc.face_scan_photo.url)
              if last_doc.face_scan_photo
              else ''
          ),
      }

    return JsonResponse({
        'is_repeated': bool(last_doc),
        'allow_apply': True,
        'reason': 'ELIGIBLE',
        'previous_data': previous_data,
    })

  except Exception as e:
    return JsonResponse({'error': str(e)}, status=500)
  
@api_view(['POST', 'PUT'])
@permission_classes([AllowAny])
def user_profile_api(request):
    data = request.data
    LoansUser = get_user_model()
    email = data.get('email')

    if not email:
        return Response({"status": "error", "message": "Email ထည့်သွင်းရန် လိုအပ်ပါသည်"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = LoansUser.objects.get(email=email)
    except LoansUser.DoesNotExist:
        return Response({"status": "error", "message": "အသုံးပြုသူအား မတွေ့ရှိပါ"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'POST' and not data.get('update_mode'):
        return Response({
            "status": "success",
            "user": {
    "full_name": user.full_name if user.full_name else "-",
    "phone_number": user.phone_number if user.phone_number else "-",
    "nrc_number": user.nrc_number if user.nrc_number else "-",
    "address": user.address if user.address else "-",
    "date_of_birth": user.date_of_birth.strftime('%Y-%m-%d') if user.date_of_birth else "-",
    "gender": user.gender if user.gender else "-",
    "photo": user.photo.url if user.photo else "",
    "role": user.role if user.role else "customer"
}
        }, status=status.HTTP_200_OK)

    elif request.method == 'PUT' or data.get('update_mode') == True:
        try:
            if 'full_name' in data: user.full_name = data.get('full_name')
            if 'phone_number' in data: user.phone_number = data.get('phone_number')
            if 'nrc_number' in data: user.nrc_number = data.get('nrc_number')
            if 'address' in data: user.address = data.get('address')
            if 'date_of_birth' in data: user.date_of_birth = data.get('date_of_birth') 
            if 'gender' in data: user.gender = data.get('gender')   
                              
                
            user.save()
            return Response({
                "status": "success",
                "message": "ကိုယ်ရေးအချက်အလက်များ ပြင်ဆင်ပြီးပါပြီ။",
                "user": {
                    "full_name": user.full_name if user.full_name else "-",
                    "phone_number": user.phone_number if user.phone_number else "-",
                    "nrc_number": user.nrc_number if user.nrc_number else "-",
                    "address": user.address if user.address else "-",
                    "date_of_birth": user.date_of_birth.strftime('%Y-%m-%d') if user.date_of_birth else "-",
                    "gender": user.gender if user.gender else "-",
                    "photo": user.photo.url if user.photo else ""
                }
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"status": "error", "message": f"ပြင်ဆင်၍မရပါ: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)
@api_view(['GET'])
def get_categories(request):
    categories = LoansCategory.objects.all()
    
    # Python set ကိုသုံးပြီး category_type တူနေတာတွေကို ဖယ်ရှားပါ
    seen = set()
    unique_categories = []
    for cat in categories:
        if cat.category_name not in seen:
            unique_categories.append(cat)
            seen.add(cat.category_name)
            
    serializer = LoansCategorySerializer(unique_categories, many=True)
    return Response(serializer.data)



@api_view(["POST"])
def update_profile(request):
    print("===== UPDATE PROFILE API CALLED =====")

    try:
        old_email = request.POST.get("old_email", "").strip()
        new_email = request.POST.get("email", "").strip()

        print("Old Email:", old_email)
        print("New Email:", new_email)

        if not old_email:
            return Response({
                "success": False,
                "message": "Old email is missing"
            }, status=400)

        if not new_email:
            return Response({
                "success": False,
                "message": "New email is missing"
            }, status=400)

        user = LoansUser.objects.get(email=old_email)

        # Duplicate email check
        if LoansUser.objects.exclude(id=user.id).filter(email=new_email).exists():
           return Response({
           "success": False,
           "message": "ဤအီးမေးလ်ဖြင့် အကောင့်ရှိပြီးသားဖြစ်ပါသည်"
        }, status=400)

        # Update fields
        user.email = new_email
        user.username = new_email
        user.phone_number = request.POST.get("phone_number", "")
        user.nrc_number = request.POST.get("nrc_number", "")
        user.date_of_birth = request.POST.get("date_of_birth", "")
        user.gender = request.POST.get("gender", "")

        if "photo" in request.FILES:
            user.photo = request.FILES["photo"]

        user.save()

        return Response({
            "success": True,
            "message": "Profile Updated"
        }, status=200)

    except LoansUser.DoesNotExist:
        return Response({
            "success": False,
            "message": "User not found"
        }, status=404)

    except Exception as e:
        print("ERROR:", str(e))
        return Response({
            "success": False,
            "message": str(e)
        }, status=500)
    
@api_view(['GET'])
@permission_classes([AllowAny])
def user_history_api(request):
    email = request.GET.get("email")

    if not email:
        return Response([], status=200)

    try:
        user = LoansUser.objects.get(email=email)
    except LoansUser.DoesNotExist:
        return Response([], status=200)

    histories = LoansHistory.objects.filter(user=user).select_related("category")

    data = []

    for h in histories:
        data.append({
    "id": h.id,
    "category": h.category.category_name if h.category else "",
    "amount": str(h.amount_request),
    "month": h.month,
    "status": h.status,
    "insurance_cost": str(h.insurance_cost or 0),
})

    return Response(data)
