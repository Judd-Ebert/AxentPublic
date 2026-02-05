import 'dart:convert';
import 'package:crypto/crypto.dart';

String buildRecombeeUrl(String query, String userId, int count) {
  final databaseId = 'axent-dev';
  final publicToken =
      'rRwGfBTEEFjAAsdQJgNE7DeZ0MofM1hfBwbS7B5xD6bA3VTxXptecN71Cxro8nw2';

  final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final preUrl = 'https://client-rapi-us-west.recombee.com';

  // Build the path with query params (no protocol/host)
  final path = '/$databaseId/search/users/$userId/items/';
  final queryString =
      'searchQuery=${Uri.encodeComponent(query)}&frontend_timestamp=$timestamp&count=$count&returnProperties=true&includedProperties=brand,title,retailprice,image';
  final pathToSign = '$path?$queryString';

  // Step 2: HMAC-SHA1 signature
  final hmac = Hmac(sha1, utf8.encode(publicToken));
  final digest = hmac.convert(utf8.encode(pathToSign)).toString();

  // Step 3: Append signature to URL
  final signedUrl = '$preUrl$pathToSign&frontend_sign=$digest';

  return signedUrl;
}