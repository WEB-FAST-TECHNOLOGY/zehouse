import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class MessagesListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> conversations;
  final String? selectedId;
  final Function(String) onConversationTap;

  const MessagesListWidget({
    super.key,
    required this.conversations,
    required this.selectedId,
    required this.onConversationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.muted,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune conversation trouvée',
              style: GoogleFonts.outfit(fontSize: 15, color: AppTheme.muted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return _ConversationTile(
          conversation: conv,
          isSelected: selectedId == conv['id'],
          onTap: () => onConversationTap(conv['id'] as String),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = conversation['unreadCount'] as int;
    final isOnline = conversation['isOnline'] as bool;

    return Material(
      color: isSelected ? AppTheme.primary.withAlpha(13) : AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.primary.withAlpha(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: CustomImageWidget(
                      imageUrl: conversation['avatarUrl'] as String,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      semanticLabel:
                          conversation['avatarSemanticLabel'] as String,
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['contactName'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          conversation['lastMessageTime'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: unread > 0
                                ? AppTheme.primary
                                : AppTheme.muted,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Property context
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CustomImageWidget(
                            imageUrl:
                                conversation['propertyImageUrl'] as String,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            semanticLabel:
                                conversation['propertySemanticLabel'] as String,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            conversation['propertyTitle'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          conversation['propertyPrice'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['lastMessage'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: unread > 0
                                  ? AppTheme.textPrimary
                                  : AppTheme.muted,
                              fontWeight: unread > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unread.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
