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
  late VideoPlayerController _controller;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeController(widget.url);
  }

  void _initializeController(String url) {
    final controllerUrl = _normalizeUrlForPlatform(url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(controllerUrl))
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            _controller.setLooping(true);
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
      _controller.pause();
      _controller.dispose();
      _initializeController(widget.url);
    } else if (widget.isActive != oldWidget.isActive ||
        widget.isThumbnail != oldWidget.isThumbnail) {
      _updatePlaybackState();
    }
  }

  void _updatePlaybackState() {
    if (!mounted || !_controller.value.isInitialized) return;

    if (widget.isActive && !widget.isThumbnail) {
      _controller.setVolume(1.0);
      _controller.play();
    } else {
      _controller.pause();
      _controller.setVolume(0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!mounted || !_controller.value.isInitialized) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
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

    if (!_controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
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
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying && !widget.isThumbnail)
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
