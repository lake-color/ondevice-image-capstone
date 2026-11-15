// Read-only inspection of the bundled model using Google's FlatBuffer schemas.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Reader {
  Reader(this.bytes) : data = ByteData.sublistView(bytes);
  final Uint8List bytes;
  final ByteData data;
  int u32(int p) => data.getUint32(p, Endian.little);
  int i32(int p) => data.getInt32(p, Endian.little);
  int u16(int p) => data.getUint16(p, Endian.little);
  int get root => u32(0);
  int field(int table, int index) {
    final v = table - i32(table);
    final p = 4 + 2 * index;
    final offset = p < u16(v) ? u16(v + p) : 0;
    return offset == 0 ? 0 : table + offset;
  }

  int indirect(int p) => p == 0 ? 0 : p + u32(p);
  String? string(int table, int index) {
    final p = indirect(field(table, index));
    return p == 0 ? null : utf8.decode(bytes.sublist(p + 4, p + 4 + u32(p)));
  }

  List<T> vector<T>(int table, int index, T Function(int) read) {
    final p = indirect(field(table, index));
    return p == 0 ? [] : List.generate(u32(p), (i) => read(p + 4 + 4 * i));
  }
}

void main() {
  final bytes = File('assets/models/mobilenet_v3_small.tflite')
      .readAsBytesSync();
  final r = Reader(bytes);
  if (ascii.decode(bytes.sublist(4, 8)) != 'TFL3') {
    throw const FormatException('Not TFLite');
  }
  final graph = r.vector(r.root, 2, r.indirect).first;
  final tensors = r.vector(graph, 0, r.indirect);
  Map<String, Object?> describe(int index) {
    final t = tensors[index];
    return {
      'name': r.string(t, 3),
      'shape': r.vector(t, 0, r.i32),
      'type': r.field(t, 1) == 0 ? 0 : r.data.getUint8(r.field(t, 1)),
    };
  }

  final buffers = r.vector(r.root, 4, r.indirect);
  final entry = r
      .vector(r.root, 6, r.indirect)
      .firstWhere((t) => r.string(t, 0) == 'TFLITE_METADATA');
  final buffer = buffers[r.u32(r.field(entry, 1))];
  final p = r.indirect(r.field(buffer, 0));
  final m = Reader(Uint8List.sublistView(bytes, p + 4, p + 4 + r.u32(p)));
  final mg = m.vector(m.root, 3, m.indirect).first;
  final input = m.vector(mg, 2, m.indirect).first;
  final processes = m.vector(input, 4, m.indirect).map((t) {
    final options = m.indirect(m.field(t, 1));
    return {
      'type': m.data.getUint8(m.field(t, 0)),
      'mean': m.vector(options, 0, (p) => m.data.getFloat32(p, Endian.little)),
      'std': m.vector(options, 1, (p) => m.data.getFloat32(p, Endian.little)),
    };
  }).toList();
  final last = r.vector(graph, 3, r.indirect).last;
  final codes = r.vector(r.root, 1, r.indirect);
  final code = codes[r.field(last, 0) == 0 ? 0 : r.u32(r.field(last, 0))];
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'bytes': bytes.length,
      'inputs': r.vector(graph, 1, r.i32).map(describe).toList(),
      'outputs': r.vector(graph, 2, r.i32).map(describe).toList(),
      'lastOperatorCode': r.field(code, 3) == 0
          ? r.data.getInt8(r.field(code, 0))
          : r.i32(r.field(code, 3)),
      'operatorCodes': codes
          .map(
            (c) => r.field(c, 3) == 0
                ? r.data.getInt8(r.field(c, 0))
                : r.i32(r.field(c, 3)),
          )
          .toList(),
      'name': m.string(m.root, 0),
      'description': m.string(m.root, 1),
      'license': m.string(m.root, 5),
      'processes': processes,
    }),
  );
}
