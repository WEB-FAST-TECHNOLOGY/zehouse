import 'package:flutter/material.dart';
import '../presentation/map_screen/map_screen.dart';
import '../presentation/property_detail_screen/property_detail_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/publish_listing_screen/publish_listing_screen.dart';
import '../presentation/messages_screen/messages_screen.dart';
import '../presentation/my_listings_screen/my_listings_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/nearby_services_screen/nearby_services_screen.dart';
import '../presentation/professionals_screen/professionals_screen.dart';
import '../presentation/subscription_plans_screen/subscription_plans_screen.dart';
import '../presentation/language_selection_screen/language_selection_screen.dart';
import '../presentation/terms_screen/terms_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/location_request_screen/location_request_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String mapScreen = '/map-screen';
  static const String propertyDetailScreen = '/property-detail-screen';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String publishListingScreen = '/publish-listing-screen';
  static const String messagesScreen = '/messages-screen';
  static const String myListingsScreen = '/my-listings-screen';
  static const String profileScreen = '/profile-screen';
  static const String nearbyServicesScreen = '/nearby-services-screen';
  static const String professionalsScreen = '/professionals-screen';
  static const String subscriptionPlansScreen = '/subscription-plans-screen';
  static const String languageSelectionScreen = '/language-selection-screen';
  static const String termsScreen = '/terms-screen';
  static const String locationRequestScreen = '/location-request-screen';
 
  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    mapScreen: (context) => const MapScreen(),
    propertyDetailScreen: (context) => const PropertyDetailScreen(),
    signUpLoginScreen: (context) => const SignUpLoginScreen(),
    publishListingScreen: (context) => const PublishListingScreen(),
    messagesScreen: (context) => const MessagesScreen(),
    myListingsScreen: (context) => const MyListingsScreen(),
    profileScreen: (context) => const ProfileScreen(),
    nearbyServicesScreen: (context) => const NearbyServicesScreen(),
    professionalsScreen: (context) => const ProfessionalsScreen(),
    subscriptionPlansScreen: (context) => const SubscriptionPlansScreen(),
    languageSelectionScreen: (context) =>
        const LanguageSelectionScreen(isFromSettings: true),
    termsScreen: (context) => const TermsScreen(),
    locationRequestScreen: (context) => const LocationRequestScreen(),
  };
}
