/*
 * Copyright (c) 2006 Romain Guy <romain.guy@mac.com>
 * Copyright © 2017 WillShex Limited.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import 'dart:math';
import 'dart:typed_data';

import 'package:blend_composites/blend_composites.dart';
import 'package:image/image.dart' as img;

final class BlendComposite extends BlendCompositeBase {
  img.Decoder srcDecoder = img.PngDecoder();
  img.Decoder dstDecoder = img.PngDecoder();
  img.Encoder encoder = img.PngEncoder();

  BlendComposite(super.protectedMode, super.protectedAlpha);

  static BlendComposite getInstance(BlendingMode mode, [double alpha = 1.0]) =>
      BlendComposite(mode, alpha);

  @override
  BlendComposite deriveFromMode(BlendingMode mode) =>
      this.mode == mode ? this : BlendComposite(protectedMode, alpha);

  @override
  BlendComposite deriveFromAlpha(double alpha) =>
      this.alpha == alpha ? this : BlendComposite(mode, protectedAlpha);

  Uint8List compose(
    Uint8List srcBytes,
    Uint8List dstBytes,
  ) {
    img.Image src = srcDecoder.decode(srcBytes)!;
    img.Image dst = dstDecoder.decode(dstBytes)!;

    img.Image dstOut = composeImages(src, dst);

    return encoder.encode(dstOut);
  }

  img.Image composeImages(img.Image src, img.Image dst) {
    int width = min(src.width, dst.width);
    int height = min(src.height, dst.height);

    double alpha = this.alpha;

    Uint8List srcPixel = Uint8List(4);
    Uint8List dstPixel = Uint8List(4);

    img.Image dstOut = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      Iterator<img.Pixel> srcPixels = src.getRange(0, y, width, 1);
      Iterator<img.Pixel> dstPixels = dst.getRange(0, y, width, 1);

      for (int x = 0; x < width; x++) {
        srcPixels.moveNext();
        dstPixels.moveNext();

        // pixels are stored as INT_ARGB`
        // our arrays are [R, G, B, A]
        img.Pixel pixel = srcPixels.current;
        srcPixel[0] = pixel.b.toInt() & 0xFF;
        srcPixel[1] = pixel.g.toInt() & 0xFF;
        srcPixel[2] = pixel.r.toInt() & 0xFF;
        srcPixel[3] = pixel.a.toInt() & 0xFF;

        pixel = dstPixels.current;
        dstPixel[0] = pixel.b.toInt() & 0xFF;
        dstPixel[1] = pixel.g.toInt() & 0xFF;
        dstPixel[2] = pixel.r.toInt() & 0xFF;
        dstPixel[3] = pixel.a.toInt() & 0xFF;

        late Uint8List result;

        try {
          result = mode.blend(srcPixel, dstPixel);
        } catch (e) {
          result = srcPixel;
        }

        // mixes the result with the opacity
        dstOut.setPixelRgba(
          x,
          y,
          (dstPixel[2] + (result[2] - dstPixel[2]) * alpha).toInt() & 0xFF,
          ((dstPixel[1] + (result[1] - dstPixel[1]) * alpha).toInt() & 0xFF),
          ((dstPixel[0] + (result[0] - dstPixel[0]) * alpha).toInt() & 0xFF),
          ((dstPixel[3] + (result[3] - dstPixel[3]) * alpha).toInt() & 0xFF),
        );
      }
    }
    return dstOut;
  }
}
