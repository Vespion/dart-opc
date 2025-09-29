import 'package:glados/glados.dart';
import 'package:opc/utils.dart';

List<MimeTypeTestData> validMimeTypes = [
  MimeTypeTestData('text/plain;charset=utf-8', 'text', 'plain', '', {
    'charset': 'utf-8',
  }, true),
  MimeTypeTestData('application/json', 'application', 'json', '', {}, true),
  MimeTypeTestData(' application/json', expectedString: "application/json", 'application', 'json', '', {}, true),
  MimeTypeTestData('application/json ', expectedString: "application/json", 'application', 'json', '', {}, true),
  MimeTypeTestData('application/json;a', 'application', 'json', '', {'a': ''}, true),
  MimeTypeTestData(
    'image/svg+xml;version=1.1;charset=utf-8',
    'image',
    'svg',
    'xml',
    {'version': '1.1', 'charset': 'utf-8'},
    true,
  ),
];

Map<String, MimeTypeTestData> validExtensionMimeTypes = {
  '.txt': MimeTypeTestData('text/plain', 'text', 'plain', '', {}, true),
  '.html': MimeTypeTestData('text/html', 'text', 'html', '', {}, true),
  '.json': MimeTypeTestData('application/json', 'application', 'json', '', {}, true),
  '.xml': MimeTypeTestData('application/xml', 'application', 'xml', '', {}, true),
  '.svg': MimeTypeTestData('image/svg+xml', 'image', 'svg', 'xml', {}, true),
};

const List<String> invalidMimeTypes = [
  '',
  'text',
  'text/',
  '/plain',
  'text/plain;=utf-8',
  'text/plain;charset=',
  'text/plain; charset="utf-8',
  'text/plain; charset=utf-8"',
  'text/plain; charset=utf-8;=value',
  'text/plain; charset==utf-8',
  'text/plain; charset=utf-8;; another=value',
  'text//plain',
  'text/ plain',
  'text/pla in',
  'te xt/plain',
  'text/pl@in',
  'te#xt/plain',
];

void main() {

  group("rejects invalid mime types", () {
    for (var input in invalidMimeTypes) {
      test(input, () {
        expect(() => MimeType.parse(input), throwsFormatException);
      });
    }

    Glados<String>(any.nonEmptyLetterOrDigits).test('generated values', (input) {
      expect(() => MimeType.parse(input), throwsFormatException);
    });
  });

  group("parses valid mime types correctly", () {
    Glados<MimeTypeTestData>(
      any.validMimeTypeTestData,
    ).test('generated values', correctlyParsesTest);

    for (var data in validMimeTypes) {
      test(data.original, () {
        correctlyParsesTest(data);
      });
    }
  });

  group("parses from extension correctly", () {
    for (var entry in validExtensionMimeTypes.entries) {
      test(entry.key, () {
        MimeType mimeType;
        try {
          mimeType = MimeType.parseFromExtension(entry.key);
        } on FormatException {
          if (entry.value.expectedIsValid) {
            throw AssertionError(
              'Expected valid MIME type, but parsing failed: ${entry.key}',
            );
          }
          return;
        }

        runMimeTypeAssertions(mimeType, entry.value);
      });
    }
  });
}

void correctlyParsesTest(MimeTypeTestData data) {
  MimeType mimeType;
  try {
    mimeType = MimeType.parse(data.original);
  } on FormatException {
    if (data.expectedIsValid) {
      throw AssertionError(
        'Expected valid MIME type, but parsing failed: ${data.original}',
      );
    }
    return;
  }

  runMimeTypeAssertions(mimeType, data);
}

void runMimeTypeAssertions(MimeType mimeType, MimeTypeTestData data) {
  expect(mimeType.type, data.expectedType, reason: 'type must match');
  expect(mimeType.subtype, data.expectedSubtype, reason: 'subtype must match');
  expect(mimeType.suffix, data.expectedSuffix, reason: 'suffix must match');
  expect(
    mimeType.parameters,
    data.expectedParameters,
    reason: 'parameters must match',
  );
  expect(
    mimeType.toString(),
    data.expectedString,
    reason: 'toString must match original',
  );
}

class MimeTypeTestData {
  final String original;
  final String expectedString;
  final String expectedType;
  final String expectedSubtype;
  final String expectedSuffix;
  final Map<String, String>? expectedParameters;
  final bool expectedIsValid;
  factory MimeTypeTestData(
    String original,
    String expectedType,
    String expectedSubtype,
    String expectedSuffix,
    Map<String, String>? expectedParameters,
    bool expectedIsValid,
    {String? expectedString}
  ) {
    return MimeTypeTestData._(
      original,
      expectedType,
      expectedSubtype,
      expectedSuffix,
      expectedParameters,
      expectedIsValid,
      expectedString ?? original
    );
  }

  const MimeTypeTestData._(
    this.original,
    this.expectedType,
    this.expectedSubtype,
    this.expectedSuffix,
    this.expectedParameters,
    this.expectedIsValid,
    this.expectedString
  );

  @override
  String toString() {
    return original;
  }
}

extension AnyMimeTypeTestData on Any {
  Generator<MimeTypeTestData> get validMimeTypeTestData => any.combine4(
    any.nonEmptyLetterOrDigits,
    any.nonEmptyLetterOrDigits,
    any.letterOrDigits,
    any.map(any.nonEmptyLetterOrDigits, any.letterOrDigits),
    (type, subtype, suffix, parameters) {
      var original = '$type/$subtype';
      if (suffix.isNotEmpty) {
        original += '+$suffix';
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
        original += ';$paramsString';
      }

      return MimeTypeTestData(
        original,
        type,
        subtype,
        suffix,
        parameters,
        true,
      );
    },
  );
}
