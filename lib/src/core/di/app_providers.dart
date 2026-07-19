import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_network_client.dart';
import '../network/network_client.dart';

final networkClientProvider = Provider<NetworkClient>((ref) {
  return DioNetworkClient();
});
