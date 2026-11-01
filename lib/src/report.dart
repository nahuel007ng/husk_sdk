/// How serious a finding is.
enum Level {
  /// Fine; shown by `doctor` only.
  ok,

  /// Context; shown by `doctor` only.
  info,

  /// Worth fixing, but `check` still passes.
  warning,

  /// `check` fails.
  error,
}

/// One line of a `doctor` or `check` report.
class Finding {
  /// Creates a finding.
  const Finding(this.level, this.message, {this.detail = const []});

  /// How serious it is.
  final Level level;

  /// One-line summary.
  final String message;

  /// Extra lines printed indented below the message.
  final List<String> detail;
}

/// A titled group of findings.
class Section {
  /// Creates an empty section.
  Section(this.title);

  /// Heading printed above the findings.
  final String title;

  /// Findings in the order they were added.
  final List<Finding> findings = [];

  /// Adds a finding.
  void add(Level level, String message, {List<String> detail = const []}) =>
      findings.add(Finding(level, message, detail: detail));
}
