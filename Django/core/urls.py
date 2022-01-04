# core/urls.py
from django.urls import path

from . import views

urlpatterns = [
    # path('', views.home, name='home'),
    path('', views.main_page, name='mainPage'),
    path('mainpage/', views.main_page, name='mainPage'),
    path('register/', views.register, name='registerPage'),
    path('login/', views.login, name='loginPage'),
    path('logout/', views.logout_view, name='logout'),
    path('user-page/', views.user_page, name='userPage'),
    path('ajax/validate_username/',
         views.validate_username, name='validate_username')



]
