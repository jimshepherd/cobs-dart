import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'package:cobs/cobs.dart';

void main() {
  Function eq = const ListEquality().equals;

  group('Encode and decode byte data using COBS', () {
    test('encodeCOBS returns error with null source data', () {
      ByteData source;
      var encoded = ByteData(1);
      EncodeResult encodeResult = encodeCOBS(encoded, source);
      expect(encodeResult.status, EncodeStatus.NULL_POINTER);
      expect(encodeResult.outLen, 0);
    });

    test('decodeCOBS returns error with null source data', () {
      ByteData source;
      var decoded = ByteData(1);
      DecodeResult decodeResult = decodeCOBS(decoded, source);
      expect(decodeResult.status, DecodeStatus.NULL_POINTER);
      expect(decodeResult.outLen, 0);
    });

    test('encode / decode all zeroes data', () {
      var data = new Uint8List.fromList([0, 0, 0, 0]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 5);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 5);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 4);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 4);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List()),
          true);
    });

    test('encode / decode data with no zeroes', () {
      var data = new Uint8List.fromList([1, 2, 3, 4, 5]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 6);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 6);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 5);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 5);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List()),
          true);
    });

    test('encode / decode data with zero at end', () {
      var data = new Uint8List.fromList([1, 2, 3, 4, 5, 0]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 7);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 7);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 6);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 6);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List()),
          true);
    });

    test('encode / decode data with embedded zero', () {
      var data = new Uint8List.fromList([1, 2, 3, 4, 5, 0, 6, 7, 8, 9]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 11);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 11);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 10);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 10);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List()),
          true);
    });

    test('encode / decode data with embedded zero and zero at end', () {
      var data = new Uint8List.fromList([1, 2, 3, 4, 5, 0, 6, 7, 8, 9, 0]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 12);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 12);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 11);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 11);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List()),
          true);
    });

    test('encode / decode data with 253 bytes', () {
      var data = new Uint8List.fromList([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
        115,
        116,
        117,
        118,
        119,
        120,
        121,
        122,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        133,
        134,
        135,
        136,
        137,
        138,
        139,
        140,
        141,
        142,
        143,
        144,
        145,
        146,
        147,
        148,
        149,
        150,
        151,
        152,
        153,
        154,
        155,
        156,
        157,
        158,
        159,
        160,
        161,
        162,
        163,
        164,
        165,
        166,
        167,
        168,
        169,
        170,
        171,
        172,
        173,
        174,
        175,
        176,
        177,
        178,
        179,
        180,
        181,
        182,
        183,
        184,
        185,
        186,
        187,
        188,
        189,
        190,
        191,
        192,
        193,
        194,
        195,
        196,
        197,
        198,
        199,
        200,
        201,
        202,
        203,
        204,
        205,
        206,
        207,
        208,
        209,
        210,
        211,
        212,
        213,
        214,
        215,
        216,
        217,
        218,
        219,
        220,
        221,
        222,
        223,
        224,
        225,
        226,
        227,
        228,
        229,
        230,
        231,
        232,
        233,
        234,
        235,
        236,
        237,
        238,
        239,
        240,
        241,
        242,
        243,
        244,
        245,
        246,
        247,
        248,
        249,
        250,
        251,
        252,
        253
      ]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 254);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 254);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 253);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 253);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List()),
          true);
    });

    test('encode / decode data with 254 bytes', () {
      var data = new Uint8List.fromList([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
        115,
        116,
        117,
        118,
        119,
        120,
        121,
        122,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        133,
        134,
        135,
        136,
        137,
        138,
        139,
        140,
        141,
        142,
        143,
        144,
        145,
        146,
        147,
        148,
        149,
        150,
        151,
        152,
        153,
        154,
        155,
        156,
        157,
        158,
        159,
        160,
        161,
        162,
        163,
        164,
        165,
        166,
        167,
        168,
        169,
        170,
        171,
        172,
        173,
        174,
        175,
        176,
        177,
        178,
        179,
        180,
        181,
        182,
        183,
        184,
        185,
        186,
        187,
        188,
        189,
        190,
        191,
        192,
        193,
        194,
        195,
        196,
        197,
        198,
        199,
        200,
        201,
        202,
        203,
        204,
        205,
        206,
        207,
        208,
        209,
        210,
        211,
        212,
        213,
        214,
        215,
        216,
        217,
        218,
        219,
        220,
        221,
        222,
        223,
        224,
        225,
        226,
        227,
        228,
        229,
        230,
        231,
        232,
        233,
        234,
        235,
        236,
        237,
        238,
        239,
        240,
        241,
        242,
        243,
        244,
        245,
        246,
        247,
        248,
        249,
        250,
        251,
        252,
        253,
        254
      ]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 255);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 255);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 254);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 254);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List()),
          true);
    });

    test('encode / decode data with 255 bytes', () {
      var data = new Uint8List.fromList([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
        115,
        116,
        117,
        118,
        119,
        120,
        121,
        122,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        133,
        134,
        135,
        136,
        137,
        138,
        139,
        140,
        141,
        142,
        143,
        144,
        145,
        146,
        147,
        148,
        149,
        150,
        151,
        152,
        153,
        154,
        155,
        156,
        157,
        158,
        159,
        160,
        161,
        162,
        163,
        164,
        165,
        166,
        167,
        168,
        169,
        170,
        171,
        172,
        173,
        174,
        175,
        176,
        177,
        178,
        179,
        180,
        181,
        182,
        183,
        184,
        185,
        186,
        187,
        188,
        189,
        190,
        191,
        192,
        193,
        194,
        195,
        196,
        197,
        198,
        199,
        200,
        201,
        202,
        203,
        204,
        205,
        206,
        207,
        208,
        209,
        210,
        211,
        212,
        213,
        214,
        215,
        216,
        217,
        218,
        219,
        220,
        221,
        222,
        223,
        224,
        225,
        226,
        227,
        228,
        229,
        230,
        231,
        232,
        233,
        234,
        235,
        236,
        237,
        238,
        239,
        240,
        241,
        242,
        243,
        244,
        245,
        246,
        247,
        248,
        249,
        250,
        251,
        252,
        253,
        254,
        255
      ]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded = ByteData(encodeDstBufMaxLen(initData.lengthInBytes));
      expect(encoded.lengthInBytes, 257);

      EncodeResult encodeResult = encodeCOBS(encoded, initData);
      expect(encodeResult.outLen, 257);
      expect(encodeResult.status, EncodeStatus.OK);

      ByteData decoded = ByteData(decodeDstBufMaxLen(encoded.lengthInBytes));
      expect(decoded.lengthInBytes, 256);

      DecodeResult decodeResult = decodeCOBS(decoded, encoded);
      expect(decodeResult.outLen, 255);
      expect(decodeResult.status, DecodeStatus.OK);
      expect(
          eq(initData.buffer.asUint8List(), decoded.buffer.asUint8List(0, 255)),
          true);
    });

    test('encode withZero appends zero byte', () {
      var data = new Uint8List.fromList([1, 2, 3, 4, 5]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded =
          ByteData(encodeDstBufMaxLen(initData.lengthInBytes, withZero: true));
      expect(encoded.lengthInBytes, 7);

      EncodeResult encodeResult = encodeCOBS(encoded, initData, withZero: true);
      expect(encodeResult.outLen, 7);
      expect(encodeResult.status, EncodeStatus.OK);
      expect(encoded.getUint8(6), 0x00);
    });
  });

  group('Decode ByteData stream using decodeCOBSStream', () {
    test('decode stream of a complete packet', () async {
      var data = new Uint8List.fromList([1, 2, 3, 4, 5, 0, 6, 7, 8, 9, 0]);
      var initData = ByteData.view(data.buffer);
      ByteData encoded =
          ByteData(encodeDstBufMaxLen(initData.lengthInBytes, withZero: true));
      expect(encoded.lengthInBytes, 13);

      var controller = new StreamController<ByteData>();
      var decoder = decodeCOBSStream(controller.stream);

      EncodeResult encodeResult = encodeCOBS(encoded, initData, withZero: true);
      expect(encodeResult.outLen, 13);
      expect(encodeResult.status, EncodeStatus.OK);

      controller.sink.add(encoded);

      await decoder.listen(expectAsync1((decoded) {
        expect(eq(decoded.buffer.asUint8List(), initData.buffer.asUint8List()),
            true);
      }, count: 1));
    });

    test('decode stream of two incomplete packets', () async {
      var data = new Uint8List.fromList([1, 2, 3, 4, 5, 0, 6, 7, 8, 9, 0]);
      var initData = ByteData.view(data.buffer);

      ByteData encoded =
          ByteData(encodeDstBufMaxLen(initData.lengthInBytes, withZero: true));
      expect(encoded.lengthInBytes, 13);

      EncodeResult encodeResult = encodeCOBS(encoded, initData, withZero: true);
      expect(encodeResult.outLen, 13);
      expect(encodeResult.status, EncodeStatus.OK);

      var first = encoded.buffer.asByteData(0, 4);
      var second = encoded.buffer.asByteData(4);

      var controller = new StreamController<ByteData>();
      var decoder = decodeCOBSStream(controller.stream);

      controller.sink.add(first);
      controller.sink.add(second);

      await decoder.listen(expectAsync1((decoded) {
        expect(eq(decoded.buffer.asUint8List(), initData.buffer.asUint8List()),
            true);
      }, count: 1));
    });
  });
}
