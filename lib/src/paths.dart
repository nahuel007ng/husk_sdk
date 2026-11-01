import 'package:path/path.dart' as p;

/// Name of the git-ignored directory that `link` copies vendor binaries into.
const String dropDirName = 'husk_vendor';

/// Normalizes a user-supplied relative path to POSIX form.
///
/// Backslashes are treated as separators so a spec written on Windows works
/// everywhere. Absolute paths, drive letters and paths that climb out of the
/// project with `..` are rejected with a [FormatException].
String normalizeRelative(String input) {
  final raw = input.trim().replaceAll(r'\', '/');
  if (raw.isEmpty) throw const FormatException('must not be empty');
  if (raw.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(raw)) {
    throw const FormatException('must be relative to the project directory');
  }
  final normalized = p.posix.normalize(raw);
  if (normalized == '.' || normalized == '..' || normalized.startsWith('../')) {
    throw const FormatException('must point inside the project directory');
  }
  if (!RegExp(r'^[A-Za-z0-9_./+-]+$').hasMatch(normalized)) {
    throw const FormatException(
      'may only contain letters, digits and _ . / + -',
    );
  }
  return normalized;
}

/// [path] relative to [from], always with forward slashes, for messages and
/// generated files.
String displayPath(String path, {required String from}) =>
    p.split(p.relative(path, from: from)).join('/');
