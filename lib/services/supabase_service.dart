import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

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
