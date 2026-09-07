import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../env.dart';
import './language_service.dart';
import './currency_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static final String supabaseUrl = Env.supabaseUrl;
  static final String supabaseAnonKey = Env.supabaseAnonKey;

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    debugPrint('=== Supabase Service Init ===');
    debugPrint('  SUPABASE_URL: "$supabaseUrl"');
    debugPrint(
      '  SUPABASE_ANON_KEY: "${supabaseAnonKey.isNotEmpty ? 'loaded' : 'empty'}"',
    );

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      httpClient: LoggingHttpClient(),
    );
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Sync user preferences (language & currency) from Supabase
  static Future<void> syncUserPreferences(BuildContext context) async {
    try {
      final user = instance.client.auth.currentUser;
      if (user == null) return;

      final data = await instance.client
          .from('user_profiles')
          .select('language_code, currency_code')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final langCode = data['language_code'] as String?;
        if (langCode != null && langCode.isNotEmpty) {
          if (context.mounted) {
            LanguageService.instance.setContext(context);
          }
          await LanguageService.instance.setLanguage(langCode);
        }

        final currCode = data['currency_code'] as String?;
        if (currCode != null && currCode.isNotEmpty) {
          await CurrencyService.instance.setCurrency(currCode);
        }
      }
    } catch (e) {
      debugPrint('Failed to sync user preferences: $e');
    }
  }
}

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('--> [Supabase Request] $timestamp');
    debugPrint('    Method: ${request.method}');
    debugPrint('    URL: ${request.url}');
    debugPrint('    Headers: ${request.headers}');

    if (request is http.Request && request.body.isNotEmpty) {
      debugPrint('    Body: ${request.body}');
    }

    try {
      final response = await _inner.send(request);
      debugPrint('<-- [Supabase Response] Status: ${response.statusCode}');

      final bytes = await response.stream.toBytes();
      try {
        final decoded = utf8.decode(bytes);
        debugPrint('    Body: $decoded');
      } catch (e) {
        debugPrint(
          '    Body: (binary or non-UTF8 data, ${bytes.length} bytes)',
        );
      }

      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error) {
      debugPrint('[Supabase Error]: $error');
      rethrow;
    }
  }
}
