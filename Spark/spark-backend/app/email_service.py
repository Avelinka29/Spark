import smtplib
from email.message import EmailMessage

from starlette.concurrency import run_in_threadpool

from .config import get_settings


async def send_auth_code(email: str, code: str, purpose: str) -> bool:
    settings = get_settings()
    if not all((settings.smtp_host, settings.smtp_username, settings.smtp_password)):
        return False

    subject = "Подтверждение email Spark" if purpose == "verify_email" else "Сброс пароля Spark"
    action = "подтверждения email" if purpose == "verify_email" else "сброса пароля"
    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = settings.smtp_sender or settings.smtp_username
    message["To"] = email
    message.set_content(
        f"Код для {action}: {code}\n\nКод действует 15 минут. "
        "Если вы не запрашивали его, просто проигнорируйте это письмо."
    )

    def send() -> None:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as smtp:
            smtp.starttls()
            smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(message)

    await run_in_threadpool(send)
    return True
