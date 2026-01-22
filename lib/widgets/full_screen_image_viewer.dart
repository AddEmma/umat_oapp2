import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A WhatsApp-style full-screen image viewer with zoom and pan capabilities.
///
/// Usage:
/// ```dart
/// FullScreenImageViewer.show(
///   context,
///   imageUrl: 'https://example.com/photo.jpg',
///   heroTag: 'profile_photo',
///   title: 'Profile Photo',
/// );
/// ```
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.title,
  });

  /// Shows the full-screen image viewer with a smooth hero animation.
  static void show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
    String? title,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageViewer(
            imageUrl: imageUrl,
            heroTag: heroTag,
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  bool _isZoomed = false;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      // Zoom out
      _animateResetZoom();
    } else {
      // Zoom in to 2.5x
      final position = _transformationController.value.getTranslation();
      final endMatrix = Matrix4.identity()
        ..translate(position.x, position.y)
        ..scale(2.5);

      _animation =
          Matrix4Tween(
            begin: _transformationController.value,
            end: endMatrix,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );

      _animationController.forward(from: 0);
      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });
    }

    setState(() {
      _isZoomed = !_isZoomed;
    });
  }

  void _animateResetZoom() {
    _animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: Matrix4.identity(),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward(from: 0);
    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    _currentScale = _transformationController.value.getMaxScaleOnAxis();
    _isZoomed = _currentScale > 1.1;
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // If scale is less than 1, reset to original size
    if (_currentScale < 1.0) {
      _animateResetZoom();
      _isZoomed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = InteractiveViewer(
      transformationController: _transformationController,
      onInteractionUpdate: _onInteractionUpdate,
      onInteractionEnd: _onInteractionEnd,
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: widget.heroTag != null
            ? Hero(
                tag: widget.heroTag!,
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    );
                  },
                ),
              )
            : Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  );
                },
              ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.title != null
            ? Text(
                widget.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        centerTitle: true,
      ),
      body: GestureDetector(
        onDoubleTap: _onDoubleTap,
        onTap: () {
          if (!_isZoomed) {
            Navigator.of(context).pop();
          }
        },
        child: Container(color: Colors.black, child: imageWidget),
      ),
    );
  }
}
