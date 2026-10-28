import os
from pathlib import Path
from datetime import timedelta

# Project ရဲ့ Base Directory သတ်မှတ်ချက်
BASE_DIR = Path(__file__).resolve().parent.parent

# 🚨 လုံခြုံရေးအတွက် Secret Key
SECRET_KEY = 'django-insecure-your-custom-secret-key-here'

# Debug mode ကို Development လုပ်နေစဉ် True ပေးထားပါသည်
DEBUG = True

# 🚨 Flutter App သို့မဟုတ် မည်သည့် IP ကမဆို လှမ်းခေါ်ခွင့်ပြုရန် "*" ပေးထားပါသည်
ALLOWED_HOSTS = ['*']

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'ngrok-skip-browser-warning', # 👈 ဒီ Header ကို ခွင့်ပြုပေးရန် မဖြစ်မနေ လိုအပ်ပါသည်
]
# ============================================================
# ၁။ INSTALLED_APPS (အသစ်သွင်းထားသော Library များနှင့် သင့် App ကို ချိတ်ဆက်ခြင်း)
# ============================================================
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Third-Party Libraries (ကျွန်တော်တို့ အသစ်သွင်းထားသော Package များ)
    'rest_framework',
    'corsheaders',
    
    # သင့်ရဲ့ ချေးငွေ App နာမည်ကို ဤနေရာတွင် စနစ်တကျ ထည့်သွင်းထားပါသည်
    'loan_api'
     '', 
]
AUTH_USER_MODEL = 'loan_api.LoansUser'
# ============================================================
# ၂။ MIDDLEWARE (CorsMiddleware ကို ထိပ်ဆုံးတွင် ထားရပါမည်)
# ============================================================
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # 🚨 CORS ကာကွယ်မှုအတွက် ထိပ်ဆုံးတွင် ရှိရမည်
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# 🚨 ဂျန်ဂိုကို အစက် (.) လေးခံပြီး ဆောက်ခဲ့သည့်အတွက် ရိုးရှင်းစွာ 'loan_project' ဟုပဲ သတ်မှတ်ပါသည်
ROOT_URLCONF = 'loan_project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'loan_project.wsgi.application'


# ============================================================
# ၃။ DATABASE (ချေးငွေ App အစမ်းသုံးရန် SQLite ကို အသုံးပြုထားပါသည်)
# ============================================================
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}


# Password Validation (စကားဝှက် လုံခြုံရေးသတ်မှတ်ချက်များ)
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]


# နိုင်ငံတကာ စံတော်ချိန် သတ်မှတ်ချက် (မြန်မာစံတော်ချိန်အတွက် ပြင်ထားပါသည်)
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Yangon'  # ဗမာပြည်စံတော်ချိန် ပြောင်းထားပါသည်
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

BASE_DIR=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760 
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760

# ============================================================
# ၄။ PROJECT ရဲ့ အဓိက ကွက်တိပြင်ဆင်ချက်များ 🚨
# ============================================================

# က။ Custom User Model ချိတ်ဆက်ခြင်း
# "loan_api" အောက်က "User" Table ကို အဓိက သုံးမည်ဟု Django ကို ပြောခြင်းဖြစ်ပါသည်


# ခ။ CORS သတ်မှတ်ချက်
# Flutter App ကနေ Django API ဆီကို Data လှမ်းပို့တဲ့အခါ Block မဖြစ်အောင် ခွင့်ပြုပေးတာပါ
CORS_ALLOW_ALL_ORIGINS = True 

# ဂ။ 📧 GMAIL SMTP သုံးပြီး Flutter ထံ OTP လှမ်းပို့မည့် စနစ်သတ်မှတ်ချက်
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'thanswetint12@gmail.com'         # 🚨 သင့် Gmail အစစ် ပြောင်းထည့်ပါ
EMAIL_HOST_PASSWORD = 'uznbnzfmzzxchsjq'  # 🚨 သင့် Google App Password ၁၆ လုံး ထည့်ပါ



REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    )
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1), # စမ်းသပ်ရလွယ်ကူအောင် Token သက်တမ်း ၁ ရက် ပေးထားပါသည်
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
}
# MIGRATION_MODULES = {
#     'loan_api': None,
# }