import 'package:iri/iri.dart';

import 'utils.dart';

interface class PartName {
  const PartName._(this.value);

  factory PartName.fromString(String s) {
    if (!isValid(s)) {
      throw ArgumentError.value(s, 's', 'Not a valid part name');
    }
    return PartName._(IRI(s));
  }

  final IRI value;

  @override
  String toString() => value.toString();

  static bool isValid(String s) {
    IRI uri;
    try {
      uri = IRI(s);
    } on FormatException {
      return false;
    }

    if (!uri.hasAbsolutePath || uri.pathSegments.isEmpty) {
      return false;
    }

    // Check each segment for emptiness and forbidden unicode
    for (final segment in uri.pathSegments) {
      if (segment.isEmpty) return false;
      for (final code in segment.runes) {
        // Forbidden Unicode Ranges
        if ((code >= 0xF900 && code <= 0xFDCF) ||
            (code >= 0xFDF0 && code <= 0xFFEF) ||
            (code >= 0x10000 && code <= 0x1FFFD) ||
            (code >= 0x20000 && code <= 0x2FFFD) ||
            (code >= 0x30000 && code <= 0x3FFFD) ||
            (code >= 0x40000 && code <= 0x4FFFD) ||
            (code >= 0x50000 && code <= 0x5FFFD) ||
            (code >= 0x60000 && code <= 0x6FFFD) ||
            (code >= 0x70000 && code <= 0x7FFFD) ||
            (code >= 0x80000 && code <= 0x8FFFD) ||
            (code >= 0x90000 && code <= 0x9FFFD) ||
            (code >= 0xA0000 && code <= 0xAFFFD) ||
            (code >= 0xB0000 && code <= 0xBFFFD) ||
            (code >= 0xC0000 && code <= 0xCFFFD) ||
            (code >= 0xD0000 && code <= 0xDFFFD) ||
            (code >= 0xE1000 && code <= 0xEFFFD)) {
          return false;
        }
      }
    }

    // Disallow query, fragment, authority
    if (uri.hasQuery ||
        uri.hasFragment ||
        uri.hasAuthority ||
        uri.userInfo.isNotEmpty) {
      return false;
    }

    // Disallow percent-encoded / and \
    final path = uri.path;
    if (path.contains("%2F") ||
        path.contains("%2f") ||
        path.contains("%5C") ||
        path.contains("%5c")) {
      return false;
    }

    // Disallow percent-encoded unreserved (A-Z, a-z, 0-9, -, ., _, ~)
    final percentEncoding = RegExp(r'%([0-9A-Fa-f]{2})');
    for (final match in percentEncoding.allMatches(path)) {
      final hex = match.group(1);
      if (hex == null) continue;
      final code = int.tryParse(hex, radix: 16);
      if (code == null) continue;
      if ((code >= 0x41 && code <= 0x5A) || // A-Z
          (code >= 0x61 && code <= 0x7A) || // a-z
          (code >= 0x30 && code <= 0x39) || // 0-9
          code == 0x2D || // -
          code == 0x2E || // .
          code == 0x5F || // _
          code == 0x7E) {
        // ~
        return false;
      }
    }

    // Disallow trailing dot
    final last = uri.pathSegments.last;
    if (last.endsWith('.')) return false;

    // Disallow /_rels/*.rels
    if (last.endsWith('.rels') &&
        uri.pathSegments.length > 1 &&
        uri.pathSegments[uri.pathSegments.length - 2] == '_rels') {
      return false;
    }

    return true;
  }
}

interface class Part {
  final PartName name;
  final MimeType? contentType;

  const Part(this.name, this.contentType);
}
