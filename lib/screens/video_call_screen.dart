import 'dart:html' as html;
import 'dart:ui' as ui;
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
  String? _error;
  html.MediaStream? _stream;
  html.VideoElement? _video;

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
      _video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', '')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..srcObject = _stream;
      html.document.body!.append(_video!);
      // Register for Flutter HtmlElementView
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory('call-video', (int id) => _video!);
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      html.window.console.error('Camera error: $e');
      if (mounted) setState(() => _error = 'تعذر الوصول للكاميرا: تأكد من السماح بها في المتصفح');
    }
  }

  @override
  void dispose() {
    _stream?.getTracks().forEach((t) => t.stop());
    if (_video?.parentNode != null) _video!.remove();
    super.dispose();
  }

  void _toggleMic() {
    _stream?.getAudioTracks().forEach((t) { t.enabled = !_micOn; });
    setState(() => _micOn = !_micOn);
  }

  void _toggleVideo() {
    _stream?.getVideoTracks().forEach((t) { t.enabled = !_videoOn; });
    setState(() => _videoOn = !_videoOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraReady && _videoOn)
            Positioned.fill(child: HtmlElementView(viewType: 'call-video'))
          else if (!_cameraReady && _error == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00A884)),
                  SizedBox(height: 16),
                  Text('جاري تشغيل الكاميرا...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 80, color: Color(0xFF8696A0)),
                  const SizedBox(height: 16),
                  Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14), textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          // Top bar
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
          // Bottom controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlButton(_micOn ? Icons.mic : Icons.mic_off, _micOn ? Colors.white : Colors.redAccent, _toggleMic),
                const SizedBox(width: 24),
                _controlButton(Icons.call_end, Colors.red, () => Navigator.pop(context), bg: Colors.red),
                const SizedBox(width: 24),
                _controlButton(_videoOn ? Icons.videocam : Icons.videocam_off, _videoOn ? Colors.white : Colors.redAccent, _toggleVideo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color, VoidCallback onTap, {Color? bg}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: bg ?? const Color(0xFF2A3942),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
