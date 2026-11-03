import 'package:comicstream_app/core/validation/profile_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('username rejects blank and short input, accepts trimmed names', () {
    expect(ProfileValidation.username(null), 'Username tidak boleh kosong');
    expect(ProfileValidation.username('  '), 'Username tidak boleh kosong');
    expect(ProfileValidation.username(' ab '), 'Username minimal 3 karakter');
    expect(ProfileValidation.username(' abcd '), isNull);
  });
}
