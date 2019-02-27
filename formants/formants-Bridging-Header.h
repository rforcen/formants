//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include <stdlib.h>
#include "Formants.h"
#include "AudioIn.h"
#include "RealArray.h"

Formants generateFormants(size_t sampRate, size_t sampleSize, float *_samples);
void releaseResources();
