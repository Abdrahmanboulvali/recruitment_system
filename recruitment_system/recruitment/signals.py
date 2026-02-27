from django.db.models.signals import post_save
from django.dispatch import receiver
from django.core.mail import send_mail
from django.conf import settings
from .models import User


@receiver(post_save, sender=User)
def send_otp_on_signup(sender, instance, created, **kwargs):
    # نرسل الرمز فقط عند إنشاء حساب جديد ويكون غير نشط
    if created and not instance.is_active:
        otp = instance.generate_otp()  # توليد الرمز الذي أضفناه في الموديل
        subject = 'Vérification de votre compte'
        message = f'Votre code de vérification est : {otp}'
        email_from = settings.EMAIL_HOST_USER
        recipient_list = [instance.email]

        try:
            send_mail(subject, message, email_from, recipient_list)
            print(f"DEBUG: OTP {otp} sent to {instance.email}")
        except Exception as e:
            print(f"ERROR sending email: {e}")