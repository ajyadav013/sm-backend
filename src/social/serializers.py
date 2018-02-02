"""
Social user serializer
"""
from rest_framework import serializers
from django.conf import settings
from django.contrib.auth.models import User

import requests

from .models import (SocialUser, )


class FacebookSerializer(serializers.Serializer):
    """
    Facebook to get access key and data of user
    """
    clientId = serializers.CharField(max_length=200)
    redirectUri = serializers.CharField(max_length=200)
    code = serializers.CharField(max_length=2000)

    def validate(self, data):
        url = 'https://graph.facebook.com/v2.10/oauth/access_token?client_id={0}&redirect_uri={1}&client_secret={2}&code={3}'.format(
            data.get('clientId'), data.get('redirectUri'), settings.FACEBOOK_APP_SECRET, data.get('code'))
        response = requests.get(url)
        try:
            access_token = response.json()['access_token']
        except:
            raise serializers.ValidationError('Incorrect access token')

        user_details_url = "https://graph.facebook.com/me?fields=id, name&access_token={}".format(
            access_token)
        user_details_response = requests.get(user_details_url)
        user_details = user_details_response.json()
        return user_details

    def create(self, validated_data):
        user = User.objects.get(id=validated_data['user_id'])
        User_details = SocialUser.objects.create(
            user=user, name=validated_data['name'], social_platform='facebook', social_platform_user_id=validated_data['id'])
        return User_details


class LinkedInSerializer(serializers.Serializer):
    """
    LinkedIn to get access key and data of user
    """
    clientId = serializers.CharField(max_length=200)
    redirectUri = serializers.CharField(max_length=200)
    code = serializers.CharField(max_length=2000)

    def validate(self, data):
        url = "https://www.linkedin.com/uas/oauth2/accessToken?grant_type=authorization_code&code={0}&redirect_uri={1}&client_id={2}&client_secret={3}&scope=r_emailaddress".format(
            data.get('code'), data.get('redirectUri'), data.get('clientId'), settings.LINKEDIN_APP_SECRET)
        response = requests.get(url)
        try:
            access_token = response.json()['access_token']
        except:
            raise serializers.ValidationError('Incorrect access token')
        headers = {'Authorization': 'Bearer ' + access_token}
        user_details_url = "https://api.linkedin.com/v1/people/~?format=json"
        user_details_response = requests.get(user_details_url, headers=headers)
        user_details = user_details_response.json()
        return user_details

    def create(self, validated_data):
        user = User.objects.get(id=validated_data['user_id'])
        User_details = SocialUser.objects.create(
            user=user, name=validated_data['firstName'], social_platform='linkedin', social_platform_user_id=validated_data['id'])
        return User_details


class SocialUserSerializer(serializers.ModelSerializer):
    """
    Serializer social user.
    """
    class Meta:
        model = SocialUser
        fields = ('id', 'name', 'social_platform',
                  'social_platform_user_id', 'user')
