import 'package:mime/mime.dart';

final class MimeType {
  final String type;
  final String subtype;
  final String suffix;
  final Map<String, String> parameters;

  /// Constructs a MimeType from its components.
  MimeType(
    this.type,
    this.subtype,
    this.suffix, [
    Map<String, String>? parameters,
  ]) : parameters = parameters == null ? {} : Map.unmodifiable(parameters);

  static final RegExp parsingExp = RegExp(
    r'^(?<type>\w+)\/(?<subtype>[\w\.-]+)(?:\+(?<suffix>[\w\.-]+))?',
  );

  factory MimeType.parseFromExtension(String path) {
    final mimeType = MimeTypeResolver().lookup(path);
    if (mimeType == null) {
      throw FormatException('Unknown file extension: $path');
    }
    return MimeType.parse(mimeType);
  }

  /// Parses a MIME type string (e.g. 'text/plain; charset=utf-8')
  factory MimeType.parse(String input) {
    // Split into main type/subtype/suffix and parameters
    final parts = input.split(';');
    final main = parts[0].trim();
    final match = parsingExp.firstMatch(main);
    if (match == null) {
      throw FormatException('Invalid MIME type: $input');
    }
    final type = match.namedGroup('type')!;
    final subtype = match.namedGroup('subtype')!;
    final suffix = match.namedGroup('suffix') ?? '';
    final params = <String, String>{};
    for (var i = 1; i < parts.length; i++) {
      final param = parts[i].trim();
      if (param.isEmpty) continue;
      final eq = param.indexOf('=');
      if (eq > 0 && eq < param.length - 1) {
        final key = param.substring(0, eq).trim();
        final value = param.substring(eq + 1).trim();
        params[key] = value;
      } else {
        // Parameter without value
        params[param] = '';
      }
    }
    return MimeType(type, subtype, suffix, params);
  }

  /// Returns the full MIME type string, including parameters.
  @override
  String toString() {
    var str = '$type/$subtype';
    if (suffix.isNotEmpty) {
      str += '+$suffix';
    }

    if (parameters.isNotEmpty) {
      var paramsString = parameters.entries
          .map((e) {
            if (e.value.isEmpty) {
              return e.key;
            }
            return '${e.key}=${e.value}';
          })
          .join(';');
      str += ';$paramsString';
    }

    return str;
  }

  /// Checks equality by type, subtype, and parameters.
  @override
  bool operator ==(Object other) =>
      other is MimeType &&
      type == other.type &&
      subtype == other.subtype &&
      _mapEquals(parameters, other.parameters);

  @override
  int get hashCode =>
      Object.hash(type, subtype, Object.hashAll(parameters.entries));

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  /// Returns true if the type and subtype are valid tokens.
  bool get isValid {
    final token = RegExp(r"^[!#\$%&'*+\-.^_`|~0-9a-zA-Z]+");
    return token.hasMatch(type) && token.hasMatch(subtype);
  }
}
