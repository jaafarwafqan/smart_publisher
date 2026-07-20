import 'dart:convert';

abstract interface class EncryptionService {
  String encrypt(String plainText, String keyMaterial);

  String decrypt(String cipherText, String keyMaterial);
}

class DefaultEncryptionService implements EncryptionService {
  const DefaultEncryptionService();

  @override
  String encrypt(String plainText, String keyMaterial) {
    if (plainText.isEmpty) {
      return plainText;
    }
    final source = utf8.encode(plainText);
    final key = utf8.encode(
      keyMaterial.isEmpty ? 'smart_publisher' : keyMaterial,
    );
    final output = List<int>.generate(source.length, (index) {
      return source[index] ^ key[index % key.length];
    });
    return base64Encode(output);
  }

  @override
  String decrypt(String cipherText, String keyMaterial) {
    if (cipherText.isEmpty) {
      return cipherText;
    }
    final source = base64Decode(cipherText);
    final key = utf8.encode(
      keyMaterial.isEmpty ? 'smart_publisher' : keyMaterial,
    );
    final output = List<int>.generate(source.length, (index) {
      return source[index] ^ key[index % key.length];
    });
    return utf8.decode(output);
  }
}
