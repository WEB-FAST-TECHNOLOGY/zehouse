import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFromSettings;
  const LanguageSelectionScreen({super.key, this.isFromSettings = false});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCode = '';

  List<String> get _regions => [
    'Tout',
    tr('language_europe'),
    tr('language_africa'),
    tr('language_asia'),
    tr('language_middle_east'),
  ];

  // Internal region keys for LanguageService lookup (always French keys)
  static const List<String> _regionKeys = [
    'Tout',
    'Europe',
    'Afrique',
    'Asie',
    'Moyen-Orient',
  ];

  final Map<String, String> _regionEmojis = {
    'Tout': '🌐',
    'Europe': '🇪🇺',
    'Afrique': '🌍',
    'Asie': '🌏',
    'Moyen-Orient': '🌙',
  };
  final Map<String, int> _regionCounts = {
    'Tout': 105,
    'Europe': 36,
    'Afrique': 19,
    'Asie': 30,
    'Moyen-Orient': 20,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedCode = LanguageService.instance.currentCode;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LanguageService.instance.setContext(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<LanguageModel> _getLanguagesForTab(int tabIndex) {
    final regionKey = _regionKeys[tabIndex];
    List<LanguageModel> list;
    if (regionKey == 'Tout') {
      list = LanguageService.allLanguages;
    } else {
      list = LanguageService.byRegion[regionKey] ?? [];
    }
    if (_searchQuery.isEmpty) return list;
    return list.where((l) {
      return l.name.toLowerCase().contains(_searchQuery) ||
          l.nativeName.toLowerCase().contains(_searchQuery) ||
          l.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _selectLanguage(LanguageModel lang) async {
    setState(() => _selectedCode = lang.code);
    LanguageService.instance.setContext(context);
    await LanguageService.instance.setLanguage(lang.code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${lang.flag} ${lang.name} ${tr('language_select')}',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (widget.isFromSettings) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: widget.isFromSettings
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: AppTheme.textPrimary,
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          tr('language_title'),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(widget.isFromSettings ? 100 : 110),
          child: Column(
            children: [
              if (!widget.isFromSettings)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Text(
                    tr('language_search'),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: tr('language_search'),
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.muted,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppTheme.muted,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: AppTheme.muted,
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.muted,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                tabs: List.generate(_regionKeys.length, (i) {
                  final key = _regionKeys[i];
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_regionEmojis[key] ?? ''),
                        const SizedBox(width: 4),
                        Text(_regions[i]),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_regionCounts[key]}',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_regionKeys.length, (tabIndex) {
          return _buildLanguageList(tabIndex);
        }),
      ),
    );
  }

  Widget _buildLanguageList(int tabIndex) {
    return AnimatedBuilder(
      animation: _searchController,
      builder: (context, _) {
        final languages = _getLanguagesForTab(tabIndex);
        if (languages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 40)),
                SizedBox(height: 1.h),
                Text(
                  tr('empty_state'),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Group by region if "Tout" tab
        if (_regionKeys[tabIndex] == 'Tout' && _searchQuery.isEmpty) {
          return _buildGroupedList();
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            return _buildLanguageTile(languages[index]);
          },
        );
      },
    );
  }

  Widget _buildGroupedList() {
    final regionKeys = ['Europe', 'Afrique', 'Asie', 'Moyen-Orient'];
    final regionLabels = [
      tr('language_europe'),
      tr('language_africa'),
      tr('language_asia'),
      tr('language_middle_east'),
    ];
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: regionKeys.length,
      itemBuilder: (context, regionIndex) {
        final regionKey = regionKeys[regionIndex];
        final regionLabel = regionLabels[regionIndex];
        final langs = LanguageService.byRegion[regionKey] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: regionIndex == 0 ? 0 : 2.h,
                bottom: 1.h,
              ),
              child: Row(
                children: [
                  Text(
                    _regionEmojis[regionKey] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    regionLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${langs.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...langs.map((lang) => _buildLanguageTile(lang)),
          ],
        );
      },
    );
  }

  Widget _buildLanguageTile(LanguageModel lang) {
    final isSelected = _selectedCode == lang.code;
    return InkWell(
      onTap: () => _selectLanguage(lang),
      borderRadius: BorderRadius.circular(12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(20) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: Text(lang.flag, style: const TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    lang.nativeName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 1.5),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
