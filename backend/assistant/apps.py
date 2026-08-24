import os
import sys
import threading

from django.apps import AppConfig


class AssistantConfig(AppConfig):
    name = 'assistant'

    def ready(self):
        if 'runserver' not in sys.argv or os.environ.get('RUN_MAIN') != 'true':
            return
        threading.Thread(target=self._warm_up_model, daemon=True).start()

    def _warm_up_model(self):
        from django.conf import settings
        from openai import OpenAI

        api_key = settings.OPENAI_API_KEY
        if not api_key:
            return
        try:
            client = OpenAI(api_key=api_key, base_url=settings.OPENAI_BASE_URL or None, max_retries=0)
            client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[{"role": "user", "content": "hi"}],
                max_tokens=1,
                timeout=120,
            )
        except Exception:
            pass
