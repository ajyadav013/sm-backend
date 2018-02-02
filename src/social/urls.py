"""
urls for social
"""

from django.conf.urls import (url)
from .views import (Social, SocialMeView)

urlpatterns = [
    url(r'me', SocialMeView.as_view(), name='socialuser_me'),
    url(r'', Social.as_view(), name='social')
    
]
