import 'package:glados/glados.dart';
import 'package:opc/part.dart';

void main() {
  Glados(any.nonEmptyLetterOrDigits).test('accepts single segment part', (s) {
    expect(PartName.isValid("/$s"), true);
  });
  test('accepts single segment part', () {
    expect(PartName.isValid("/foo"), true);
    expect(PartName.isValid("/é"), true, reason: "unicode should be accepted");
  });

  Glados(any.nonEmptyLetterOrDigits)
      .test('accepts multi-segment part', (s) {
    expect(PartName.isValid("/$s"), true);
  });
  test('accepts multi-segment part', () {
    expect(PartName.isValid("/foo123/bar456"), true);
    expect(PartName.isValid("/hello/world/doc.xml"), true);
  });

  test("accepts allowed percent-encoded characters", () {
    expect(PartName.isValid("/foo%20bar"), true);
  });

  test("rejects disallowed percent-encoded characters", () {
    expect(PartName.isValid("/%EF%A4%81"), false);
  });

  test("accepts special characters", () {
    expect(PartName.isValid("/foo_bar-baz.qux~"), true);
    expect(PartName.isValid("/!\$&'()*+,;=:@"), true);
  });

  Glados(any.nonEmptyLetters)
      .test("rejects non-absolute uri", (s) {
    expect(PartName.isValid(s), false);
  });
  test("rejects non-absolute uri", () {
    expect(PartName.isValid("foo/bar"), false);
  });

  test("rejects empty part", () {
    expect(PartName.isValid("/"), false);
    expect(PartName.isValid("//"), false);
    expect(PartName.isValid("/foo//bar"), false);
  });

  Glados3(
    any.nonEmptyLetters,
    any.nonEmptyLetters,
    any.oneOf([any.nonEmptyLetters, any.null_]),
  ).test("rejects uri with query", (query, path, value) {

    var str = "/$path?$query";
    if(value != null) {
      str += "=$value";
    }

    expect(PartName.isValid(str), false);
  });
  test("rejects uri with query", () {
    expect(PartName.isValid("/foo/bar?baz"), false);
    expect(PartName.isValid("/foo/bar?baz=qux"), false);
  });

  Glados2(
    any.nonEmptyLetters,
    any.nonEmptyLetters,
  ).test("rejects uri with fragment", (fragment, path) {
    expect(PartName.isValid("/$path#$fragment"), false);
  });
  test("rejects uri with fragment", () {
    expect(PartName.isValid("/foo#section1"), false);
    expect(PartName.isValid("/foo/bar#section1"), false);
  });

  Glados2(
    any.nonEmptyLetters,
    any.nonEmptyLetters,
  ).test("rejects uri with authority", (authority, path) {
    expect(PartName.isValid("http://$authority/$path"), false);
  });
  test("rejects uri with authority", () {
    expect(PartName.isValid("http://example.com/foo"), false);
    expect(PartName.isValid("http://example.com/foo/bar"), false);
  });

  Glados2(
    any.nonEmptyLetters,
    any.nonEmptyLetters,
  ).test("rejects uri with schema", (schema, path) {
    expect(PartName.isValid("$schema://$path"), false);
  });
  test("rejects uri with schema", () {
    expect(PartName.isValid("http://foo"), false);
    expect(PartName.isValid("http://foo/bar"), false);
    expect(PartName.isValid("custom-scheme://foo/bar"), false);
  });
  
  test("rejects empty string", () {
    expect(PartName.isValid(""), false);
  });

  test("rejects whitespace string", () {
    expect(PartName.isValid("   "), false);
  });

  test("rejects uri ending in dot", () {
    expect(PartName.isValid("/foo."), false);
  });


  Glados(any.nonEmptyLetters)
      .test("rejects reserved uri", (s) {
    expect(PartName.isValid("/_rels/$s.rels"), false, reason: "should reject /_rels/$s.rels");
    expect(PartName.isValid("/$s.rels"), true, reason: "should accept /$s.rels");
  });
  test("rejects reserved uri", () {
    expect(PartName.isValid("/_rels/.rels"), false);
    expect(PartName.isValid("/_rels/a.rels"), false);
    expect(PartName.isValid("/foo.rels"), true);
    expect(PartName.isValid("/a.rels"), true);
  });
}