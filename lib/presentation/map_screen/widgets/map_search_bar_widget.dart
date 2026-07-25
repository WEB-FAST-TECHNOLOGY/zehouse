import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MapSearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final VoidCallback? onTap;
  final VoidCallback? onBack;

  const MapSearchBarWidget({
    super.key,
    required this.onSearch,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.onTap,
    this.onBack,
  });

  @override
  State<MapSearchBarWidget> createState() => _MapSearchBarWidgetState();
}

class _MapSearchBarWidgetState extends State<MapSearchBarWidget> {
  final _controller = TextEditingController();
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: _hasFocus ? AppTheme.primary : AppTheme.border,
          width: _hasFocus ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          widget.onBack != null
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: widget.onBack,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: _hasFocus ? AppTheme.primary : AppTheme.muted,
                    ),
                  ],
                ),
          const SizedBox(width: 10),
          Expanded(
            child: widget.onTap != null
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onTap,
                    child: IgnorePointer(
                      child: TextField(
                        controller: _controller,
                        readOnly: true,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ville, quartier, adresse…',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 15,
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
                  )
                : Focus(
                    onFocusChange: (f) => setState(() => _hasFocus = f),
                    child: TextField(
                      controller: _controller,
                      onChanged: widget.onSearch,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ville, quartier, adresse…',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 15,
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
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onSearch('');
              },
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppTheme.muted,
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: widget.hasActiveFilters
                        ? AppTheme.primary.withAlpha(230)
                        : AppTheme.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                if (widget.hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE85D4A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
