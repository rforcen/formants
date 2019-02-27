//
//  testFormants.cpp
//  formants
//
//  Created by asd on 05/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

#include "generateFormants.hpp"
#include "Formants.h"

extern "C" {
    Formants _localForms;
    
    Formants generateFormants(size_t sampRate, size_t sampleSize, float *_samples) {
        
        CSpectrograph spec((int)sampRate, (int)sampleSize);
        
        spec.copySamples(_samples, sampleSize);
        spec.LCPformants();
        spec.FFT1d(); // fft = _FFT1d(samples)
        
        Formants forms = {
            .n=spec.getnForms(),
            .hz=spec.getHzs(),
            .pwr=spec.getPwrs(),
            .bw=spec.getBws(),
            
            .nfr=spec.getsizeFreqResp(),
            .xfr=spec.getHzFreqResp(),
            .yfr=spec.getPwrFreqResp(),
            
            .nfft=spec.getnfft(),
            .fft=spec.getfft()
        };
        
        return _localForms = forms;
    }
    
    void releaseResources() {
        free(_localForms.hz);
        free(_localForms.pwr);
        free(_localForms.bw);
        free(_localForms.xfr);
        free(_localForms.yfr);
        free(_localForms.fft);
    }
}
