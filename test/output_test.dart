import 'dart:io';

import 'package:husk_sdk/husk_sdk.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  BlockEdit block(
    String path,
    List<String> body, {
    InsertAt at = InsertAt.end,
  }) => BlockEdit(
    path,
    comment: '#',
    body: body,
    insertAt: at,
    indent: at == InsertAt.end ? '' : '  ',
  );

  test('appends a block, then replaces it in place', () {
    final once = block('f', ['a']).apply('x = 1\n\n\n', force: false);
    expect(once, startsWith('x = 1\n\n# BEGIN husk_sdk'));
    expect(once, endsWith('a\n# END husk_sdk\n'));
    final twice = block('f', ['b']).apply('$once\nafter\n', force: false);
    expect(twice, contains('\nb\n# END husk_sdk\n\nafter\n'));
    expect(twice, isNot(contains('\na\n')));
  });

  test('inserts before the closing end of a podspec', () {
    final out = block(
      'p',
      ['s.x = 1'],
      at: InsertAt.beforeLastRubyEnd,
    ).apply("Pod::Spec.new do |s|\n  s.name = 'p'\nend\n", force: false);
    expect(out, endsWith('  s.x = 1\n  # END husk_sdk\nend\n'));
    expect(
      () => block('p', [
        'x',
      ], at: InsertAt.beforeLastRubyEnd).apply('nothing', force: false),
      throwsA(isA<PlanException>()),
    );
  });

  test('broken markers are reported, not guessed at', () {
    expect(
      () => block('f', ['a']).apply('# BEGIN husk_sdk\nno end\n', force: false),
      throwsA(
        isA<PlanException>().having(
          (e) => e.message,
          'message',
          contains('without END'),
        ),
      ),
    );
    expect(
      () => block('f', ['a']).apply('# END husk_sdk\n', force: false),
      throwsA(isA<PlanException>()),
    );
  });

  test('owned files refuse to overwrite hand-written files unless forced', () {
    final f = OwnedFile('x.dart', '// $generatedMarker\nnew\n');
    expect(
      () => f.apply('mine\n', force: false),
      throwsA(isA<PlanException>()),
    );
    expect(f.apply('mine\n', force: true), '// $generatedMarker\nnew\n');
    expect(
      f.apply('// $generatedMarker\nold\n', force: false),
      contains('new'),
    );
  });

  test('applyPlan writes only what changed and keeps CRLF files CRLF', () {
    final root = tempDir().path;
    final crlf = write(root, 'win.txt', 'one\r\ntwo\r\n');
    final plan = [
      BlockEdit('win.txt', comment: '#', body: ['x']),
      OwnedFile('gen/a.txt', '// $generatedMarker\nhi\n'),
    ];
    final first = applyPlan(root, plan);
    expect(first.map((o) => o.status), [
      FileStatus.updated,
      FileStatus.created,
    ]);
    expect(crlf.readAsStringSync(), contains('\r\n# END husk_sdk\r\n'));
    expect(
      crlf.readAsStringSync().replaceAll('\r\n', ''),
      isNot(contains('\n')),
    );

    final stamp = File('$root/gen/a.txt').lastModifiedSync();
    final second = applyPlan(root, plan);
    expect(second.map((o) => o.status), everyElement(FileStatus.unchanged));
    expect(File('$root/gen/a.txt').lastModifiedSync(), stamp);
  });

  test('dry run writes nothing', () {
    final root = tempDir().path;
    final out = applyPlan(root, [OwnedFile('a.txt', 'x\n')], dryRun: true);
    expect(out.single.status, FileStatus.created);
    expect(File('$root/a.txt').existsSync(), isFalse);
  });

  test('an existing file keeps its permission bits', () {
    if (Platform.isWindows) return;
    final root = tempDir().path;
    final f = write(root, 'script.sh', 'echo hi\n');
    Process.runSync('chmod', ['755', f.path]);
    applyPlan(root, [
      BlockEdit('script.sh', comment: '#', body: ['echo husk']),
    ]);
    expect(f.statSync().modeString(), 'rwxr-xr-x');
  });
}
