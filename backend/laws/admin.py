from django.contrib import admin
from .models import Category, Law, LegalSection


admin.site.register(Category)
admin.site.register(Law)
admin.site.register(LegalSection)