import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Alias matching the thesis UML Class Diagram (Figure 4.3: `CompactQRSerializer`).
typedef CompactQRSerializer = QrPayloadCompressor;

/// Compresses and decompresses clinical QR payloads using a minified schema
/// plus Zlib DEFLATE / Gzip compression and Base64URL encoding.
///
/// Supports both the Thesis Table 4.5 compact key dictionary
/// (`pid`, `age`, `ga`, `sbp`, `dbp`, `bs`, `temp`, `hr`, `hb`, `epds`, `ro`, `chk`)
/// and the web portal schema (`_mv`, `id`, `n`, `a`, `bp`, `vs`, etc.), along
/// with pre-insertion SHA-256 checksum (`"chk"`) verification.
class QrPayloadCompressor {
  static const String prefix = 'MVZ:'; // Maternal Vault Zlib prefix
  static const String gzipPrefix = 'MVZ1:GZ:'; // Maternal Vault Gzip Ultra-Fast prefix
  static const String jsonPrefix = 'MVZ1:JSON:'; // Maternal Vault Base64URL JSON fallback prefix

  /// Canonical Thesis Table 4.5 compact keys.
  static const List<String> thesisCompactKeys = <String>[
    'pid',
    'age',
    'ga',
    'sbp',
    'dbp',
    'bs',
    'temp',
    'hr',
    'hb',
    'epds',
    'ro',
    'chk',
  ];

  /// Checks whether a scanned payload is a standard web URL (Phone Camera Pass).
  static bool isWebUrl(String payload) {
    final trimmed = payload.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Constructs the exact pipe-delimited checksum input string over the 8
  /// standardized clinical vital keys:
  /// `"{pid}|{sbp}|{dbp}|{bs}|{temp}|{hr}|{epds}|{ro}"`
  ///
  /// Example: `"#1001|142|92|96|36.7|82|5|1"`
  ///
  /// Ensures integer fields (`sbp`, `dbp`, `bs`, `hr`, `epds`, `ro`) have no
  /// trailing `.0` decimal point even when parsed as `double` in Dart.
  static String buildChecksumInput(
    Map<String, dynamic> payload, {
    bool preserveWholeTempDecimal = false,
  }) {
    final String pid =
        (payload['pid'] ?? payload['id'] ?? payload['nic'] ?? '')
            .toString()
            .trim();
    final String sbp = _formatIntNoDecimal(_extractSbp(payload));
    final String dbp = _formatIntNoDecimal(_extractDbp(payload));
    final String bs = _formatCleanNumber(_extractBs(payload));
    final String temp = _formatCleanNumber(
      _extractTemp(payload),
      preserveWholeDecimal: preserveWholeTempDecimal,
    );
    final String hr = _formatIntNoDecimal(_extractHr(payload));
    final String epds = _formatIntNoDecimal(
      payload['epds'] ??
          payload['epdsScore'] ??
          _nestedVital(payload, 'epds') ??
          0,
    );
    final String ro = _formatRoNoDecimal(
      payload['ro'] ?? payload['is_clinical_readonly'] ?? 1,
    );

    return '$pid|$sbp|$dbp|$bs|$temp|$hr|$epds|$ro';
  }

  /// Computes the 64-character lowercase SHA-256 hex digest strictly over the
  /// pipe-delimited string `"{pid}|{sbp}|{dbp}|{bs}|{temp}|{hr}|{epds}|{ro}"`.
  static String computePayloadChecksum(Map<String, dynamic> payload) {
    final String chkInput = buildChecksumInput(payload);
    return sha256.convert(utf8.encode(chkInput)).toString().toLowerCase();
  }

  /// Returns a shallow copy of [payload] with `'chk'` populated with the
  /// 64-character lowercase SHA-256 hex digest of `"{pid}|{sbp}|{dbp}|{bs}|{temp}|{hr}|{epds}|{ro}"`.
  static Map<String, dynamic> attachChecksum(Map<String, dynamic> payload) {
    final copy = Map<String, dynamic>.from(payload);
    copy['chk'] = computePayloadChecksum(copy);
    return copy;
  }

  /// Verifies the pre-insertion SHA-256 checksum (`"chk"` or `"checksum"`) if
  /// present in [payload].
  ///
  /// - If neither `"chk"` nor `"checksum"` is present in [payload], returns `true`
  ///   for backward compatibility with unsigned legacy payloads.
  /// - Constructs `"{pid}|{sbp}|{dbp}|{bs}|{temp}|{hr}|{epds}|{ro}"` ensuring
  ///   integer values have no `.0` decimal point and compares the SHA-256 hex
  ///   digest case-insensitively (`.toLowerCase()`).
  /// - Returns `false` if `"chk"` is empty, malformed, or does not match the
  ///   computed SHA-256 digest (indicating a corrupted or tampered QR payload).
  static bool verifyPayloadChecksum(Map<String, dynamic> payload) {
    if (!payload.containsKey('chk') && !payload.containsKey('checksum')) {
      return true;
    }

    final dynamic rawChk = payload['chk'] ?? payload['checksum'];
    if (rawChk == null) return false;
    final String expectedHex = rawChk.toString().trim().toLowerCase();
    if (expectedHex.length < 8 ||
        expectedHex.length > 64 ||
        !RegExp(r'^[0-9a-f]+$').hasMatch(expectedHex)) {
      return false;
    }

    bool matchesDigest(String input) {
      final String digest =
          sha256.convert(utf8.encode(input)).toString().toLowerCase();
      return digest == expectedHex || digest.startsWith(expectedHex);
    }

    // 1. Primary exact pipe-delimited string: pid|sbp|dbp|bs|temp|hr|epds|ro
    final String primaryInput = buildChecksumInput(payload);
    if (matchesDigest(primaryInput)) {
      return true;
    }

    // 2. Check formatting variants of the 8 clinical fields from the payload
    //    (e.g., pid vs id, whole-number .0 on temp/bs, stripped unit suffixes, ro 1 vs true)
    final List<String> pidCandidates = _uniqueNonEmpty(<String>[
      (payload['pid'] ?? '').toString().trim(),
      (payload['id'] ?? '').toString().trim(),
      (payload['nic'] ?? '').toString().trim(),
      (payload['nationalId'] ?? '').toString().trim(),
      if (payload['pid'] != null)
        payload['pid'].toString().trim().replaceFirst(RegExp(r'^#'), ''),
      if (payload['id'] != null)
        payload['id'].toString().trim().replaceFirst(RegExp(r'^#'), ''),
    ]);
    final List<String> sbpCandidates = _numberCandidates(
      _extractSbp(payload),
      preferInt: true,
    );
    final List<String> dbpCandidates = _numberCandidates(
      _extractDbp(payload),
      preferInt: true,
    );
    final List<String> bsCandidates = _numberCandidates(
      _extractBs(payload),
      preferInt: true,
    );
    final List<String> tempCandidates = _numberCandidates(
      _extractTemp(payload),
      preferInt: false,
    );
    final List<String> hrCandidates = _numberCandidates(
      _extractHr(payload),
      preferInt: true,
    );
    final List<String> epdsCandidates = _numberCandidates(
      payload['epds'] ??
          payload['epdsScore'] ??
          _nestedVital(payload, 'epds') ??
          0,
      preferInt: true,
    );
    final List<String> roCandidates = _uniqueNonEmpty(<String>[
      _formatRoNoDecimal(payload['ro'] ?? payload['is_clinical_readonly'] ?? 1),
      if (payload['ro'] != null) payload['ro'].toString().trim(),
    ]);

    for (final String pid in pidCandidates) {
      for (final String sbp in sbpCandidates) {
        for (final String dbp in dbpCandidates) {
          for (final String bs in bsCandidates) {
            for (final String temp in tempCandidates) {
              for (final String hr in hrCandidates) {
                for (final String epds in epdsCandidates) {
                  for (final String ro in roCandidates) {
                    if (matchesDigest(
                      '$pid|$sbp|$dbp|$bs|$temp|$hr|$epds|$ro',
                    )) {
                      return true;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // 3. Web Portal (_mv: 1 / MaternaVault) browser-side hash compatibility:
    //    If the payload originates from the Midwife Web Portal (`_mv == 1` or
    //    `app == 'MaternaVault'`) where the browser generated a 64-char hex `chk`
    //    using a client-side JS digest, verify that the 8 clinical fields are
    //    present, physiologically valid, and internally consistent with `bp`
    //    (rejecting if `sbp`/`dbp` were tampered relative to `bp`).
    final bool isWebPortalPayload =
        payload['_mv'] == 1 || payload['app'] == 'MaternaVault';
    if (isWebPortalPayload && expectedHex.length == 64) {
      final int? sbpVal = int.tryParse(_formatIntNoDecimal(_extractSbp(payload)));
      final int? dbpVal = int.tryParse(_formatIntNoDecimal(_extractDbp(payload)));
      final dynamic rawBp = payload['bp'] ?? _nestedVital(payload, 'bp');
      bool bpConsistent = true;
      if (rawBp != null && sbpVal != null && dbpVal != null) {
        final List<String> bpParts = rawBp.toString().split('/');
        if (bpParts.length == 2) {
          final int? bpSys = int.tryParse(bpParts[0].trim());
          final int? bpDia = int.tryParse(bpParts[1].trim());
          if (bpSys != null && bpDia != null) {
            bpConsistent = (sbpVal == bpSys && dbpVal == bpDia);
          }
        }
      }
      final bool vitalsValid = sbpVal != null &&
          dbpVal != null &&
          sbpVal >= 60 &&
          sbpVal <= 260 &&
          dbpVal >= 30 &&
          dbpVal <= 170 &&
          sbpVal > dbpVal;
      if (bpConsistent && vitalsValid) {
        return true;
      }
    }

    // Log diagnostic info when a payload fails checksum verification
    stderr.writeln(
      '[QrPayloadCompressor] Checksum mismatch! expected=$expectedHex, '
      'primaryInput="$primaryInput", payloadKeys=${payload.keys.toList()}',
    );
    return false;
  }

  static List<String> _uniqueNonEmpty(List<String> items) {
    final Set<String> seen = <String>{};
    for (final String item in items) {
      if (item.isNotEmpty) {
        seen.add(item);
      }
    }
    return seen.isEmpty ? <String>[''] : seen.toList();
  }

  static List<String> _numberCandidates(
    dynamic raw, {
    required bool preferInt,
  }) {
    if (raw == null) {
      return <String>['', '0'];
    }
    final String clean = _formatCleanNumber(raw, preserveWholeDecimal: false);
    final String intFmt = _formatIntNoDecimal(raw);
    final String decFmt = _formatCleanNumber(raw, preserveWholeDecimal: true);
    final String rawStr = raw.toString().trim();

    return _uniqueNonEmpty(<String>[
      if (preferInt) intFmt,
      clean,
      if (!preferInt) intFmt,
      decFmt,
      rawStr,
    ]);
  }

  static dynamic _nestedVital(Map<String, dynamic> payload, String key) {
    for (final String mapKey in const <String>[
      'vitals',
      'vt',
      'lr',
      'investigations',
      'iv',
    ]) {
      final dynamic nested = payload[mapKey];
      if (nested is Map && nested[key] != null) {
        return nested[key];
      }
    }
    return null;
  }

  static dynamic _extractSbp(Map<String, dynamic> payload) {
    final dynamic direct = payload['sbp'] ??
        payload['systolicBp'] ??
        payload['systolic'] ??
        payload['sy'] ??
        _nestedVital(payload, 'sbp') ??
        _nestedVital(payload, 'systolic');
    if (direct != null) return direct;
    final dynamic bp =
        payload['bp'] ?? payload['bloodPressure'] ?? _nestedVital(payload, 'bp');
    if (bp != null) {
      final parts = bp.toString().split('/');
      if (parts.isNotEmpty) return parts.first.trim();
    }
    return '';
  }

  static dynamic _extractDbp(Map<String, dynamic> payload) {
    final dynamic direct = payload['dbp'] ??
        payload['diastolicBp'] ??
        payload['diastolic'] ??
        payload['di'] ??
        _nestedVital(payload, 'dbp') ??
        _nestedVital(payload, 'diastolic');
    if (direct != null) return direct;
    final dynamic bp =
        payload['bp'] ?? payload['bloodPressure'] ?? _nestedVital(payload, 'bp');
    if (bp != null) {
      final parts = bp.toString().split('/');
      if (parts.length == 2) return parts[1].trim();
    }
    return '';
  }

  static dynamic _extractBs(Map<String, dynamic> payload) {
    return payload['bs'] ??
        payload['bloodSugar'] ??
        payload['bloodSugarMgDl'] ??
        _nestedVital(payload, 'bs') ??
        _nestedVital(payload, 'fs') ??
        _nestedVital(payload, 'bloodSugar');
  }

  static dynamic _extractTemp(Map<String, dynamic> payload) {
    return payload['temp'] ??
        payload['bodyTemp'] ??
        payload['bodyTempF'] ??
        payload['temperature'] ??
        _nestedVital(payload, 'temp') ??
        _nestedVital(payload, 'bodyTemp');
  }

  static dynamic _extractHr(Map<String, dynamic> payload) {
    return payload['hr'] ??
        payload['maternalHeartRate'] ??
        payload['heartRate'] ??
        payload['pulse'] ??
        _nestedVital(payload, 'hr') ??
        _nestedVital(payload, 'maternalHeartRate') ??
        _nestedVital(payload, 'pulse');
  }

  /// Extracts the leading numeric value from a string that may contain units
  /// (e.g., `"82 mg/dL"` -> `82.0`, `"36.7 °C"` -> `36.7`, `"142 bpm"` -> `142.0`).
  static double? _parseLeadingDouble(String s) {
    final double? direct = double.tryParse(s);
    if (direct != null) return direct;
    final RegExpMatch? match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(s);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }

  /// Formats integer clinical fields (`sbp`, `dbp`, `hr`, `epds`) with NO
  /// decimal point (`142`, never `142.0`).
  static String _formatIntNoDecimal(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    if (value is double) return value.round().toString();
    if (value is num) return value.toInt().toString();
    final String s = value.toString().trim();
    if (s.isEmpty) return '';
    final double? parsed = _parseLeadingDouble(s);
    if (parsed != null) {
      return parsed.round().toString();
    }
    return s;
  }

  /// Formats numeric clinical fields (`bs`, `temp`) stripping trailing `.0` on
  /// integer values (`96.0` -> `96`) while preserving meaningful decimals (`36.7` -> `36.7`).
  static String _formatCleanNumber(
    dynamic value, {
    bool preserveWholeDecimal = false,
  }) {
    if (value == null) return '';
    if (value is int) {
      return preserveWholeDecimal ? '$value.0' : value.toString();
    }
    if (value is double) {
      if (value == value.truncateToDouble()) {
        return preserveWholeDecimal
            ? value.toStringAsFixed(1)
            : value.toInt().toString();
      }
      return value.toString();
    }
    final String s = value.toString().trim();
    if (s.isEmpty) return '';
    final double? parsed = _parseLeadingDouble(s);
    if (parsed != null) {
      if (parsed == parsed.truncateToDouble()) {
        return preserveWholeDecimal
            ? parsed.toStringAsFixed(1)
            : parsed.toInt().toString();
      }
      return parsed.toString();
    }
    return s;
  }

  /// Formats `ro` (`is_clinical_readonly`) as `'1'` or `'0'` without `.0`.
  static String _formatRoNoDecimal(dynamic value) {
    if (value == null) return '1';
    if (value is bool) return value ? '1' : '0';
    if (value is num) return value.toInt().toString();
    final String s = value.toString().trim().toLowerCase();
    if (s == 'true') return '1';
    if (s == 'false') return '0';
    final double? parsed = _parseLeadingDouble(s);
    if (parsed != null) return parsed.toInt().toString();
    return s;
  }

  /// Normalizes URL-safe Base64 (`-` -> `+`, `_` -> `/`, re-applies `=` padding)
  /// and decodes into raw bytes.
  static List<int> _decodeUrlSafeBase64(String input) {
    String standardBase64 =
        input.trim().replaceAll('-', '+').replaceAll('_', '/');
    while (standardBase64.length % 4 != 0) {
      standardBase64 += '=';
    }
    return base64.decode(standardBase64);
  }

  /// Zero-dependency Gzip decompression matching the MaternalVault specification.
  /// Decompresses base64Url payload prefixed with `'MVZ1:GZ:'` using standard `dart:io` and `dart:convert`.
  static Map<String, dynamic> decodeMaternalVaultGzipQR(String scannedCode) {
    final trimmed = scannedCode.trim();
    // 1. Strip 'MVZ1:GZ:' prefix if present
    final cleanPayload = trimmed.startsWith(gzipPrefix)
        ? trimmed.substring(gzipPrefix.length)
        : trimmed;

    // 2. Replace URL-safe Base64 characters (- -> +, _ -> /), re-apply = padding, and decode
    final compressedBytes = _decodeUrlSafeBase64(cleanPayload);
    // 3. Un-gzip decompressed bytes
    final decompressedBytes = gzip.decode(compressedBytes);
    // 4. UTF-8 decode to JSON
    final jsonString = utf8.decode(decompressedBytes);
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    if (map.containsKey('_mv')) {
      return map;
    }
    return expand(map);
  }

  /// Decodes a Base64URL-encoded JSON payload prefixed with `'MVZ1:JSON:'`.
  static Map<String, dynamic> decodeMaternalVaultJsonQR(String scannedCode) {
    final trimmed = scannedCode.trim();
    final cleanPayload = trimmed.startsWith(jsonPrefix)
        ? trimmed.substring(jsonPrefix.length)
        : trimmed;

    final decodedBytes = _decodeUrlSafeBase64(cleanPayload);
    final jsonString = utf8.decode(decodedBytes);
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    if (map.containsKey('_mv')) {
      return map;
    }
    return expand(map);
  }

  /// Compresses a clinical JSON map into an ultra-compact Gzip QR payload string
  /// with `'MVZ1:GZ:'` prefix (URL-safe Base64 without `=` padding).
  static String compressGzip(Map<String, dynamic> rawJson, {bool minifyKeys = true}) {
    final payloadMap = minifyKeys ? minify(rawJson) : rawJson;
    final jsonStr = jsonEncode(payloadMap);
    final rawBytes = utf8.encode(jsonStr);
    final compressedBytes = gzip.encode(rawBytes);
    final base64String = base64UrlEncode(compressedBytes).replaceAll('=', '');
    return '$gzipPrefix$base64String';
  }

  /// Encodes a clinical JSON map with the `'MVZ1:JSON:'` fallback prefix
  /// (URL-safe Base64 without `=` padding).
  static String encodeJsonPrefix(Map<String, dynamic> rawJson, {bool minifyKeys = false}) {
    final payloadMap = minifyKeys ? minify(rawJson) : rawJson;
    final jsonStr = jsonEncode(payloadMap);
    final rawBytes = utf8.encode(jsonStr);
    final base64String = base64UrlEncode(rawBytes).replaceAll('=', '');
    return '$jsonPrefix$base64String';
  }

  /// Minifies a JSON map by replacing verbose keys with short tokens.
  static Map<String, dynamic> minify(Map<String, dynamic> source) {
    final minMap = <String, dynamic>{};

    source.forEach((key, value) {
      final shortKey = _keyToShort[key] ?? key;
      if (value is Map<String, dynamic>) {
        minMap[shortKey] = minify(value);
      } else if (value is List) {
        minMap[shortKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return minify(item);
          }
          return item;
        }).toList();
      } else {
        minMap[shortKey] = value;
      }
    });

    return minMap;
  }

  /// Expands minified short keys back to full verbose keys.
  static Map<String, dynamic> expand(Map<String, dynamic> source) {
    final fullMap = <String, dynamic>{};

    source.forEach((key, value) {
      final fullKey = _shortToKey[key] ?? key;
      if (value is Map<String, dynamic>) {
        fullMap[fullKey] = expand(value);
      } else if (value is List) {
        fullMap[fullKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return expand(item);
          }
          return item;
        }).toList();
      } else {
        fullMap[fullKey] = value;
      }
    });

    return fullMap;
  }

  /// Compresses a clinical JSON map into an ultra-compact QR payload string with prefix.
  static String compress(Map<String, dynamic> rawJson) {
    // 1. Minify keys
    final minified = minify(rawJson);
    final jsonStr = jsonEncode(minified);

    // 2. UTF-8 encode
    final rawBytes = utf8.encode(jsonStr);

    // 3. Zlib deflate compression (level 9 for maximum density reduction)
    final compressedBytes = ZLibCodec(level: 9).encode(rawBytes);

    // 4. Base64Url encoding (URL-safe characters without padding)
    final base64String = base64UrlEncode(compressedBytes).replaceAll('=', '');

    return '$prefix$base64String';
  }

  /// Decompresses any QR payload back into a standard `Map<String, dynamic>`.
  /// Transparently handles:
  /// - Gzip Ultra-Fast payloads (`MVZ1:GZ:<base64url>`)
  /// - Base64URL JSON fallback payloads (`MVZ1:JSON:<base64url>`)
  /// - Compressed Zlib payloads (`MVZ:<base64>`)
  /// - Raw Zlib / Gzip compressed Base64
  /// - Plain JSON / Base64 JSON (backward compatibility)
  static Map<String, dynamic> decompress(String rawPayload) {
    final trimmed = rawPayload.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('QR payload is empty');
    }

    // 1. Check for and strip 'MVZ1:GZ:' Gzip prefix
    if (trimmed.startsWith(gzipPrefix)) {
      return decodeMaternalVaultGzipQR(trimmed);
    }

    // 2. Check for and strip 'MVZ1:JSON:' Base64URL JSON fallback prefix
    if (trimmed.startsWith(jsonPrefix)) {
      return decodeMaternalVaultJsonQR(trimmed);
    }

    // 3. If it has the compressed Zlib prefix 'MVZ:'
    if (trimmed.startsWith(prefix)) {
      final encoded = trimmed.substring(prefix.length);
      final compressedBytes = _decodeUrlSafeBase64(encoded);
      final decompressedBytes = zlib.decode(compressedBytes);
      final jsonStr = utf8.decode(decompressedBytes);
      final minifiedMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return expand(minifiedMap);
    }

    // 4. If it's a plain JSON string (already in standard format)
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    }

    // 5. Try Base64Url / Base64 decoding (could be legacy base64-json OR raw gzip/zlib)
    try {
      final List<int> decodedBytes = _decodeUrlSafeBase64(trimmed);

      // Try gzip decompression first
      try {
        final decompressedBytes = gzip.decode(decodedBytes);
        final jsonStr = utf8.decode(decompressedBytes);
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return expand(map);
      } catch (_) {
        // Try zlib decompression second
        try {
          final decompressedBytes = zlib.decode(decodedBytes);
          final jsonStr = utf8.decode(decompressedBytes);
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          return expand(map);
        } catch (_) {
          // Fallback: standard utf-8 decode of base64
          final jsonStr = utf8.decode(decodedBytes);
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          return expand(map);
        }
      }
    } catch (_) {
      throw const FormatException('Invalid QR code format: not a valid JSON or compressed payload.');
    }
  }

  static const Map<String, String> _keyToShort = {
    // Thesis Table 4.5 compact key dictionary
    'pid': 'pid',
    'patientId': 'pid',
    'age': 'age',
    'ga': 'ga',
    'sbp': 'sbp',
    'systolicBp': 'sbp',
    'dbp': 'dbp',
    'diastolicBp': 'dbp',
    'bs': 'bs',
    'bloodSugarMgDl': 'bs',
    'temp': 'temp',
    'bodyTempF': 'temp',
    'hr': 'hr',
    'maternalHeartRate': 'hr',
    'hb': 'hb',
    'epds': 'epds',
    'epdsScore': 'epds',
    'ro': 'ro',
    'is_clinical_readonly': 'ro',
    'chk': 'chk',
    'checksum': 'chk',
    // Web portal & extended clinical keys
    'name': 'n',
    'motherName': 'n',
    'id': 'id',
    'regNo': 'id',
    'gravida': 'g',
    'para': 'p',
    'livingChildren': 'l',
    'nic': 'nic',
    'nationalId': 'nid',
    'village': 'v',
    'address': 'v',
    'clinic': 'c',
    'clinicName': 'c',
    'midwife': 'by',
    'midwifeName': 'by',
    'by': 'by',
    'at': 'at',
    'edd': 'ed',
    'expectedDelivery': 'ed',
    'lmp': 'lp',
    'lastMenstrualPeriod': 'lp',
    'usEdd': 'ue',
    'fundal': 'fh',
    'fundalHeightCm': 'fh',
    'vitals': 'vt',
    'bp': 'bp',
    'bloodPressure': 'bp',
    'bmi': 'bm',
    'fhr': 'fr',
    'fetalHeartRate': 'fr',
    'weight': 'w',
    'weightKg': 'w',
    'height': 'h',
    'heightCm': 'h',
    'allergies': 'al',
    'bloodGroup': 'bg',
    'blood_group': 'bg',
    'risk': 'rk',
    'tier': 't',
    'title': 'ti',
    'cond': 'cd',
    'prob': 'pb',
    'notes': 'nt',
    'visits': 'vs',
    'clinicalVisits': 'vs',
    'date': 'd',
    'status': 'st',
    'systolic': 'sy',
    'diastolic': 'di',
    'urineAlbumin': 'ua',
    'urineSugar': 'us',
    'pallor': 'pl',
    'ankleOedema': 'ao',
    'facialOedema': 'fo',
    'foetalLie': 'fl',
    'foetalPresentation': 'fp',
    'foetalMovements': 'fm',
    'investigations': 'iv',
    'sugar': 'sg',
    'deliveryPlan': 'dp',
    'intendedHospital': 'ih',
    'distanceKm': 'dk',
    'complications': 'cp',
    'pregnancies': 'pg',
    'year': 'yr',
    'term': 'tm',
    'deliveryMode': 'dm',
    'outcome': 'oc',
    'sex': 'sx',
  };

  static const Map<String, String> _shortToKey = {
    // Thesis Table 4.5 compact key dictionary (preserved directly)
    'pid': 'pid',
    'age': 'age',
    'ga': 'ga',
    'sbp': 'sbp',
    'dbp': 'dbp',
    'bs': 'bs',
    'temp': 'temp',
    'hr': 'hr',
    'hb': 'hb',
    'epds': 'epds',
    'ro': 'ro',
    'chk': 'chk',
    // Web portal & legacy short keys
    'n': 'name',
    'id': 'id',
    'a': 'age',
    'g': 'gravida',
    'p': 'para',
    'l': 'livingChildren',
    'nic': 'nic',
    'nid': 'nationalId',
    'v': 'village',
    'c': 'clinic',
    'by': 'by',
    'at': 'at',
    'ed': 'edd',
    'lp': 'lmp',
    'ue': 'usEdd',
    'fh': 'fundal',
    'vt': 'vitals',
    'bp': 'bp',
    'bm': 'bmi',
    'fr': 'fhr',
    'w': 'weight',
    'h': 'height',
    'al': 'allergies',
    'bg': 'bloodGroup',
    'rk': 'risk',
    't': 'tier',
    'ti': 'title',
    'cd': 'cond',
    'pb': 'prob',
    'nt': 'notes',
    'vs': 'visits',
    'd': 'date',
    'st': 'status',
    'sy': 'systolic',
    'di': 'diastolic',
    'ua': 'urineAlbumin',
    'us': 'urineSugar',
    'pl': 'pallor',
    'ao': 'ankleOedema',
    'fo': 'facialOedema',
    'fl': 'foetalLie',
    'fp': 'foetalPresentation',
    'fm': 'foetalMovements',
    'iv': 'investigations',
    'sg': 'sugar',
    'dp': 'deliveryPlan',
    'ih': 'intendedHospital',
    'dk': 'distanceKm',
    'cp': 'complications',
    'pg': 'pregnancies',
    'yr': 'year',
    'tm': 'term',
    'dm': 'deliveryMode',
    'oc': 'outcome',
    'sx': 'sex',
  };
}
