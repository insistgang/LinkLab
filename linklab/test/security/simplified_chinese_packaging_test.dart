import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('交付源码与界面文案不得包含已知繁体或旧字形', () {
    const roots = [
      'README.md',
      'lib',
      'assets',
      'docs',
      'admin_dashboard/lib',
      'android',
      'web',
    ];
    const textExtensions = {
      '.dart',
      '.md',
      '.json',
      '.yaml',
      '.yml',
      '.xml',
      '.svg',
      '.tsv',
      '.html',
      '.js',
      '.kt',
      '.kts',
      '.properties',
      '.txt',
    };
    final forbidden = RegExp(r'回覆|谘询|高峯');
    final offenders = <String>[];

    for (final rootPath in roots) {
      final type = FileSystemEntity.typeSync(rootPath);
      final files = switch (type) {
        FileSystemEntityType.file => <File>[File(rootPath)],
        FileSystemEntityType.directory => Directory(
          rootPath,
        ).listSync(recursive: true, followLinks: false).whereType<File>(),
        _ => const <File>[],
      };

      for (final file in files) {
        final name = file.path.toLowerCase();
        if (!textExtensions.any(name.endsWith)) continue;

        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          if (forbidden.hasMatch(lines[index])) {
            offenders.add('${file.path}:${index + 1}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '请将这些面向用户或交付阅读者的旧字形统一为简体：\n'
          '${offenders.join('\n')}',
    );
  });
}
