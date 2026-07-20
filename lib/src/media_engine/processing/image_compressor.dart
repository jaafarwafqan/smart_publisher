class ImageCompressor {
  const ImageCompressor({this.quality = 78});

  final int quality;

  int compressSize(int originalSizeInBytes) {
    final boundedQuality = quality.clamp(10, 100);
    final ratio = boundedQuality / 100.0;
    final estimated = (originalSizeInBytes * ratio).round();
    return estimated <= 0 ? 1 : estimated;
  }
}
