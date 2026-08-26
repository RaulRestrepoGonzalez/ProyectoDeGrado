import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final bool isThumbnail;
  final bool isActive;

  const VideoPlayerWidget({
    super.key,
    required this.url,
    this.isThumbnail = false,
    this.isActive = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.isActive && !widget.isThumbnail) {
      _initializeController(widget.url);
    }
  }

  void _initializeController(String url) {
    final controllerUrl = _normalizeUrlForPlatform(url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(controllerUrl))
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            _controller?.setLooping(true);
            _updatePlaybackState();
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _isError = true;
                _errorMessage = error.toString();
              });
            }
          });
  }

  String _normalizeUrlForPlatform(String url) {
    if (Platform.isAndroid &&
        (url.contains('localhost') || url.contains('127.0.0.1'))) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _disposeController();
      if (widget.isActive && !widget.isThumbnail) {
        _initializeController(widget.url);
      }
    } else if (widget.isActive != oldWidget.isActive ||
        widget.isThumbnail != oldWidget.isThumbnail) {
      if (widget.isActive && !widget.isThumbnail && _controller == null) {
        _initializeController(widget.url);
      } else if (!widget.isActive || widget.isThumbnail) {
        _disposeController();
      } else {
        _updatePlaybackState();
      }
    }
  }

  void _updatePlaybackState() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.value.isInitialized)
      return;

    if (widget.isActive && !widget.isThumbnail) {
      controller.setVolume(1.0);
      controller.play();
    } else {
      controller.pause();
      controller.setVolume(0.0);
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.value.isInitialized)
      return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        color: Colors.grey.shade900,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 50,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error cargando video:\n$_errorMessage\n\nURL: ${widget.url}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Colors.white70,
            size: 64,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.isThumbnail ? null : _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          if (!controller.value.isPlaying && !widget.isThumbnail)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.play_arrow, size: 80, color: Colors.white70),
              ),
            ),
          if (widget.isThumbnail)
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
