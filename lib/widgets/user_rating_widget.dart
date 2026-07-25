import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// Reusable widget to display and submit ratings for any user
/// (landlord, agent, tenant, etc.) using the user_ratings table.
class UserRatingWidget extends StatefulWidget {
  final String ratedUserId;
  final String ratedUserName;
  final String context; // 'landlord', 'agent', 'tenant', etc.
  final String? listingId;

  const UserRatingWidget({
    super.key,
    required this.ratedUserId,
    required this.ratedUserName,
    required this.context,
    this.listingId,
  });

  @override
  State<UserRatingWidget> createState() => _UserRatingWidgetState();
}

class _UserRatingWidgetState extends State<UserRatingWidget> {
  List<Map<String, dynamic>> _ratings = [];
  bool _isLoading = true;
  double _averageRating = 0;
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final data = await Supabase.instance.client
          .from('user_ratings')
          .select('*, rater:rater_id(full_name, avatar_url)')
          .eq('rated_user_id', widget.ratedUserId)
          .order('created_at', ascending: false)
          .limit(10);

      final ratings = List<Map<String, dynamic>>.from(data);
      double avg = 0;
      if (ratings.isNotEmpty) {
        avg =
            ratings.fold<double>(
              0,
              (sum, r) => sum + (r['rating'] as num).toDouble(),
            ) /
            ratings.length;
      }

      bool hasRated = false;
      if (currentUser != null) {
        hasRated = ratings.any((r) => r['rater_id'] == currentUser.id);
      }

      if (mounted) {
        setState(() {
          _ratings = ratings;
          _averageRating = avg;
          _hasRated = hasRated;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRatingDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connectez-vous pour laisser un avis',
            style: GoogleFonts.outfit(fontSize: 13),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    int selectedRating = _hasRated ? 5 : 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Évaluer ${widget.ratedUserName}',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _contextLabel(widget.context),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Star selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          i < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          key: ValueKey('$i-${i < selectedRating}'),
                          size: 40,
                          color: i < selectedRating
                              ? const Color(0xFFF59E0B)
                              : AppTheme.border,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _ratingLabel(selectedRating),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Comment field
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 300,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience (optionnel)...',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.muted,
                  ),
                  counterStyle: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.muted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            await Supabase.instance.client
                                .from('user_ratings')
                                .upsert({
                                  'rated_user_id': widget.ratedUserId,
                                  'rater_id': user.id,
                                  'rating': selectedRating,
                                  'comment':
                                      commentController.text.trim().isEmpty
                                      ? null
                                      : commentController.text.trim(),
                                  'context': widget.context,
                                  'listing_id': widget.listingId,
                                }, onConflict: 'rated_user_id,rater_id');
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadRatings();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Votre avis a été publié !',
                                    style: GoogleFonts.outfit(fontSize: 13),
                                  ),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            setModalState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Publier mon avis',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _contextLabel(String ctx) {
    switch (ctx) {
      case 'landlord':
        return 'Évaluation du bailleur';
      case 'agent':
        return 'Évaluation de l\'agent immobilier';
      case 'tenant':
        return 'Évaluation du locataire';
      default:
        return 'Évaluation';
    }
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Avis & Évaluations',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showRatingDialog,
                icon: Icon(
                  _hasRated ? Icons.edit_rounded : Icons.rate_review_outlined,
                  size: 16,
                ),
                label: Text(
                  _hasRated ? 'Modifier' : 'Évaluer',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          if (_averageRating > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < _averageRating;
                        final half =
                            !filled &&
                            i < _averageRating + 0.5 &&
                            _averageRating % 1 >= 0.3;
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : half
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: const Color(0xFFF59E0B),
                        );
                      }),
                    ),
                    Text(
                      '${_ratings.length} avis',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_ratings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 36,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun avis pour le moment.\nSoyez le premier à évaluer !',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_ratings.take(3).map((r) => _RatingCard(rating: r))),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final Map<String, dynamic> rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final rater = rating['rater'] as Map<String, dynamic>?;
    final name = rater?['full_name'] as String? ?? 'Utilisateur';
    final stars = (rating['rating'] as num?)?.toInt() ?? 0;
    final comment = rating['comment'] as String? ?? '';
    final createdAt = rating['created_at'] as String?;

    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withAlpha(30),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 13,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
