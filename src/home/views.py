from django.shortcuts import render
from django.views.generic import TemplateView

from rest_framework.settings import api_settings
from rest_framework.permissions import (IsAuthenticated, )

class Home(TemplateView):
    authentication_classes = api_settings.DEFAULT_AUTHENTICATION_CLASSES
    permission_classes = (IsAuthenticated, )
    template_name = 'home.html'
    
