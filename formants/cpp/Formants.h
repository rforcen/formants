//
//  Formants.h
//  formants
//
//  Created by asd on 06/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

#ifndef Formants_h
#define Formants_h

typedef struct {
    size_t n; // formants
    double*hz, *pwr, *bw;
    
    size_t nfr; // n, x,y freq. response
    double*xfr,*yfr;
    
    size_t nfft;
    double*fft;
    
    double*sumFFT;
} Formants;


#endif /* Formants_h */
