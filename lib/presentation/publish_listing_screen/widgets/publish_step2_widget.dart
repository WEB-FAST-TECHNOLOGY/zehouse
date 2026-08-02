import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';

class PublishStep2Widget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String key, dynamic value) onChanged;

  const PublishStep2Widget({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<PublishStep2Widget> createState() => _PublishStep2WidgetState();
}

class _PublishStep2WidgetState extends State<PublishStep2Widget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 80,
    );
    if (images.isNotEmpty) {
      final currentPhotos = List<XFile>.from(widget.formData['photos'] as List<XFile>);
      currentPhotos.addAll(images);
      widget.onChanged('photos', currentPhotos);
      setState(() {});
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (video != null) {
      final file = File(video.path);
      final sizeInBytes = await file.length();
      if (sizeInBytes > 25 * 1024 * 1024) { // 25 MB
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('La vidéo dépasse la limite de 25 Mo.', style: GoogleFonts.outfit(color: Colors.white)),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }
      widget.onChanged('video', video);
      setState(() {});
    }
  }

  void _removePhoto(int index) {
    final currentPhotos = List<XFile>.from(widget.formData['photos'] as List<XFile>);
    currentPhotos.removeAt(index);
    widget.onChanged('photos', currentPhotos);
    setState(() {});
  }

  void _removeVideo() {
    widget.onChanged('video', null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.formData['photos'] as List<XFile>;
    final video = widget.formData['video'] as XFile?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos section
        _SectionTitle('Photos du bien'),
        const SizedBox(height: 6),
        Text(
          'Ajoutez jusqu\'à 15 photos. La première sera la photo principale.',
          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        ),
        const SizedBox(height: 16),

        // Photo grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: photos.length + 1, // +1 for add button
          itemBuilder: (context, index) {
            if (index == photos.length) {
              return _AddMediaButton(onTap: _pickPhotos, icon: Icons.add_photo_alternate_rounded, label: 'Photos');
            }
            return _PhotoTileFile(
              file: File(photos[index].path),
              isMain: index == 0,
              onRemove: () => _removePhoto(index),
            );
          },
        ),

        const SizedBox(height: 24),
        
        // Video section
        _SectionTitle('Vidéo du bien (Optionnel)'),
        const SizedBox(height: 6),
        Text(
          'Ajoutez une vidéo de visite (Max 25 Mo).',
          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        
        if (video == null)
          SizedBox(
            width: 120,
            height: 120,
            child: _AddMediaButton(onTap: _pickVideo, icon: Icons.video_call_rounded, label: 'Vidéo'),
          )
        else
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_file_rounded, size: 40, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      video.name,
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeVideo,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: AppTheme.muted,
            ),
            const SizedBox(width: 4),
            Text(
              'Glissez pour réorganiser les photos',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Description
        _SectionTitle('Description'),
        const SizedBox(height: 6),
        Text(
          'Décrivez les points forts de votre bien (emplacement, rénovation, équipements…)',
          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        ),
        const SizedBox(height: 16),

        TextFormField(
          initialValue: widget.formData['description'] as String,
          onChanged: (v) => widget.onChanged('description', v),
          maxLines: 6,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppTheme.textPrimary,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText:
                'ex. Magnifique appartement au 3ème étage avec vue dégagée, entièrement rénové en 2024...',
            hintStyle: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.muted.withAlpha(179),
              height: 1.6,
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
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: AppTheme.surface,
          ),
        ),

        const SizedBox(height: 12),

        // Character count hint
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(widget.formData['description'] as String).length} / 1000 caractères',
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
          ),
        ),

        const SizedBox(height: 28),

        // Key features
        _SectionTitle('Équipements & atouts'),
        const SizedBox(height: 12),
        _FeaturesSelector(),

      ],
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _AddMediaButton({required this.onTap, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTileFile extends StatelessWidget {
  final File file;
  final bool isMain;
  final VoidCallback onRemove;

  const _PhotoTileFile({
    required this.file,
    required this.isMain,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.surfaceVariant,
              child: Icon(Icons.image_outlined, color: AppTheme.muted),
            ),
          ),
        ),
        if (isMain)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Principale',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturesSelector extends StatefulWidget {
  @override
  State<_FeaturesSelector> createState() => _FeaturesSelectorState();
}

class _FeaturesSelectorState extends State<_FeaturesSelector> {
  // TODO: Replace with Riverpod for production
  final Set<String> _selected = {'Balcon', 'Parking'};

  static const List<String> _features = [
    'Balcon',
    'Terrasse',
    'Jardin',
    'Parking',
    'Cave',
    'Gardien',
    'Digicode',
    'Interphone',
    'Ascenseur',
    'Piscine',
    'Lumineux',
    'Calme',
    'Vue dégagée',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _features.map((feature) {
        final isSelected = _selected.contains(feature);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(feature);
              } else {
                _selected.add(feature);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            child: Text(
              feature,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
