import 'dart:typed_data';

Uint8List pcmToWav(Uint8List pcmBytes, {
  int sampleRate = 44100,
  int channels = 2,
  int bitsPerSample = 16,
}) {
  int byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  int blockAlign = channels * (bitsPerSample ~/ 8);
  int dataSize = pcmBytes.length;


  final header = BytesBuilder();

  header.add([
    0x52, 0x49, 0x46, 0x46, 
    ..._intToBytes(36 + dataSize, 4),
    0x57, 0x41, 0x56, 0x45,

    // fmt chunk
    0x66, 0x6D, 0x74, 0x20,
    ..._intToBytes(16, 4),
    ..._intToBytes(1, 2),  
    ..._intToBytes(channels, 2),
    ..._intToBytes(sampleRate, 4),
    ..._intToBytes(byteRate, 4),
    ..._intToBytes(blockAlign, 2),
    ..._intToBytes(bitsPerSample, 2),

    // data chunk
    0x64, 0x61, 0x74, 0x61,
    ..._intToBytes(dataSize, 4),
  ]);

  final wav = BytesBuilder();
  wav.add(header.toBytes());
  wav.add(pcmBytes);

  return wav.toBytes();
}

List<int> _intToBytes(int value, int length) {
  final bytes = <int>[];
  for (int i = 0; i < length; i++) {
    bytes.add((value >> (8 * i)) & 0xFF);
  }
  return bytes;
}
