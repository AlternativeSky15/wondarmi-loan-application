# serializers.py
from rest_framework import serializers
from .models import LoansUser, LoansCategory, PaymentRequest

# 💡 ပုံ URL အပြည့်အစုံရရှိစေမယ့် UserSerializer
class UserSerializer(serializers.ModelSerializer):
    # photo field ကို method field အနေဖြင့် သတ်မှတ်ခြင်း
    photo = serializers.SerializerMethodField()

    class Meta:
        model = LoansUser
        fields = ['full_name', 'phone_number', 'nrc_number', 'address', 'date_of_birth', 'gender', 'photo', 'role']

    def get_photo(self, obj):
        # request ကို context မှရယူ၍ absolute URL တည်ဆောက်ခြင်း
        request = self.context.get('request')
        if obj.photo and hasattr(obj.photo, 'url'):
            if request:
                return request.build_absolute_uri(obj.photo.url)
            return obj.photo.url
        return None

class LoansCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LoansCategory
        fields = ['category_id', 'category_name', 'category_type', 'image', 'interest_rate']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6, style={'input_type': 'password'})

    class Meta:
        model = LoansUser
        fields = ['username', 'email', 'password', 'full_name', 'nrc_number', 'phone_number', 'address', 'role']

    def validate_email(self, value):
        if LoansUser.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email is already registered.")
        return value

    def create(self, validated_data):
        user = LoansUser.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email'),
            password=validated_data['password'],
            full_name=validated_data.get('full_name'),
            nrc_number=validated_data.get('nrc_number'),
            phone_number=validated_data.get('phone_number'),
            address=validated_data.get('address'),
            role=validated_data.get('role', 'customer')
        )
        return user
class PaymentRequestSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()
    customer_phone = serializers.SerializerMethodField()
    customer_email = serializers.SerializerMethodField()
    loan_id = serializers.IntegerField(source='loan.id', read_only=True)

    class Meta:
        model = PaymentRequest
        fields = [
            'id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'loan_id',
            'bank_account_or_phone',
            'payment_method',
            'transaction_id',
            'amount',
            'transfer_date',
            'payment_image',
            'status',
            'admin_remark',
            'created_at',
            'approved_at',
        ]

    def get_customer_name(self, obj):
        if obj.customer:
            return getattr(obj.customer, 'full_name', None) or obj.customer.username
        return "-"

    def get_customer_phone(self, obj):
        if obj.customer:
            return getattr(obj.customer, 'phone_number', '-')
        return "-"

    def get_customer_email(self, obj):
        if obj.customer:
            return obj.customer.email
        return "-" 