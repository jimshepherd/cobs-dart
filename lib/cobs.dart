library cobs;

import 'dart:typed_data';

enum EncodeStatus {
  OK,
  NULL_POINTER,
  OUT_BUFFER_OVERFLOW,
}

class EncodeResult {
  int outLen;
  EncodeStatus status;
}

enum DecodeStatus {
  OK,
  NULL_POINTER,
  OUT_BUFFER_OVERFLOW,
  ZERO_BYTE_IN_INPUT,
  INPUT_TOO_SHORT,
}

class DecodeResult {
  int outLen;
  DecodeStatus status;
}

int encodeDstBufMaxLen(int srcLen, {bool withZero=false}) {
  return srcLen + (srcLen + 253)~/254 + (withZero ? 1 : 0);
}

int decodeDstBufMaxLen(int srcLen){
  return srcLen == 0 ? 0 : srcLen - 1;
}

EncodeResult encodeCOBS(ByteData encoded, ByteData source,
    {bool withZero=false}) {
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


DecodeResult decodeCOBS(ByteData decoded, ByteData source){
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
