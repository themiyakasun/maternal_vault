import 'dart:convert';
import 'dart:io';

class SuiteGroupSpec {
  const SuiteGroupSpec({
    required this.displayName,
    required this.files,
    required this.target,
    required this.expectedCount,
  });

  final String displayName;
  final List<String> files;
  final String target;
  final int expectedCount;
}

class SuiteGroupResult {
  const SuiteGroupResult({
    required this.spec,
    required this.passed,
    required this.failed,
  });

  final SuiteGroupSpec spec;
  final int passed;
  final int failed;

  int get total => passed + failed;

  String get passFailLabel {
    final int pct = total == 0 ? 0 : ((passed / total) * 100).round();
    final String status = failed == 0 ? 'PASS' : 'FAIL';
    return '$passed / $failed ($pct% $status)';
  }
}

const List<SuiteGroupSpec> kSuiteSpecs = <SuiteGroupSpec>[
  SuiteGroupSpec(
    displayName: 'midwife_sync_test.dart',
    files: <String>['midwife_sync_test.dart'],
    target:
        'MVZ1:GZ: QR payload parsing, Gzip decompression, checksum verification, and read-only lock flags',
    expectedCount: 21,
  ),
  SuiteGroupSpec(
    displayName: 'model_notification_test.dart',
    files: <String>['model_notification_test.dart'],
    target:
        'On-device risk tier mapping, threshold escalation triggers, and offline alert generation',
    expectedCount: 20,
  ),
  SuiteGroupSpec(
    displayName: 'basic_profile_screen_test.dart',
    files: <String>['basic_profile_screen_test.dart'],
    target:
        'Form H-512 demographic rendering, field validation, and read-only state binding',
    expectedCount: 11,
  ),
  SuiteGroupSpec(
    displayName: 'app_inputs_test.dart',
    files: <String>['app_inputs_test.dart'],
    target:
        'Clinical numeric input bounds, unit labels, and error state rendering',
    expectedCount: 11,
  ),
  SuiteGroupSpec(
    displayName: 'app_buttons_test.dart & app_cards_test.dart',
    files: <String>[
      'app_buttons_test.dart',
      'app_cards_test.dart',
    ],
    target:
        'UI component states, loading indicators, and triage summary cards',
    expectedCount: 16,
  ),
  SuiteGroupSpec(
    displayName: 'mother_vault_setup_test.dart & mother_shell_test.dart',
    files: <String>[
      'mother_vault_setup_test.dart',
      'mother_shell_test.dart',
    ],
    target:
        'Vault initialization, navigation routing, and offline session persistence',
    expectedCount: 12,
  ),
  SuiteGroupSpec(
    displayName: 'partner_connect_screen_test.dart & partner_sync_test.dart',
    files: <String>[
      'partner_connect_screen_test.dart',
      'partner_sync_test.dart',
    ],
    target:
        'Partner role access boundaries and privacy filtering of sensitive mental health notes',
    expectedCount: 10,
  ),
  SuiteGroupSpec(
    displayName:
        'welcome_screen_test.dart, mother_settings_screen_test.dart, widget_test.dart',
    files: <String>[
      'welcome_screen_test.dart',
      'mother_settings_screen_test.dart',
      'widget_test.dart',
    ],
    target:
        'Localization switching (en/si/ta), app bootstrap, and settings controls',
    expectedCount: 9,
  ),
];

Future<void> main() async {
  final String flutterExec = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final List<String> allTestPaths = kSuiteSpecs
      .expand((SuiteGroupSpec s) => s.files.map((String f) => 'test/$f'))
      .toList();

  final ProcessResult proc = await Process.run(
    flutterExec,
    <String>['test', '--machine', ...allTestPaths],
    runInShell: true,
    environment: <String, String>{
      ...Platform.environment,
      'MV_SUPPRESS_CONFIG_TABLE': '1',
    },
  );

  final Map<int, String> suiteIdToBasename = <int, String>{};
  final Map<int, int> testIdToSuiteId = <int, int>{};
  final Map<String, int> passedByFile = <String, int>{};
  final Map<String, int> failedByFile = <String, int>{};

  for (final SuiteGroupSpec spec in kSuiteSpecs) {
    for (final String f in spec.files) {
      passedByFile[f] = 0;
      failedByFile[f] = 0;
    }
  }

  final List<String> lines = const LineSplitter().convert(
    proc.stdout.toString(),
  );
  for (final String line in lines) {
    final String trimmed = line.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) continue;
    try {
      final Map<String, dynamic> event =
          jsonDecode(trimmed) as Map<String, dynamic>;
      final String? type = event['type'] as String?;
      if (type == 'suite') {
        final Map<String, dynamic> suiteObj =
            event['suite'] as Map<String, dynamic>;
        final int id = suiteObj['id'] as int;
        final String rawPath = (suiteObj['path'] as String?) ?? '';
        final String basename = rawPath.replaceAll('\\', '/').split('/').last;
        suiteIdToBasename[id] = basename;
      } else if (type == 'testStart') {
        final Map<String, dynamic> testObj =
            event['test'] as Map<String, dynamic>;
        final int id = testObj['id'] as int;
        final int suiteId = testObj['suiteID'] as int;
        final String name = (testObj['name'] as String?) ?? '';
        if (!name.startsWith('loading ')) {
          testIdToSuiteId[id] = suiteId;
        }
      } else if (type == 'testDone') {
        final int testId = event['testID'] as int;
        final bool hidden = (event['hidden'] as bool?) ?? false;
        if (!hidden && testIdToSuiteId.containsKey(testId)) {
          final int suiteId = testIdToSuiteId[testId]!;
          final String? basename = suiteIdToBasename[suiteId];
          if (basename != null && passedByFile.containsKey(basename)) {
            final String? res = event['result'] as String?;
            if (res == 'success') {
              passedByFile[basename] = (passedByFile[basename] ?? 0) + 1;
            } else {
              failedByFile[basename] = (failedByFile[basename] ?? 0) + 1;
            }
          }
        }
      }
    } catch (_) {
      // Ignore non-JSON lines emitted by print() inside tests
    }
  }

  final List<SuiteGroupResult> results = <SuiteGroupResult>[];
  int totalPassed = 0;
  int totalFailed = 0;
  int totalFiles = 0;

  for (final SuiteGroupSpec spec in kSuiteSpecs) {
    totalFiles += spec.files.length;
    int groupPassed = 0;
    int groupFailed = 0;
    for (final String f in spec.files) {
      groupPassed += passedByFile[f] ?? 0;
      groupFailed += failedByFile[f] ?? 0;
    }
    totalPassed += groupPassed;
    totalFailed += groupFailed;
    results.add(
      SuiteGroupResult(spec: spec, passed: groupPassed, failed: groupFailed),
    );
  }

  if (proc.exitCode != 0 && totalFailed == 0) {
    totalFailed = 1;
  }

  final int grandTotal = totalPassed + totalFailed;
  final int grandPct =
      grandTotal == 0 ? 0 : ((totalPassed / grandTotal) * 100).round();
  final String grandStatus = totalFailed == 0 ? 'PASS' : 'FAIL';
  final String grandPassFail =
      '$totalPassed / $totalFailed ($grandPct% $grandStatus)';

  // 1. Output exact CLI verification table after success
  stdout.writeln(
    'Test Suite File (test/)\tPrimary Verification Target\tAssertions / Tests\tPass / Fail',
  );
  for (final SuiteGroupResult r in results) {
    stdout.writeln(
      '${r.spec.displayName}\t${r.spec.target}\t${r.total}\t${r.passFailLabel}',
    );
  }
  stdout.writeln(
    'Total Automated Test Suite\t$totalFiles Test Files\t$grandTotal\t$grandPassFail',
  );

  // 2. Append Markdown table to GITHUB_STEP_SUMMARY when running in GitHub Actions CI
  final String? stepSummaryPath = Platform.environment['GITHUB_STEP_SUMMARY'];
  if (stepSummaryPath != null && stepSummaryPath.isNotEmpty) {
    final StringBuffer md = StringBuffer()
      ..writeln('## Maternal Vault — Automated Test Suite Verification')
      ..writeln()
      ..writeln(
        '| Test Suite File (`test/`) | Primary Verification Target | Assertions / Tests | Pass / Fail |',
      )
      ..writeln('| :--- | :--- | :---: | :---: |');
    for (final SuiteGroupResult r in results) {
      md.writeln(
        '| `${r.spec.displayName}` | ${r.spec.target} | ${r.total} | **${r.passFailLabel}** |',
      );
    }
    md.writeln(
      '| **Total Automated Test Suite** | **$totalFiles Test Files** | **$grandTotal** | **$grandPassFail** |',
    );
    File(stepSummaryPath).writeAsStringSync(
      md.toString(),
      mode: FileMode.append,
    );
  }

  if (totalFailed > 0 || totalPassed != 110) {
    stderr.writeln(
      '\nERROR: Expected 110 passing tests with 0 failures, but got $totalPassed passed and $totalFailed failed.',
    );
    exitCode = 1;
  }
}
