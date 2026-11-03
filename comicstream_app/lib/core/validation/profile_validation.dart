/// Input rules for editing the public profile.
class ProfileValidation {
  static String? username(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Username tidak boleh kosong';
    if (username.length < 3) return 'Username minimal 3 karakter';
    return null;
  }
}
