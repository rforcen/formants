#ifndef LPCH
#define LPCH
#include <math.h>
#include <vector>

using std::vector;

class LPC {
	vector<double>delayLine;
	vector<double>impulseResponse;
	int count;
	vector<double>coefs;
	int ncoefs;

public:
	LPC() {
		ncoefs = 0;
		count = 0;
	}

	vector<double>filter(vector<double>y, int n) {
		for (int i = 0; i < n; i++)
			y[i] = getOutputSample(y[i]);
		return y;
	}

	vector<double>eval(vector<double>y, int n) {
		double yy, yp;
		for (int i = 0; i < n; i++) {
			yp = 0;
			yy = y[i];
			for (int j = 0; j < ncoefs; j++)
				yp += coefs[j] * pow(yy, j);
			y[i] = yp;
		}
		return y;
	}

	vector<double>calcCoeff(int p, vector<double>x) {
		this->ncoefs = p;
		coefs = getCoefficients(p, x);
		init();
		return coefs;
	}

	void init() {
		impulseResponse = coefs;
		delayLine = vector<double>(ncoefs);
		count = 0;
	}

	double getOutputSample(double inputSample) { // evaluate conv
		delayLine[count] = inputSample;
		double result = 0.0;
		int index = count;
		for (int i = 0; i < ncoefs; i++) {
			result += impulseResponse[i] * delayLine[index--];
			if (index < 0)
				index = ncoefs - 1;
		}
		if (++count >= ncoefs)
			count = 0;
		return result;
	}

	
	vector<double>getCoefficients(int p, vector<double>x) {
        double r[p+1]; // = new double[p + 1]; // size = 11
		auto N = x.size(); // size = 256
		for (int T = 0; T < p + 1; T++) {
			for (int t = 0; t < N - T; t++) {
				r[T] += x[t] * x[t + T];
			}
		}
		double e = r[0], e1 = 0.0, k = 0.0;
        vector<double>alpha_new = vector<double>(p + 1);
        double alpha_old[p+1];
        
		alpha_new[0] = alpha_old[0] = 1.0;
		for (int h = 1; h <= p; h++)
			alpha_new[h] = alpha_old[h] = 0.0;
        
		double sum = 0.0;
		for (int i = 1; i <= p; i++) {
			sum = 0;
			for (int j = 1; j <= i - 1; j++)
				sum += alpha_old[j] * (r[i - j]);
			k = ((r[i]) - sum) / e;
			alpha_new[i] = k;
			for (int c = 1; c <= i - 1; c++)
				alpha_new[c] = alpha_old[c] - (k * alpha_old[i - c]);
			e1 = (1 - (k * k)) * e;
			for (int g = 0; g <= i; g++)
				alpha_old[g] = alpha_new[g];
			e = e1;
		}
		for (int a = 1; a < p + 1; a++)
			alpha_new[a] = -1 * alpha_new[a];

        
		return alpha_new;
	}

	void test() {
		int xl = 256;
		short *x = new short[xl];
		for (int i = 0; i < xl; i++)
			x[i] = (short)(16000 * sin(2. * M_PI * 8000. * i / 44100.));
//        vector<double>alpha = getCoefficients(10, x, xl);
	}
};

#endif
