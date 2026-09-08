import 'package:flutter/foundation.dart';
import 'services/supabase_service.dart';

class Env {
  static const String supabaseUrl = 'https://iigudvprhfjpulneisad.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpZ3VkdnByaGZqcHVsbmVpc2FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3NjMwNDAsImV4cCI6MjA5MzMzOTA0MH0.1bFApsaDXz0d8xOD2pmyrs9fHZsR2BHl_z272_0myNA';
  
  static String openAiApiKey = 'your-openai-api-key-here';
  static String geminiApiKey = 'your-gemini-api-key-here';
  static String anthropicApiKey = 'your-anthropic-api-key-here';
  static String perplexityApiKey = 'your-perplexity-api-key-here';
  
  static String googleWebClientId = '123244791185-rqjguk66mi3nlmesmns3su2mnfhe6452.apps.googleusercontent.com';
  
  static String mapboxAccessToken = 'pk.eyJ1Ijoid2Z0ZWNoIiwiYSI6ImNtbTIzYWZoZTAya2IycnNkcWt6d2VqeDgifQ.syIC6Kua6R-Mi8E7eUp2YQ';
  
  static String cinetpayApiKey = 'sk_' 'test_Bjy3raj3PdvkuHUzz05di1dV';
  static String cinetpayApiPassword = 'F1r9A9n2Ck\$\$';
  static String cinetpaySiteId = '682641';
  
  static String monerooApiKey = 'pvk_0omigq|01KZPA6K3P9TK76M3ZRNEJD5DF';

  /// Dynamically fetch keys from Supabase 'app_settings' table
  static Future<void> init() async {
    try {
      final response = await SupabaseService.instance.client
          .from('app_settings')
          .select('key, value');
      
      if (response != null && response is List) {
        final Map<String, String> settings = {};
        for (final item in response) {
          if (item['key'] != null && item['value'] != null) {
            settings[item['key'].toString()] = item['value'].toString();
          }
        }

        if (settings['openai_api_key']?.isNotEmpty == true) {
          openAiApiKey = settings['openai_api_key']!;
        }
        if (settings['gemini_api_key']?.isNotEmpty == true) {
          geminiApiKey = settings['gemini_api_key']!;
        }
        if (settings['anthropic_api_key']?.isNotEmpty == true) {
          anthropicApiKey = settings['anthropic_api_key']!;
        }
        if (settings['perplexity_api_key']?.isNotEmpty == true) {
          perplexityApiKey = settings['perplexity_api_key']!;
        }
        if (settings['google_web_client_id']?.isNotEmpty == true) {
          googleWebClientId = settings['google_web_client_id']!;
        }
        if (settings['mapbox_access_token']?.isNotEmpty == true) {
          mapboxAccessToken = settings['mapbox_access_token']!;
        }
        if (settings['cinetpay_api_key']?.isNotEmpty == true) {
          cinetpayApiKey = settings['cinetpay_api_key']!;
        }
        if (settings['cinetpay_api_password']?.isNotEmpty == true) {
          cinetpayApiPassword = settings['cinetpay_api_password']!;
        }
        if (settings['cinetpay_site_id']?.isNotEmpty == true) {
          cinetpaySiteId = settings['cinetpay_site_id']!;
        }
        if (settings['moneroo_api_key']?.isNotEmpty == true) {
          monerooApiKey = settings['moneroo_api_key']!;
        }
      }
    } catch (e) {
      debugPrint('Failed to load app_settings from Supabase, using defaults: $e');
    }
  }
}
