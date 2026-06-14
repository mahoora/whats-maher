import 'dart:html' as html;
import 'package:flutter/material.dart';

class VideoCallScreen extends StatefulWidget {
  final String name;
  const VideoCallScreen({super.key, this.name = 'المستخدم'});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _micOn = true;
  bool _videoOn = true;
  bool _loading = true;
  String? _error;
  html.MediaStream? _stream;
  html.DivElement? _overlay;
  html.VideoElement? _video;

  @override
  void initState() {
    super.initState();
    _createOverlay();
  }

  void _createOverlay() {
    _overlay = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'black'
      ..style.zIndex = '999999'
      ..style.display = 'flex'
      ..style.flexDirection = 'column';

    final topBar = html.DivElement()
      ..style.padding = '40px 20px 0'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'space-between';
    final nameEl = html.SpanElement()
      ..style.color = 'white'
      ..style.fontSize = '18px'
      ..style.fontWeight = 'bold'
      ..innerText = widget.name;
    final closeBtn = html.ButtonElement()
      ..style.background = 'none'
      ..style.border = 'none'
      ..style.color = 'white'
      ..style.fontSize = '24px'
      ..style.cursor = 'pointer'
      ..style.padding = '8px'
      ..innerText = '✕';
    closeBtn.onClick.listen((_) { _cleanUp(); if (mounted) Navigator.pop(context); });
    topBar.append(nameEl);
    topBar.append(closeBtn);
    _overlay!.append(topBar);

    // Video container
    final videoContainer = html.DivElement()
      ..style.flex = '1'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.overflow = 'hidden';

    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '')
      ..style.maxWidth = '100%'
      ..style.maxHeight = '100%'
      ..style.objectFit = 'contain';
    videoContainer.append(_video!);
    _overlay!.append(videoContainer);

    // Controls
    final controlsRow = html.DivElement()
      ..style.padding = '20px 24px'
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..style.gap = '32px'
      ..style.alignItems = 'center';
    _overlay!.append(controlsRow);

    html.document.body!.append(_overlay!);
    _initCamera(controlsRow);
  }

  Future<void> _initCamera(html.DivElement controlsRow) async {
    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'width': 640, 'height': 480, 'facingMode': 'user'},
        'audio': true,
      });
      _video!.srcObject = _stream;
      _addButtons(controlsRow);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      html.window.console.error('Camera error: $e');
      if (mounted) setState(() { _loading = false; _error = 'تعذر الوصول للكاميرا/الميكروفون'; });
    }
  }

  void _addButtons(html.DivElement controlsRow) {
    controlsRow.innerHtml = '';
    controlsRow.append(_circleBtn(_micOn ? '🎤' : '🔇', () {
      _micOn = !_micOn;
      _stream?.getAudioTracks().forEach((t) => t.enabled = _micOn);
      _addButtons(controlsRow);
    }));
    controlsRow.append(_circleBtn('📞', () {
      _cleanUp();
      if (mounted) Navigator.pop(context);
    }, red: true, big: true));
    controlsRow.append(_circleBtn(_videoOn ? '📹' : '🚫', () {
      _videoOn = !_videoOn;
      _stream?.getVideoTracks().forEach((t) => t.enabled = _videoOn);
      _addButtons(controlsRow);
    }));
  }

  html.Element _circleBtn(String text, void Function() onTap, {bool red = false, bool big = false}) {
    final btn = html.ButtonElement()
      ..style.width = big ? '64px' : '52px'
      ..style.height = big ? '64px' : '52px'
      ..style.borderRadius = '50%'
      ..style.border = 'none'
      ..style.fontSize = '24px'
      ..style.cursor = 'pointer'
      ..style.backgroundColor = red ? '#EF4444' : '#2A3942'
      ..style.color = 'white'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.transition = '0.2s'
      ..innerText = text;
    btn.onClick.listen((_) => onTap());
    return btn;
  }

  void _cleanUp() {
    _stream?.getTracks().forEach((t) => t.stop());
    _video?.remove();
    _overlay?.remove();
    _stream = null; _video = null; _overlay = null;
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _loading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00A884)),
                  SizedBox(height: 16),
                  Text('جاري تشغيل الكاميرا...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              )
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16))
                : const SizedBox.shrink(),
      ),
    );
  }
}
