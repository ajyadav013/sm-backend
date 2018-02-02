"""
Social Views
"""

from django.http import HttpResponse

from rest_framework.settings import api_settings
from rest_framework.permissions import (IsAuthenticated, )
from rest_framework.views import APIView
from rest_framework.response import Response  

from .models import SocialUser
from .serializers import (
    FacebookSerializer, LinkedInSerializer, SocialUserSerializer)

class Social(APIView):
    """
    Social View to access user's social data
    """
    authentication_classes = api_settings.DEFAULT_AUTHENTICATION_CLASSES
    permission_classes = (IsAuthenticated, )

    def post(self, request, format=None):
        try:
            social_user = SocialUser.objects.get(
                user_id=request.user.id, social_platform=request.data.get('provider'))
            return HttpResponse(social_user)
        except SocialUser.DoesNotExist:
            if request.data.get('provider') == 'facebook':
                serializer = FacebookSerializer(data={'clientId': request.data.get(
                    'clientId'), 'redirectUri': request.data.get('redirectUri'), 'code': request.data.get('code')})
            else:
                serializer = LinkedInSerializer(data={'clientId': request.data.get(
                    'clientId'), 'redirectUri': request.data.get('redirectUri'), 'code': request.data.get('code')})
            if serializer.is_valid():
                social_user = serializer.save(**{'user_id': request.user.id})
                return HttpResponse(social_user)
            else:
                return HttpResponse(False)


class SocialMeView(APIView):
    """
    User's Social Me View
    """
    authentication_classes = api_settings.DEFAULT_AUTHENTICATION_CLASSES
    permission_classes = (IsAuthenticated, )

    def get(self, request):
        serializer = SocialUserSerializer(
            request.user.socialuser.all(), many=True)
        return Response(serializer.data, status=200)
