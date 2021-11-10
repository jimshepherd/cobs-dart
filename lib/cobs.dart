library cobs;

import 'dart:typed_data';

/// [encodeCOBS()] status types
enum EncodeStatus {
  OK,
  NULL_POINTER,
  OUT_BUFFER_OVERFLOW,
}

/// Status and length container of [encodeCOBS()] result.
class EncodeResult {
  int outLen;
  EncodeStatus status;
}

/// [decodeCOBS()] status types.
enum DecodeStatus {
  OK,
  NULL_POINTER,
  OUT_BUFFER_OVERFLOW,
  ZERO_BYTE_IN_INPUT,
  INPUT_TOO_SHORT,
}

/// Status and length container of [decodeCOBS()] result.
class DecodeResult {
  int outLen;
  DecodeStatus status;
}

/// Determine maximum encoded byte length for source containing [srcLen] bytes.
///
/// If [withZero] is true, the length is increased by 1 to allow room for a 0x00
/// byte to be appended to the end
int encodeDstBufMaxLen(int srcLen, {bool withZero = false}) {
  return srcLen + (srcLen + 253) ~/ 254 + (withZero ? 1 : 0);
}

/// Determine maximum decoded byte length for source containing [srcLen] bytes.
int decodeDstBufMaxLen(int srcLen) {
  return srcLen == 0 ? 0 : srcLen - 1;
}

/// Encode [source] to [encoded] using COBS and return [EncodeResult] status.
///
/// If [withZero] is true, a 0x00 byte is appended to [encoded]
/// The [EncodeResult] instance returned will include the actual length of the
/// encoded byte array in [outLen] and the status of the encoding attempt in
/// [status].
EncodeResult encodeCOBS(ByteData encoded, ByteData source,
    {bool withZero = false}) {
  EncodeResult result = new EncodeResult();
  result.outLen = 0;
  result.status = EncodeStatus.OK;

  if (encoded == null || source == null) {
    result.status = EncodeStatus.NULL_POINTER;
    return result;
  }

  int encodedWriteCounter = 1;
  int encodedCodeWriteCounter = 0;
  int encodedEndCounter = encoded.lengthInBytes;

  int sourceCounter = 0;
  int sourceEndCounter = source.lengthInBytes;

  int searchLen = 1;

  if (source.lengthInBytes != 0) {
    /* Iterate over the source bytes */
    while (true) {
      /* Check for running out of output buffer space */
      if (encodedWriteCounter >= encodedEndCounter) {
        result.status = EncodeStatus.OUT_BUFFER_OVERFLOW;
        break;
      }

      int sourceByte = source.getUint8(sourceCounter++);
      if (sourceByte == 0) {
        /* We found a zero byte */
        encoded.setUint8(encodedCodeWriteCounter, searchLen & 0xFF);
        encodedCodeWriteCounter = encodedWriteCounter++;
        searchLen = 1;
        if (sourceCounter >= sourceEndCounter) {
          break;
        }
      } else {
        /* Copy the non-zero byte to the destination buffer */
        encoded.setUint8(encodedWriteCounter++, sourceByte & 0xFF);
        searchLen++;

        if (sourceCounter >= sourceEndCounter) {
          break;
        }

        if (searchLen == 0xFF) {
          /* We have a long string of non-zero bytes, so we need
           * to write out a length code of 0xFF. */
          encoded.setUint8(encodedCodeWriteCounter, searchLen & 0xFF);
          encodedCodeWriteCounter = encodedWriteCounter++;
          searchLen = 1;
        }
      }
    }
  }

  if (withZero) {
    encoded.setUint8(encodedWriteCounter++, 0x00);
  }

  /* We've reached the end of the source data (or possibly run out of output buffer)
   * Finalise the remaining output. In particular, write the code (length) byte.
   * Update the pointer to calculate the final output length.
   */
  if (encodedCodeWriteCounter >= encodedEndCounter) {
    /* We've run out of output buffer to write the code byte. */
    result.status = EncodeStatus.OUT_BUFFER_OVERFLOW;
    encodedWriteCounter = encodedEndCounter;
  } else {
    /* Write the last code (length) byte. */
    encoded.setUint8(encodedCodeWriteCounter, searchLen & 0xFF);
  }

  /* Calculate the output length, from the value of dst_code_write_ptr */
  result.outLen = encodedWriteCounter;

  return result;
}

/// Decode [source] to [decoded] using COBS and return [DecodeResult] status.
///
/// The [DecodeResult] instance returned will include the actual length of the
/// decoded byte array in [outLen] and the status of the decoding attempt in
/// [status].
DecodeResult decodeCOBS(ByteData decoded, ByteData source) {
  DecodeResult result = new DecodeResult();
  result.outLen = 0;
  result.status = DecodeStatus.OK;

  /* First, do a NULL check and return immediately if it fails. */
  if (decoded == null || source == null) {
    result.status = DecodeStatus.NULL_POINTER;
    return result;
  }

  int sourceCounter = 0;
  int sourceEndCounter = source.lengthInBytes;
  int decodedEndCounter = decoded.lengthInBytes;
  int decodedWriteCounter = 0;
  int remainingBytes;
  int sourceByte;
  int i;
  int lengthCode;

  if (source.lengthInBytes != 0) {
    while (true) {
      lengthCode = source.getUint8(sourceCounter++);
      if (lengthCode == 0) {
        result.status = DecodeStatus.ZERO_BYTE_IN_INPUT;
        break;
      }
      lengthCode--;

      /* Check length code against remaining input bytes */
      remainingBytes = sourceEndCounter - sourceCounter;
      if (lengthCode > remainingBytes) {
        result.status = DecodeStatus.INPUT_TOO_SHORT;
        lengthCode = remainingBytes;
      }

      /* Check length code against remaining output buffer space */
      remainingBytes = decodedEndCounter - decodedWriteCounter;
      if (lengthCode > remainingBytes) {
        result.status = DecodeStatus.OUT_BUFFER_OVERFLOW;
        lengthCode = remainingBytes;
      }

      for (i = lengthCode; i != 0; i--) {
        sourceByte = source.getUint8(sourceCounter++);
        if (sourceByte == 0) {
          result.status = DecodeStatus.ZERO_BYTE_IN_INPUT;
        }
        decoded.setUint8(decodedWriteCounter++, sourceByte);
      }

      if (sourceCounter >= sourceEndCounter) {
        break;
      }

      /* Add a zero to the end */
      if (lengthCode != 0xFE) {
        if (decodedWriteCounter >= decodedEndCounter) {
          result.status = DecodeStatus.OUT_BUFFER_OVERFLOW;
          break;
        }
        decoded.setUint8(decodedWriteCounter++, 0);
      }
    }
  }

  result.outLen = decodedWriteCounter;
  return result;
}

/// Decodes a stream of COBS-encoded bytes into packets of decoded bytes.
///
/// The input bytes are provided in chunks through the [source] stream.
Stream<ByteData> decodeCOBSStream(Stream<ByteData> source) async* {
  // Stores any partial packets from the previous chunk.
  var partial = ByteData(0);

  // Wait until a new chunk is available, then process it.
  await for (var chunk in source) {
    // Get index of 0x00 byte if found
    var offset = 0;
    for (var i = 0; i < chunk.lengthInBytes; i++) {
      if (chunk.getUint8(i) == 0x00) {
        // Packet delimiter found, now decode it
        int encodedLength = partial.lengthInBytes + i - offset;
        var encoded = ByteData(encodedLength);
        var index = 0;
        for (var ip = 0; ip < partial.lengthInBytes; ip++) {
          encoded.setUint8(index, partial.getUint8(ip));
          index++;
        }
        for (var ie = offset; ie < i; ie++) {
          encoded.setUint8(index, chunk.getUint8(ie));
          index++;
        }

        partial = ByteData(0);
        offset = i + 1;

        ByteData decoded = ByteData(decodeDstBufMaxLen(encodedLength));
        DecodeResult result = decodeCOBS(decoded, encoded);
        if (result.status == DecodeStatus.OK) {
          yield ByteData.view(decoded.buffer, 0, result.outLen);
        }
      }
    }
    partial = chunk.buffer.asByteData(offset, chunk.lengthInBytes - offset);
  }
}
