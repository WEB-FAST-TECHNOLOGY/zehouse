import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_export.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http://') || startsWith('https://')) {
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file://')) {
      return ImageType.file;
    } else if (startsWith('assets/')) {
      return ImageType.png;
    } else {
      return ImageType.unknown;
    }
  }
}

enum ImageType { svg, png, network, file, unknown }

class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/no-image.jpg',
    this.errorWidget,
    this.semanticLabel,
  });

  ///[imageUrl] is optional parameter for showing image
  final String? imageUrl;

  ///[name] optional name to extract initial letter when image is missing or fails
  final String? name;

  final double? height;

  final double? width;

  final BoxFit? fit;

  final String placeHolder;

  final Color? color;

  final Alignment? alignment;

  final VoidCallback? onTap;

  final BorderRadius? radius;

  final EdgeInsetsGeometry? margin;

  final BoxBorder? border;

  /// Optional widget to show when the image fails to load.
  final Widget? errorWidget;

  /// Semantic label for the image to improve accessibility
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(alignment: alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(onTap: onTap, child: _buildCircleImage()),
    );
  }

  ///build the image with border radius
  Widget _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  ///build the image with border and border radius style
  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(border: border, borderRadius: radius),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildInitialFallback() {
    String initial = '?';
    if (name != null && name!.trim().isNotEmpty) {
      initial = name!.trim()[0].toUpperCase();
    } else if (semanticLabel != null && semanticLabel!.trim().isNotEmpty) {
      final clean = semanticLabel!
          .replaceAll('Photo de profil de ', '')
          .replaceAll('Avatar ', '')
          .trim();
      if (clean.isNotEmpty) {
        initial = clean[0].toUpperCase();
      }
    }

    return Container(
      height: height,
      width: width,
      color: AppTheme.primary.withAlpha(20),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: ((height ?? 40) * 0.4).clamp(12.0, 32.0),
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildImageView() {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      switch (imageUrl!.imageType) {
        case ImageType.svg:
          return SizedBox(
            height: height,
            width: width,
            child: SvgPicture.asset(
              imageUrl!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null
                  ? ColorFilter.mode(
                      color ?? Colors.transparent,
                      BlendMode.srcIn,
                    )
                  : null,
              semanticsLabel: semanticLabel,
            ),
          );
        case ImageType.file:
          return Image.file(
            File(imageUrl!),
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            semanticLabel: semanticLabel,
            errorBuilder: (context, error, stackTrace) =>
                errorWidget ?? _buildInitialFallback(),
          );
        case ImageType.network:
          return CachedNetworkImage(
            height: height,
            width: width,
            fit: fit,
            imageUrl: imageUrl!,
            color: color,
            placeholder: (context, url) => SizedBox(
              height: 30,
              width: 30,
              child: LinearProgressIndicator(
                color: Colors.grey.shade200,
                backgroundColor: Colors.grey.shade100,
              ),
            ),
            errorWidget: (context, url, error) =>
                errorWidget ?? _buildInitialFallback(),
          );
        case ImageType.png:
          return Image.asset(
            imageUrl!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            semanticLabel: semanticLabel,
            errorBuilder: (context, error, stackTrace) =>
                errorWidget ?? _buildInitialFallback(),
          );
        case ImageType.unknown:
        default:
          return errorWidget ?? _buildInitialFallback();
      }
    }
    return errorWidget ?? _buildInitialFallback();
  }
}
