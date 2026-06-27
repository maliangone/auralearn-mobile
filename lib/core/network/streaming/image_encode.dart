import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Image preparation for the `/solve` streaming contract.
///
/// Per the streaming contract: each image is downscaled to a long edge of
/// `<= [maxLongEdge]` px, re-encoded as JPEG, and base64-encoded. At most
/// [maxImages] images are sent (extras are dropped).
class SolveImageEncoder {
  /// Long-edge cap matching the Claude vision tiling sweet spot.
  static const int maxLongEdge = 1568;

  /// Hard cap on images per question (contract: <= 3).
  static const int maxImages = 3;

  /// JPEG quality used when re-encoding downscaled images.
  static const int jpegQuality = 85;

  /// Downscales, JPEG-encodes, and base64-encodes up to [maxImages] images.
  ///
  /// Decoding failures (corrupt/unsupported bytes) fall back to base64 of the
  /// raw input bytes so a single bad frame does not abort the whole request.
  static List<String> encodeAll(List<Uint8List> images) {
    final selected =
        images.length > maxImages ? images.sublist(0, maxImages) : images;
    return selected.map(encodeOne).toList(growable: false);
  }

  /// Downscales (if needed), JPEG-encodes, and base64-encodes a single image.
  static String encodeOne(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // TODO: unsupported/corrupt image — falling back to raw base64 without
      // resize. The proxy may reject oversized payloads.
      return base64Encode(bytes);
    }

    final longEdge =
        decoded.width >= decoded.height ? decoded.width : decoded.height;

    final img.Image normalized = longEdge > maxLongEdge
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxLongEdge : null,
            height: decoded.height > decoded.width ? maxLongEdge : null,
          )
        : decoded;

    final jpeg = img.encodeJpg(normalized, quality: jpegQuality);
    return base64Encode(jpeg);
  }
}
