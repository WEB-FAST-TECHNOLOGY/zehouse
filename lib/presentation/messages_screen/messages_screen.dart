import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../core/app_export.dart';
import '../../services/messaging_service.dart';
import './widgets/chat_view_widget.dart';
import './widgets/messages_list_widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _currentNavIndex = 3;
  String? _selectedConversationId;
  String _searchQuery = '';

  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _error;

  RealtimeChannel? _conversationsChannel;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToConversations();
  }

  @override
  void dispose() {
    _conversationsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final convs = await MessagingService.instance.fetchConversations();
      if (mounted) {
        setState(() {
          _conversations = convs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les conversations.';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToConversations() {
    _conversationsChannel = MessagingService.instance.subscribeToConversations(
      () {
        _loadConversations();
      },
    );
  }

  List<Map<String, dynamic>> get _filteredConversationMaps {
    final maps = _conversations.map((c) => c.toDisplayMap()).toList();
    if (_searchQuery.isEmpty) return maps;
    final q = _searchQuery.toLowerCase();
    return maps
        .where(
          (c) =>
              (c['contactName'] as String).toLowerCase().contains(q) ||
              (c['propertyTitle'] as String).toLowerCase().contains(q),
        )
        .toList();
  }

  Map<String, dynamic>? _getConversationMap(String id) {
    try {
      final conv = _conversations.firstWhere((c) => c.id == id);
      return conv.toDisplayMap();
    } catch (_) {
      return null;
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mapScreen,
          (r) => false,
        );
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mapScreen,
          (r) => false,
        );
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.publishListingScreen);
        break;
      case 3:
        // Already on Messages screen — do nothing
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.myListingsScreen);
        break;
      case 5:
        Navigator.pushNamed(context, AppRoutes.profileScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildPhoneLayout() {
    if (_selectedConversationId != null) {
      final conv = _getConversationMap(_selectedConversationId!);
      if (conv != null) {
        return ChatViewWidget(
          conversation: conv,
          conversationId: _selectedConversationId!,
          onBack: () => setState(() => _selectedConversationId = null),
        );
      }
    }
    return _buildConversationList();
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        SizedBox(width: 340, child: _buildConversationList()),
        Container(width: 1, color: AppTheme.border),
        Expanded(
          child: _selectedConversationId != null
              ? Builder(
                  builder: (context) {
                    final conv = _getConversationMap(_selectedConversationId!);
                    if (conv == null) return _buildEmptyChatState();
                    return ChatViewWidget(
                      conversation: conv,
                      conversationId: _selectedConversationId!,
                      onBack: () =>
                          setState(() => _selectedConversationId = null),
                      isTabletPanel: true,
                    );
                  },
                )
              : _buildEmptyChatState(),
        ),
      ],
    );
  }

  Widget _buildConversationList() {
    final totalUnread = _conversations.fold<int>(
      0,
      (sum, c) => sum + c.unreadCount,
    );

    return Column(
      children: [
        // App bar
        SafeArea(
          bottom: false,
          child: Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Messages',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                        if (totalUnread > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  totalUnread > 9
                                      ? '9+'
                                      : totalUnread.toString(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rechercher une conversation…',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.muted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadConversations,
                        child: Text(
                          'Réessayer',
                          style: GoogleFonts.outfit(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                )
              : MessagesListWidget(
                  conversations: _filteredConversationMaps,
                  selectedId: _selectedConversationId,
                  onConversationTap: (id) =>
                      setState(() => _selectedConversationId = id),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez une conversation',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vos échanges avec les agents et propriétaires apparaissent ici.',
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
