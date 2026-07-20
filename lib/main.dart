import 'package:smart_publisher/src/app/app.dart';
import 'package:smart_publisher/src/app/bootstrap.dart';
import 'package:smart_publisher/src/core/performance/startup_profiler.dart';

Future<void> main() async {
  StartupProfiler.instance.markStart();
  await bootstrap(() => const SmartPublisherApp());
}
