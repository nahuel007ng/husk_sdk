import 'dart:io';
import 'dart:typed_data';

/// How a binary inside a framework links.
enum Linkage {
  /// A static archive (`ar`), linked into the app binary.
  static,

  /// A dynamic library, embedded in the app bundle.
  dynamic,

  /// Not recognised.
  unknown,
}

/// Reads just enough of [file] to tell a static archive from a dynamic
/// library, looking through a universal (fat) wrapper at the first slice.
Linkage detectLinkage(File file) {
  RandomAccessFile? raf;
  try {
    raf = file.openSync();
    return _detect(raf, 0, allowFat: true);
  } on FileSystemException {
    return Linkage.unknown;
  } finally {
    raf?.closeSync();
  }
}

Linkage _detect(RandomAccessFile raf, int offset, {required bool allowFat}) {
  final length = raf.lengthSync();
  if (offset < 0 || offset + 32 > length) return Linkage.unknown;
  raf.setPositionSync(offset);
  final head = Uint8List.fromList(raf.readSync(32));
  if (head.length < 16) return Linkage.unknown;
  if (String.fromCharCodes(head.sublist(0, 8)) == '!<arch>\n') {
    return Linkage.static;
  }
  final view = ByteData.sublistView(head);
  final be = view.getUint32(0);
  if (allowFat && (be == 0xcafebabe || be == 0xcafebabf)) {
    final count = view.getUint32(4);
    if (count == 0 || count > 32) return Linkage.unknown;
    final int sliceOffset;
    if (be == 0xcafebabe) {
      sliceOffset = view.getUint32(8 + 8);
    } else {
      sliceOffset =
          view.getUint32(8 + 8) * 0x100000000 + view.getUint32(8 + 12);
    }
    return _detect(raf, sliceOffset, allowFat: false);
  }
  final le = view.getUint32(0, Endian.little);
  if (le == 0xfeedfacf || le == 0xfeedface) {
    const mhDylib = 6;
    return view.getUint32(12, Endian.little) == mhDylib
        ? Linkage.dynamic
        : Linkage.unknown;
  }
  return Linkage.unknown;
}
