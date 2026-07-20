class VideoCompressor {
  const VideoCompressor({this.targetBitrateRatio = 0.65});

  final double targetBitrateRatio;

  int compressSize(int originalSizeInBytes) {
    final ratio = targetBitrateRatio.clamp(0.1, 1.0);
    final estimated = (originalSizeInBytes * ratio).round();
    return estimated <= 0 ? 1 : estimated;
  }
}
