import os
import smtplib
from email.message import EmailMessage


def _smtp_configured():
    smtp_host = os.getenv("SMTP_HOST")
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")

    return bool(smtp_host and smtp_user and smtp_password)


def _send_email(to_email, subject, body):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    smtp_from = os.getenv("SMTP_FROM", smtp_user or "no-reply@smarttooth.app")
    use_tls = os.getenv("SMTP_USE_TLS", "true").lower() != "false"

    if not _smtp_configured():
        print("SMTP no configurado: no se pudo enviar el correo")
        return False

    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = smtp_from
    message["To"] = to_email
    message.set_content(body)

    try:
        with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
            if use_tls:
                server.starttls()
            server.login(smtp_user, smtp_password)
            server.send_message(message)
        return True
    except Exception as e:
        print("SEND EMAIL ERROR:", e)
        return False


def send_welcome_email(to_email, name):
    body = "\n".join([
        f"Hola {name},",
        "",
        "Tu cuenta en SmartTooth fue creada correctamente.",
        "Ya puedes iniciar sesión y gestionar tus citas dentales.",
        "",
        "Si no creaste esta cuenta, comunícate con soporte.",
        "",
        "SmartTooth",
    ])

    return _send_email(
        to_email,
        "Bienvenido a SmartTooth",
        body,
    )


def send_password_reset_code(to_email, code):
    if not _smtp_configured():
        if os.getenv("SMTP_DEBUG_CODE", "false").lower() == "true":
            print(f"PASSWORD RESET CODE for {to_email}: {code}")
            return True

        print("SMTP no configurado: no se pudo enviar el código de seguridad")
        return False

    body = "\n".join([
        "Hola,",
        "",
        "Recibimos una solicitud para cambiar la contraseña de tu cuenta SmartTooth.",
        f"Tu código de seguridad es: {code}",
        "",
        "Este código vence en 10 minutos. Si no solicitaste este cambio, ignora este correo.",
        "",
        "SmartTooth",
    ])

    return _send_email(
        to_email,
        "Código de seguridad SmartTooth",
        body,
    )
