import os

import requests


BREVO_EMAIL_URL = "https://api.brevo.com/v3/smtp/email"


def _app_name():
    return os.getenv("FRONTEND_APP_NAME", "SmartTooth")


def _brevo_configured():
    return bool(
        os.getenv("BREVO_API_KEY")
        and os.getenv("BREVO_SENDER_EMAIL")
    )


def _debug_reset_code_enabled():
    return (
        os.getenv("DEBUG_RESET_CODE", "false").lower() == "true"
        or os.getenv("SMTP_DEBUG_CODE", "false").lower() == "true"
    )


def _send_brevo_email(to_email, subject, text_content, html_content=None):
    api_key = os.getenv("BREVO_API_KEY")
    sender_email = os.getenv("BREVO_SENDER_EMAIL")
    sender_name = os.getenv("BREVO_SENDER_NAME", _app_name())

    if not _brevo_configured():
        print("Brevo no configurado: faltan BREVO_API_KEY o BREVO_SENDER_EMAIL")
        return False

    payload = {
        "sender": {
            "name": sender_name,
            "email": sender_email,
        },
        "to": [{"email": to_email}],
        "subject": subject,
        "textContent": text_content,
    }

    if html_content:
        payload["htmlContent"] = html_content

    try:
        response = requests.post(
            BREVO_EMAIL_URL,
            headers={
                "accept": "application/json",
                "api-key": api_key,
                "content-type": "application/json",
            },
            json=payload,
            timeout=15,
        )

        if 200 <= response.status_code < 300:
            return True

        print("BREVO EMAIL ERROR:", response.status_code, response.text[:300])
        return False
    except Exception as exc:
        print("BREVO EMAIL EXCEPTION:", exc)
        return False


def send_welcome_email(to_email, name):
    app_name = _app_name()
    subject = f"Bienvenido a {app_name}"
    text = "\n".join([
        f"Hola {name},",
        "",
        f"Tu cuenta en {app_name} fue creada correctamente.",
        "Ya puedes iniciar sesión y gestionar tus citas dentales.",
        "",
        "Si no creaste esta cuenta, comunícate con soporte.",
        "",
        app_name,
    ])
    html = f"""
    <p>Hola {name},</p>
    <p>Tu cuenta en <strong>{app_name}</strong> fue creada correctamente.</p>
    <p>Ya puedes iniciar sesión y gestionar tus citas dentales.</p>
    <p>Si no creaste esta cuenta, comunícate con soporte.</p>
    <p>{app_name}</p>
    """

    return _send_brevo_email(to_email, subject, text, html)


def send_password_reset_code(to_email, code):
    app_name = _app_name()

    if not _brevo_configured():
        if _debug_reset_code_enabled():
            print(f"PASSWORD RESET CODE for {to_email}: {code}")
            return True
        print("Brevo no configurado: no se pudo enviar el código de seguridad")
        return False

    subject = f"Código de recuperación - {app_name}"
    text = "\n".join([
        "Hola,",
        "",
        f"Recibimos una solicitud para cambiar la contraseña de tu cuenta {app_name}.",
        f"Tu código de seguridad es: {code}",
        "",
        "Este código vence en 10 minutos.",
        "Si no solicitaste este cambio, ignora este correo.",
        "",
        app_name,
    ])
    html = f"""
    <p>Hola,</p>
    <p>Recibimos una solicitud para cambiar la contraseña de tu cuenta <strong>{app_name}</strong>.</p>
    <p>Tu código de seguridad es:</p>
    <p style="font-size:24px;font-weight:700;letter-spacing:4px;">{code}</p>
    <p>Este código vence en <strong>10 minutos</strong>.</p>
    <p>Si no solicitaste este cambio, ignora este correo.</p>
    <p>{app_name}</p>
    """

    return _send_brevo_email(to_email, subject, text, html)
