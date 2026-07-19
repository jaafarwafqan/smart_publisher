import 'package:smart_publisher/src/app/app.dart';
import 'package:smart_publisher/src/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const SmartPublisherApp());
}
