
#ifndef CSpectrographH
#define CSpectrographH
#include <stdio.h>

#include "LPC.h"
#include "PolyRoots.h"
#include <vector>
#include <algorithm>

using std::vector;

#include <Accelerate/Accelerate.h>

using namespace std;
typedef std::complex<double> Complex;

class FormantItem {
public:
    double hz=0, bw=0, pwr=0;
    
    FormantItem() {	}
    FormantItem(double hz, double bw, double pwr) {
        this->hz = hz; this->bw = bw; this->pwr = pwr;
    }
};

class CSpectrograph {
private:
    vector<double>samples;
    
public:
    int sampleRate;
    int sampSize;
    
    vector<FormantItem>forms;
    LPC lpc;
    
    vector<Complex>freqResp; // x/y freq. response (power, freq)
    vector<double>fft;
    
    CSpectrograph(int sampleRate, int sampleSize) {
        this->sampleRate = sampleRate;
        this->sampSize = sampleSize; // sample buffer mgr.
    }
    
    ~CSpectrograph() {
        forms.clear();
        samples.clear();
        freqResp.clear();
    }
    
    void copySamples(double*samples, size_t n) {
        this->samples.clear();
        for (int i=0; i<n; i++)
            this->samples.push_back(samples[i]);
    }
    void copySamples(float*samples, size_t n) {
        this->samples.clear();
        for (int i=0; i<n; i++)
            this->samples.push_back(samples[i]);
    }
    
    size_t getnForms() { return forms.size(); }
    
    size_t getnfft() { return fft.size(); }
    
    double*getfft() {
        double *v=(double*)calloc(getnfft(), sizeof(double));
        for (int i=0; i<getnfft(); i++)
            v[i]=fft[i];
        return v;
    }
    
    vector<Complex>getFreqsResp() {
        return freqResp;
    }
    size_t getsizeFreqResp() {
        return (int)freqResp.size();
    }
    double*getPwrFreqResp() {
        double *v=(double*)calloc(getsizeFreqResp(), sizeof(double));
        for (int i=0; i<getsizeFreqResp(); i++)
            v[i]=freqResp[i].real();
        return v;
    }
    double*getHzFreqResp() {
        double *v=(double*)calloc(getsizeFreqResp(), sizeof(double));
        for (int i=0; i<getsizeFreqResp(); i++)
            v[i]=freqResp[i].imag();
        return v;
    }
    
    double*createDoubleFormBuffer() {
        return (double*)calloc(getnForms(), sizeof(double));
    }
    
    double* getHzs() {
        double*v=createDoubleFormBuffer();
        for (int i=0; i<getnForms(); i++) v[i]=forms[i].hz;
        return v;
    }
    double* getPwrs() {
        double*v=createDoubleFormBuffer();
        for (int i=0; i<getnForms(); i++) v[i]=forms[i].pwr;
        return v;
    }
    double* getBws() {
        double*v=createDoubleFormBuffer();
        for (int i=0; i<getnForms(); i++) v[i]=forms[i].bw;
        return v;
    }
    
    int n2pow2(int n) { // log2(n)
        int p2=0;
        while(n>>=1)p2++;
        return p2;
    }
    
    vector<Complex>FFT(vector<Complex>input) {
        
        const int log2n=n2pow2((int)input.size()),
        nfft = 1<<log2n, n2=nfft/2;
        vector<float>re,im;
        
        // convert nfft items Complex(double) to float
        for (int i=0; i<nfft; i++) {
            re.push_back(input[i].real());
            im.push_back(input[i].imag());
        }
        
        DSPSplitComplex cxfft={ .realp = re.data(), .imagp = im.data() };
        
        // prepare the fft algo (you want to reuse the setup across fft calculations)
        FFTSetup setup = vDSP_create_fftsetup(log2n, kFFTRadix2);
        
        vDSP_fft_zrip(setup, &cxfft, 1, log2n, FFT_FORWARD); // calculate the fft
        
        for (int i=0; i<n2; i++) // save symmetric result
            input[i] = Complex(cxfft.realp[i], cxfft.imagp[i]);
        input[0]=Complex(0,0);
        
        vDSP_destroy_fftsetup(setup); // release resources
        
        input.resize(n2/2); // symmetrical
        return input;
    }
    
    vector<double>_FFT1d(vector<double>input) {
        
        const int log2n=n2pow2((int)input.size()),
        nfft = 1<<log2n, n2=nfft/2;
        vector<float>re,im;
        
        // convert nfft items Complex(double) to float
        for (int i=0; i<nfft; i++) {
            re.push_back(input[i]);
            im.push_back(0);
        }
        
        DSPSplitComplex cxfft={ .realp = re.data(), .imagp = im.data() };
        
        // prepare the fft algo (you want to reuse the setup across fft calculations)
        FFTSetup setup = vDSP_create_fftsetup(log2n, kFFTRadix2);
        
        vDSP_fft_zrip(setup, &cxfft, 1, log2n, FFT_FORWARD); // calculate the fft
        
        for (int i=0; i<n2; i++) // save symmetric result
            input[i] = abs( Complex(cxfft.realp[i], cxfft.imagp[i]) );
        input[0]=0;
        
        vDSP_destroy_fftsetup(setup); // release resources
        
        input.resize(n2/2); // symmetrical
        return input;
    }
    
    void FFT1d() {
        fft = _FFT1d(samples);
    }

    
    double index2Freq(int i, double sampRate, int nFFT) {
        return (double)i * (sampRate / nFFT / 2.);
    }
    
    int freq2Index(double freq, double sampRate, int nFFT) {
        return (int)freq / (sampRate / nFFT / 2.);
    }
    
    double db(Complex c) {
        double pwr=20.0 * log10(abs(1. / c) + 1e-16); // power in db
        if(isnan(pwr) || isinf(pwr)) pwr=0;
        return pwr;
    }
    
    void LCPformants() { // lpc formants
        int ncoeff = 2 + sampleRate / 1000; // LPC coeff
        vector<double>lpcCoeff = lpc.calcCoeff(ncoeff, samples);
        
        { // formants
            vector<Complex>roots = PolyRoots::roots(lpcCoeff); // poly roots
            
            double srDivpi2 = (double)sampleRate / (M_PI * 2.);
            double srDivpi = (double)sampleRate / M_PI;
            
            forms.clear();
            
            for (auto root:roots) { // only look for roots >0Hz up to fs/2
                if (root.imag() >= 0.01) {
                    double hz = srDivpi2 * atan2( root.imag(), root.real() );
                    double bw = srDivpi * log(abs(root));
                    if (hz > 0 & bw < 400) { // formant frequencies should be greater than 0 Hz with bandwidths less than 400 Hz
                        
                        forms.push_back(FormantItem(hz, bw, 0));
                    }
                }
            }
            sort(forms.begin(), forms.end(),
                 [](FormantItem a, FormantItem b) { return a.hz < b.hz; }); // by hz
        }
        
        { // frequency response
            
            freqResp.clear();
            
            vector<Complex>fResp=vector<Complex>(sampSize);
            copy(lpcCoeff.begin(), lpcCoeff.end(), fResp.begin()); // fResp=lpcCoeff
            
            auto fftCpx=FFT(fResp);
            auto nfft=(int)fftCpx.size();
            
            for (int i = 0; i < nfft; i++) { // freq. rsp in log scale (real=power, imag=freq), symmetric->only half required
                freqResp.push_back( Complex(db(fftCpx[i]) , index2Freq(i, sampleRate, nfft)) );
            }
            
            for (auto &form:forms)  // update power in formants db( fft[index of form.hz freq] )
                form.pwr=db( fftCpx[freq2Index(form.hz, sampleRate, nfft)] );
            
            sort(forms.begin(), forms.end(),
                 [](FormantItem a, FormantItem b) { return a.pwr > b.pwr; }); // by power
        }
        
    }
    
};

#endif
