import 'dart:convert';

/// Portable account labels and appearance only. This is never a login backup.
class AccountSetupEntry {
  const AccountSetupEntry({required this.alias, required this.color});
  final String alias;
  final int color;
}

class AccountSetupArchive {
  AccountSetupArchive({
    required List<AccountSetupEntry> accounts,
    this.theme = 'system',
  }) : accounts = List.unmodifiable(accounts);

  static const format = 'profile-desk-account-setup';
  static const maxBytes = 64 * 1024;
  final List<AccountSetupEntry> accounts;
  final String theme;

  static Map<String, dynamic> _object(Object? value, Set<String> keys) {
    if (value is! Map<String, dynamic> ||
        value.length != keys.length ||
        !keys.containsAll(value.keys)) {
      throw const FormatException('Invalid account setup fields');
    }
    return value;
  }

  factory AccountSetupArchive.decode(String source) {
    if (source.length > maxBytes || utf8.encode(source).length > maxBytes) {
      throw const FormatException('Account setup file is too large');
    }
    _checkJsonStructure(source);
    final root = _object(jsonDecode(source), {
      'format',
      'version',
      'requiresRelinking',
      'accounts',
      'appearance',
    });
    if (root['format'] != format ||
        root['version'] is! int ||
        root['version'] != 1 ||
        root['requiresRelinking'] != true) {
      throw const FormatException('Unsupported account setup format');
    }
    final appearance = _object(root['appearance'], {'theme'});
    final theme = appearance['theme'];
    if (theme is! String || !{'system', 'light', 'dark'}.contains(theme)) {
      throw const FormatException('Invalid appearance');
    }
    final values = root['accounts'];
    if (values is! List || values.length > 10) {
      throw const FormatException('Use at most ten accounts');
    }
    final names = <String>{};
    final entries = <AccountSetupEntry>[];
    for (final value in values) {
      final row = _object(value, {'alias', 'color'});
      final alias = row['alias'];
      final color = row['color'];
      if (alias is! String ||
          !validAlias(alias) ||
          color is! int ||
          color < 0 ||
          color > 0xffffffff ||
          !names.add(alias.trim().toLowerCase())) {
        throw const FormatException('Invalid or duplicate account');
      }
      entries.add(AccountSetupEntry(alias: alias.trim(), color: color));
    }
    return AccountSetupArchive(accounts: entries, theme: theme);
  }

  static bool validAlias(String value) {
    final alias = value.trim();
    return alias.isNotEmpty &&
        alias.runes.length <= 40 &&
        !alias.runes.any(
          (r) =>
              r < 32 || (r >= 127 && r <= 159) || (r >= 0xd800 && r <= 0xdfff),
        );
  }

  // jsonDecode deliberately accepts duplicate keys. Reject them before it can
  // discard an earlier value, and bound nesting before the parser is invoked.
  // This scan only validates structure; jsonDecode remains the JSON parser.
  static void _checkJsonStructure(String source) {
    final stack = <({Set<String>? keys, bool expectingKey})>[];
    for (var index = 0; index < source.length; index++) {
      final unit = source.codeUnitAt(index);
      if (unit == 34) {
        final start = index++;
        var escaped = false;
        for (; index < source.length; index++) {
          final next = source.codeUnitAt(index);
          if (escaped) {
            escaped = false;
          } else if (next == 92) {
            escaped = true;
          } else if (next == 34) {
            break;
          }
        }
        if (index >= source.length)
          throw const FormatException('Invalid JSON string');
        if (stack.isNotEmpty && stack.last.expectingKey) {
          final key = jsonDecode(source.substring(start, index + 1)) as String;
          final frame = stack.removeLast();
          if (!frame.keys!.add(key))
            throw const FormatException('Duplicate account setup field');
          stack.add((keys: frame.keys, expectingKey: false));
        }
      } else if (unit == 123 || unit == 91) {
        if (stack.length >= 3)
          throw const FormatException('Invalid account setup nesting');
        stack.add((
          keys: unit == 123 ? <String>{} : null,
          expectingKey: unit == 123,
        ));
      } else if (unit == 125 || unit == 93) {
        if (stack.isEmpty)
          throw const FormatException('Invalid JSON container');
        stack.removeLast();
      } else if (unit == 44 && stack.isNotEmpty && stack.last.keys != null) {
        final frame = stack.removeLast();
        stack.add((keys: frame.keys, expectingKey: true));
      }
    }
  }

  String encode() {
    final source = jsonEncode({
      'format': format,
      'version': 1,
      'requiresRelinking': true,
      'accounts': [
        for (final account in accounts)
          {'alias': account.alias, 'color': account.color},
      ],
      'appearance': {'theme': theme},
    });
    AccountSetupArchive.decode(source);
    return source;
  }
}
