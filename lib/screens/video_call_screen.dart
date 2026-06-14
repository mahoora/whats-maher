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
  String? _error;
  html.MediaStream? _stream;
  html.DivElement? _overlay;
  html.VideoElement? _video;
  html.DivElement? _controls;

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
      ..style.zIndex = '99999'
      ..style.display = 'flex'
      ..style.flexDirection = 'column'
      ..style.overflow = 'hidden';

    // Name label
    final nameLabel = html.DivElement()
      ..style.padding = '40px 16px 0'
      ..style.textAlign = 'center'
      ..style.color = 'white'
      ..style.fontSize = '20px'
      ..style.fontWeight = 'bold'
      ..innerText = widget.name;
    _overlay!.append(nameLabel);

    // Video element
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '')
      ..style.flex = '1'
      ..style.width = '100%'
      ..style.objectFit = 'cover';
    _overlay!.append(_video!);

    // Controls
    _controls = html.DivElement()
      ..style.padding = '24px'
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..style.gap = '32px';
    _overlay!.append(_controls!);

    html.document.body!.append(_overlay!);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': true,
        'audio': true,
      });
      _video!.srcObject = _stream;
      _addButtons();
    } catch (e) {
      html.window.console.error('Camera error: $e');
      if (_overlay != null) {
        _overlay!.children.first.innerText = 'تعذر الوصول للكاميرا: تأكد من السماح بها';
      }
    }
  }

  void _addButtons() {
    if (_controls == null || _controls!.isConnected != true) return;
    _controls!.innerHtml = '';
    _controls!.append(_btn(_micOn ? '🎤' : '🔇', () {
      _micOn = !_micOn;
      _stream?.getAudioTracks().forEach((t) => t.enabled = _micOn);
      _addButtons();
    }));
    _controls!.append(_btn('📞', () {
      _cleanUp();
      if (mounted) Navigator.pop(context);
    }, red: true));
    _controls!.append(_btn(_videoOn ? '📹' : '🚫', () {
      _videoOn = !_videoOn;
      _stream?.getVideoTracks().forEach((t) => t.enabled = _videoOn);
      _addButtons();
    }));
  }

  html.Element _btn(String text, void Function() onTap, {bool red = false}) {
    final btn = html.ButtonElement()
      ..style.width = '56px'
      ..style.height = '56px'
      ..style.borderRadius = '50%'
      ..style.border = 'none'
      ..style.fontSize = '28px'
      ..style.cursor = 'pointer'
      ..style.backgroundColor = red ? '#EF4444' : '#2A3942'
      ..style.color = 'white'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..innerText = text;
    btn.onClick.listen((_) => onTap());
    return btn;
  }

  void _cleanUp() {
    _stream?.getTracks().forEach((t) => t.stop());
    _video?.remove();
    _overlay?.remove();
    _stream = null;
    _video = null;
    _overlay = null;
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
