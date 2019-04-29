# Consistent Overhead Byte Stuffing (COBS) implementation in Dart.

This package is a Dart port of original COBS implementation in C
by Craig McQueen and influenced by the Java implementation by
TheMarpe (https://github.com/themarpe)

# Intro

A library is provided, which contains functions for encoding and decoding
according to COBS methods.


## What Is COBS?

COBS is a method of encoding a packet of bytes into a form that contains no
bytes with value zero (0x00). The input packet of bytes can contain bytes
in the full range of 0x00 to 0xFF. The COBS encoded packet is guaranteed to
generate packets with bytes only in the range 0x01 to 0xFF. Thus, in a
communication protocol, packet boundaries can be reliably delimited with 0x00
bytes.

The COBS encoding does have to increase the packet size to achieve this
encoding. However, compared to other byte-stuffing methods, the packet size
increase is reasonable and predictable. COBS always adds 1 byte to the
message length. Additionally, for longer packets of length *n*, it *may* add
n/254 (rounded down) additional bytes to the encoded packet size.

For example, compare to the PPP protocol, which uses 0x7E bytes to delimit
PPP packets. The PPP protocol uses an "escape" style of byte stuffing,
replacing all occurrences of 0x7E bytes in the packet with 0x7D 0x5E. But that
byte-stuffing method can potentially double the size of the packet in the
worst case. COBS uses a different method for byte-stuffing, which has a much
more reasonable worst-case overhead.

For more details about COBS, see the references [1][1] [2][2].


## References

[Consistent Overhead Byte Stuffing][1]\
Stuart Cheshire and Mary Baker\
IEEE/ACM Transations on Networking, Vol. 7, No. 2, April 1999

[PPP Consistent Overhead Byte Stuffing (COBS)][2]\
PPP Working Group Internet Draft<br>James Carlson, IronBridge Networks\
Stuart Cheshire and Mary Baker, Stanford University, November 1997

[1]: http://www.stuartcheshire.org/papers/COBSforToN.pdf
[2]: http://tools.ietf.org/html/draft-ietf-pppext-cobs-00