import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class ConversationModel {
  final String id;
  final String participantOne;
  final String participantTwo;
  final String propertyTitle;
  final String propertyImageUrl;
  final String propertyPrice;
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  // Populated from join
  final String? contactName;
  final String? contactAvatarUrl;
  final String? contactRole;
  final bool isOnline;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.participantOne,
    required this.participantTwo,
    required this.propertyTitle,
    required this.propertyImageUrl,
    required this.propertyPrice,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    this.contactName,
    this.contactAvatarUrl,
    this.contactRole,
    this.isOnline = false,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    int unreadCount = 0,
  }) {
    final currentUid = currentUserId ?? '';
    final isParticipantOne = json['participant_one'] == currentUid;
    final otherProfile = isParticipantOne
        ? json['profile_two'] as Map<String, dynamic>?
        : json['profile_one'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] as String,
      participantOne: json['participant_one'] as String,
      participantTwo: json['participant_two'] as String,
      propertyTitle: json['property_title'] as String? ?? '',
      propertyImageUrl: json['property_image_url'] as String? ?? '',
      propertyPrice: json['property_price'] as String? ?? '',
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageAt: DateTime.parse(
        json['last_message_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      contactName: otherProfile?['full_name'] as String?,
      contactAvatarUrl: otherProfile?['avatar_url'] as String?,
      contactRole: otherProfile?['role'] as String?,
      isOnline: otherProfile?['is_online'] as bool? ?? false,
      unreadCount: unreadCount,
    );
  }

  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'contactName': contactName ?? 'Utilisateur',
      'contactRole': contactRole ?? 'Membre',
      'avatarUrl': contactAvatarUrl ?? '',
      'avatarSemanticLabel':
          'Photo de profil de ${contactName ?? 'utilisateur'}',
      'propertyTitle': propertyTitle,
      'propertyImageUrl': propertyImageUrl,
      'propertySemanticLabel': 'Image de $propertyTitle',
      'lastMessage': lastMessage,
      'lastMessageTime': _formatTime(lastMessageAt),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'propertyPrice': propertyPrice,
    };
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toDisplayMap(String currentUserId) {
    final isMe = senderId == currentUserId;
    return {
      'id': id,
      'text': content,
      'isMe': isMe,
      'time':
          '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
      'isRead': isRead,
    };
  }
}

class MessagingService {
  static MessagingService? _instance;
  static MessagingService get instance => _instance ??= MessagingService._();
  MessagingService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // Fetch all conversations for current user with unread counts
  Future<List<ConversationModel>> fetchConversations() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final data = await _client
        .from('conversations')
        .select('''
          *,
          profile_one:user_profiles!conversations_participant_one_fkey(full_name, avatar_url, role, is_online),
          profile_two:user_profiles!conversations_participant_two_fkey(full_name, avatar_url, role, is_online)
        ''')
        .or('participant_one.eq.$uid,participant_two.eq.$uid')
        .order('last_message_at', ascending: false);

    final List<ConversationModel> conversations = [];
    for (final row in data as List) {
      final unread = await _countUnread(row['id'] as String);
      conversations.add(
        ConversationModel.fromJson(
          row as Map<String, dynamic>,
          currentUserId: uid,
          unreadCount: unread,
        ),
      );
    }
    return conversations;
  }

  Future<int> _countUnread(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return 0;
    try {
      final response = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('is_read', false)
          .neq('sender_id', uid);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  // Fetch messages for a conversation
  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  // Send a message
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final data = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': uid,
          'content': content,
          'is_read': false,
        })
        .select()
        .single();

    return MessageModel.fromJson(data);
  }

  // Mark messages as read
  Future<void> markMessagesRead(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', uid)
        .eq('is_read', false);
  }

  // Subscribe to new messages in a conversation
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(MessageModel) onMessage,
  ) {
    return _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final msg = MessageModel.fromJson(payload.newRecord);
            onMessage(msg);
          },
        )
        .subscribe();
  }

  // Subscribe to conversation list updates
  RealtimeChannel subscribeToConversations(void Function() onUpdate) {
    final uid = currentUserId;
    return _client
        .channel('conversations:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  // Create or get existing conversation
  Future<String?> getOrCreateConversation({
    required String otherUserId,
    required String propertyTitle,
    required String propertyImageUrl,
    required String propertyPrice,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    // Check if conversation already exists (either direction)
    final existing = await _client
        .from('conversations')
        .select('id')
        .or(
          'and(participant_one.eq.$uid,participant_two.eq.$otherUserId),and(participant_one.eq.$otherUserId,participant_two.eq.$uid)',
        )
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create new conversation
    final data = await _client
        .from('conversations')
        .insert({
          'participant_one': uid,
          'participant_two': otherUserId,
          'property_title': propertyTitle,
          'property_image_url': propertyImageUrl,
          'property_price': propertyPrice,
          'last_message': '',
        })
        .select('id')
        .single();

    return data['id'] as String;
  }
}
