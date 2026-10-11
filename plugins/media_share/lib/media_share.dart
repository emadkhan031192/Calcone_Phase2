import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Shares a PNG image through the Android MediaStore.
///
/// Why this exists: `share_plus` shares files through
/// `androidx.core.content.FileProvider`, whose classes get obfuscated by
/// R8 in release builds — on real devices that crashes with
/// `IncompatibleClassChangeError` inside the provider's XML parsing.
/// Writing the image to `MediaStore.Images` instead yields a
/// `content://media/...` URI with no FileProvider and no extra
/// permissions (Android 10+), so the system share sheet just works.
class MediaShare {
  MediaShare._();

  static const MethodChannel _channel = MethodChannel('media_share');

  /// Saves [bytes] as [fileName] under Pictures/Calcone and opens the
  /// system share sheet with the image (plus [text] when given).
  /// Throws [PlatformException] when the save or the share fails.
  static Future<void> shareImage(
    Uint8List bytes, {
    String fileName = 'calcone_share.png',
    String? text,
  }) {
    return _channel.invokeMethod<void>('shareImage', <String, dynamic>{
      'bytes': bytes,
      'fileName': fileName,
      'text': text,
    });
  }

  /// True on Android 10+ where the MediaStore path needs no permission.
  static Future<bool> get isSupported async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>('isSupported');
      return ok ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
