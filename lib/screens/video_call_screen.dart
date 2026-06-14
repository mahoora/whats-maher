import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';

class VideoCallScreen extends StatefulWidget {
  final String name;
  const VideoCallScreen({super.key, this.name = 'المستخدم'});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _cameraReady = false;
  bool _micOn = true;
  bool _videoOn = true;
  html.MediaStream? _stream;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': true,
        'audio': true,
      });
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', '')
        ..srcObject = _stream;
      html.document.body!.append(video);
      video.style.position = 'absolute';
      video.style.top = '0';
      video.style.left = '0';
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';
      video.style.zIndex = '0';
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      html.window.console.error('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _stream?.getTracks().forEach((t) => t.stop());
    // Remove video element
    final els = html.document.querySelectorAll('video');
    for (final el in els) {
      if (el.parentNode != null) el.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_cameraReady)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00A884)),
                  SizedBox(height: 16),
                  Text('جاري تشغيل الكاميرا...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          // Controls
          Positioned(
            top: 40,
            left: 20,
            child: Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlButton(Icons.mic, _micOn, () => setState(() => _micOn = !_micOn)),
                const SizedBox(width: 24),
                _controlButton(Icons.call_end, true, () => Navigator.pop(context), isRed: true),
                const SizedBox(width: 24),
                _controlButton(Icons.videocam, _videoOn, () => setState(() => _videoOn = !_videoOn)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, bool active, VoidCallback onTap, {bool isRed = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: isRed ? Colors.red : (active ? const Color(0xFF2A3942) : const Color(0xFF8696A0)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isRed ? Colors.white : (active ? Colors.white : const Color(0xFF2A3942)), size: 24),
      ),
    );
  }
}
