import 'package:flutter/painting.dart';

import '../observability/metrics_registry.dart';

class ImageCacheSnapshot {
  const ImageCacheSnapshot({
    required this.currentSize,
    required this.currentSizeBytes,
    required this.maximumSize,
    required this.maximumSizeBytes,
  });

  final int currentSize;
  final int currentSizeBytes;
  final int maximumSize;
  final int maximumSizeBytes;
}

class ImageCacheManager {
  const ImageCacheManager();

  void configure({int maxEntries = 150, int maxBytes = 150 * 1024 * 1024}) {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = maxEntries;
    cache.maximumSizeBytes = maxBytes;
  }

  ImageCacheSnapshot snapshot() {
    final cache = PaintingBinding.instance.imageCache;
    final snapshot = ImageCacheSnapshot(
      currentSize: cache.currentSize,
      currentSizeBytes: cache.currentSizeBytes,
      maximumSize: cache.maximumSize,
      maximumSizeBytes: cache.maximumSizeBytes,
    );

    globalMetricsRegistry.setGauge(
      'memory.image_cache.bytes',
      snapshot.currentSizeBytes,
    );
    globalMetricsRegistry.setGauge(
      'memory.image_cache.entries',
      snapshot.currentSize,
    );
    return snapshot;
  }
}
