#ifndef FIRH
#define FIRH

#include <math.h>

enum {
	BANDPASS, DIFFERENTIATOR, HILBERT
};
enum {
	NEGATIVE, POSITIVE
};

class remezCoeffCalc { // Parks-McClellan algorithm for FIR filter design

	double Pi, Pi2;
	int GRIDDENSITY, MAXITERATIONS;

public:

	remezCoeffCalc() {
        Pi = M_PI; Pi2 = Pi * 2.;
        GRIDDENSITY = 16; MAXITERATIONS = 40;
	}

	void CreateDenseGrid(int r, int numtaps, int numband, double *bands,
		double *des, double *weight, int gridsize, double *Grid, double *D,
		double *W, int symmetry) {
		int i, j, k, band;
		double delf, lowf, highf;

		delf = 0.5 / (GRIDDENSITY * r);

		/*
		 * For differentiator, hilbert, symmetry is odd and Grid[0] = max(delf,
		 * band[0])
		 */

		if ((symmetry == NEGATIVE) && (delf > bands[0]))
			bands[0] = delf;

		j = 0;
		for (band = 0; band < numband; band++) {
			Grid[j] = bands[2 * band];
			lowf = bands[2 * band];
			highf = bands[2 * band + 1];
			k = (int)((highf - lowf) / delf + 0.5); /* .5 for rounding */
			for (i = 0; i < k; i++) {
				D[j] = des[band];
				W[j] = weight[band];
				Grid[j] = lowf;
				lowf += delf;
				j++;
			}
			Grid[j - 1] = highf;
		}

		/*
		 * Similar to above, if odd symmetry, last grid point can't be .5 - but,
		 * if there are even taps, leave the last grid point at .5
		 */
		if ((symmetry == NEGATIVE) & (Grid[gridsize - 1] > (0.5 - delf)) &
			(numtaps % 2) != 0) {
			Grid[gridsize - 1] = 0.5 - delf;
		}
	}

	void InitialGuess(int r, int *Ext, int gridsize) {
		int i;
		for (i = 0; i <= r; i++)
			Ext[i] = i * (gridsize - 1) / r;
	}

	void CalcParms(int r, int *Ext, double *Grid, double *D, double *W,
		double *ad, double *x, double *y) {
		int i, j, k, ld;
		double sign, xi, delta, denom, numer;

		// Find x*

		for (i = 0; i <= r; i++)
			x[i] = cos(Pi2 * Grid[Ext[i]]);

		// Calculate ad* - Oppenheim & Schafer eq 7.132
		ld = (r - 1) / 15 + 1; /* Skips around to avoid round errors */
		for (i = 0; i <= r; i++) {
			denom = 1.0;
			xi = x[i];
			for (j = 0; j < ld; j++) {
				for (k = j; k <= r; k += ld)
					if (k != i)
						denom *= 2.0 * (xi - x[k]);
			}
			if (fabs(denom) < 0.00001)
				denom = 0.00001;
			ad[i] = 1.0 / denom;
		}

		/*
		 * Calculate delta - Oppenheim & Schafer eq 7.131
		 */
		numer = denom = 0;
		sign = 1;
		for (i = 0; i <= r; i++) {
			numer += ad[i] * D[Ext[i]];
			denom += sign * ad[i] / W[Ext[i]];
			sign = -sign;
		}
		delta = numer / denom;
		sign = 1;

		/*
		 * Calculate y* - Oppenheim & Schafer eq 7.133b
		 */
		for (i = 0; i <= r; i++) {
			y[i] = D[Ext[i]] - sign * delta / W[Ext[i]];
			sign = -sign;
		}
	}

	double ComputeA(double freq, int r, double *ad, double *x, double *y) {
		int i;
		double xc, c, denom, numer;

		denom = numer = 0;
		xc = cos(Pi2 * freq);
		for (i = 0; i <= r; i++) {
			c = xc - x[i];
			if (fabs(c) < 1.0e-7) {
				numer = y[i];
				denom = 1;
				break;
			}
			c = ad[i] / c;
			denom += c;
			numer += c * y[i];
		}
		return numer / denom;
	}

	void CalcError(int r, double *ad, double *x, double *y, int gridsize,
		double *Grid, double *D, double *W, double *E) {
		int i;
		double A;

		for (i = 0; i < gridsize; i++) {
			A = ComputeA(Grid[i], r, ad, x, y);
			E[i] = W[i] * (D[i] - A);
		}
	}

	void Search(int r, int *Ext, int gridsize, double *E) {
		int i, j, k, l, extra; /* Counters */
		int up, alt;
		int*foundExt; /* Array of found extremals */

		/*
		 * Allocate enough space for found extremals.
		 */
		foundExt = new int[2 * r];
		k = 0;

		/*
		 * Check for extremum at 0.
		 */
		if (((E[0] > 0.0) && (E[0] > E[1])) || ((E[0] < 0.0) && (E[0] < E[1])))
			foundExt[k++] = 0;

		/*
		 * Check for extrema inside dense grid
		 */
		for (i = 1; i < gridsize - 1; i++) {
			if (((E[i] >= E[i - 1]) && (E[i] > E[i + 1]) && (E[i] > 0.0)) ||
				((E[i] <= E[i - 1]) && (E[i] < E[i + 1]) && (E[i] < 0.0)))
				foundExt[k++] = i;
		}

		/*
		 * Check for extremum at 0.5
		 */
		j = gridsize - 1;
		if (((E[j] > 0.0) && (E[j] > E[j - 1])) ||
			((E[j] < 0.0) && (E[j] < E[j - 1])))
			foundExt[k++] = j;

		/*
		 * Remove extra extremals
		 */
		extra = k - (r + 1);

		while (extra > 0) {
			if (E[foundExt[0]] > 0.0)
				up = 1; /* first one is a maxima */
			else
				up = 0; /* first one is a minima */

			l = 0;
			alt = 1;
			for (j = 1; j < k; j++) {
				if (fabs(E[foundExt[j]]) < fabs(E[foundExt[l]]))
					l = j; /* new smallest error. */
				if ((up != 0) & (E[foundExt[j]] < 0.0))
					up = 0; /* switch to a minima */
				else if ((up == 0) & (E[foundExt[j]] > 0.0))
					up = 1; /* switch to a maxima */
				else {
					alt = 0;
					break; /* Ooops, found two non-alternating */
				} /* extrema. Delete smallest of them */
			} /* if the loop finishes, all extrema are alternating */

			/*
			 * If there's only one extremal and all are alternating, delete the
			 * smallest of the first/last extremals.
			 */
			if ((alt != 0) & (extra == 1)) {
				if (fabs(E[foundExt[k - 1]]) < fabs(E[foundExt[0]]))
					l = foundExt[k - 1]; /* Delete last extremal */
				else
					l = foundExt[0]; /* Delete first extremal */
			}

			for (j = l; j < k; j++) /* Loop that does the deletion */ {
				foundExt[j] = foundExt[j + 1];
			}
			k--;
			extra--;
		}

		for (i = 0; i <= r; i++) {
			Ext[i] = foundExt[i]; /* Copy found extremals to Ext* */
		}
	}

	void FreqSample(int N, double *A, double *h, int symm) {
		int n, k;
		double x, val, M;

		M = (N - 1.0) / 2.0;
		if (symm == POSITIVE) {
			if (N % 2 != 0) {
				for (n = 0; n < N; n++) {
					val = A[0];
					x = Pi2 * (n - M) / N;
					for (k = 1; k <= M; k++)
						val += 2.0 * A[k] * cos(x * k);
					h[n] = val / N;
				}
			}
			else {
				for (n = 0; n < N; n++) {
					val = A[0];
					x = Pi2 * (n - M) / N;
					for (k = 1; k <= (N / 2 - 1); k++)
						val += 2.0 * A[k] * cos(x * k);
					h[n] = val / N;
				}
			}
		}
		else {
			if (N % 2 != 0) {
				for (n = 0; n < N; n++) {
					val = 0;
					x = Pi2 * (n - M) / N;
					for (k = 1; k <= M; k++)
						val += 2.0 * A[k] * sin(x * k);
					h[n] = val / N;
				}
			}
			else {
				for (n = 0; n < N; n++) {
					val = A[N / 2] * sin(Pi * (n - M));
					x = Pi2 * (n - M) / N;
					for (k = 1; k <= (N / 2 - 1); k++)
						val += 2.0 * A[k] * sin(x * k);
					h[n] = val / N;
				}
			}
		}
	}

	short isDone(int r, int *Ext, double *E) {
		int i;
		double min, max, current;

		min = max = fabs(E[Ext[0]]);
		for (i = 1; i <= r; i++) {
			current = fabs(E[Ext[i]]);
			if (current < min)
				min = current;
			if (current > max)
				max = current;
		}
		if (((max - min) / max) < 0.0001)
			return 1;
		return 0;
	}

	void remez(double *h, int numtaps, int numband, double *bands, double *des,
		double *weight, int type) {
		double*Grid, *W, *D, *E;
		int i, iter, gridsize, r;
		int*Ext;
		double*taps;
		double c;
		double*x, *y, *ad;
		int symmetry;

		if (type == BANDPASS)
			symmetry = POSITIVE;
		else
			symmetry = NEGATIVE;

		r = numtaps / 2; /* number of extrema */
		if ((numtaps % 2 != 0) & (symmetry == POSITIVE))
			r++;

		/*
		 * Predict dense grid size in advance for memory allocation .5 is so we
		 * round up, not truncate
		 */
		gridsize = 0;
		for (i = 0; i < numband; i++) {
			gridsize +=
				(int)(2 * r * GRIDDENSITY * (bands[2 * i + 1] -
				bands[2 * i]) + .5);
		}
		if (symmetry == NEGATIVE) {
			gridsize--;
		}

		/*
		 * Dynamically allocate memory for arrays with proper sizes
		 */
		Grid = new double[gridsize];
		D = new double[gridsize];
		W = new double[gridsize];
		E = new double[gridsize];
		Ext = new int[r + 1];
		taps = new double[r + 1];
		x = new double[r + 1];
		y = new double[r + 1];
		ad = new double[r + 1];

		/*
		 * Create dense frequency grid
		 */
		CreateDenseGrid(r, numtaps, numband, bands, des, weight, gridsize, Grid,
			D, W, symmetry);
		InitialGuess(r, Ext, gridsize);

		/*
		 * For Differentiator: (fix grid)
		 */
		if (type == DIFFERENTIATOR) {
			for (i = 0; i < gridsize; i++) {
				/* D[i] = D[i]*Grid[i]; */
				if (D[i] > 0.0001)
					W[i] = W[i] / Grid[i];
			}
		}

		/*
		 * For odd or Negative symmetry filters, alter the D* and W* according
		 * to Parks McClellan
		 */
		if (symmetry == POSITIVE) {
			if (numtaps % 2 == 0) {
				for (i = 0; i < gridsize; i++) {
					c = cos(Pi * Grid[i]);
					D[i] /= c;
					W[i] *= c;
				}
			}
		}
		else {
			if (numtaps % 2 != 0) {
				for (i = 0; i < gridsize; i++) {
					c = sin(Pi2 * Grid[i]);
					D[i] /= c;
					W[i] *= c;
				}
			}
			else {
				for (i = 0; i < gridsize; i++) {
					c = sin(Pi * Grid[i]);
					D[i] /= c;
					W[i] *= c;
				}
			}
		}

		/*
		 * Perform the Remez Exchange algorithm
		 */
		for (iter = 0; iter < MAXITERATIONS; iter++) {
			CalcParms(r, Ext, Grid, D, W, ad, x, y);
			CalcError(r, ad, x, y, gridsize, Grid, D, W, E);
			Search(r, Ext, gridsize, E);
			if (isDone(r, Ext, E) != 0)
				break;
		}
		if (iter == MAXITERATIONS) {
			// printf("Reached maximum iteration count.\nResults may be bad.\n");
		}

		CalcParms(r, Ext, Grid, D, W, ad, x, y);

		/*
		 * Find the 'taps' of the filter for use with Frequency Sampling. If odd
		 * or Negative symmetry, fix the taps according to Parks McClellan
		 */
		for (i = 0; i <= numtaps / 2; i++) {
			if (symmetry == POSITIVE) {
				if (numtaps % 2 != 0)
					c = 1;
				else
					c = cos(Pi * (double) i / numtaps);
			}
			else {
				if (numtaps % 2 != 0)
					c = sin(Pi2 * (double) i / numtaps);
				else
					c = sin(Pi * (double) i / numtaps);
			}
			taps[i] = ComputeA((double) i / numtaps, r, ad, x, y) * c;
		}

		/*
		 * Frequency sampling design with calculated taps
		 */
		FreqSample(numtaps, taps, h, symmetry);
	}

	// sample test
	void test() {
		int numtaps = 7, numband = 5;
		double *h, desired[] = {0, 1, 0, 1, 0}, // band responses [numband]
			weights[] = {10, 1, 3, 1, 20}, // error weights [numband]
			bands[] = {0, 0.05, 0.1, 0.15, 0.18, 0.25, 0.3, 0.36, 0.41, 0.5
		}; // User-specified band edges [2 * numband]
		h = new double[300];
		remez(h, numtaps, numband, bands, desired, weights, BANDPASS);
	}
};

// ---------------------------------------------------------------------------
class FIR {

	double*delayLine;
	double*impulseResponse;
#define length(v) (sizeof(v)/sizeof(*v))

	int count, nCoeff;

	FIR() {
		count = 0;
		setCoeff(coeffSetAVG(30), 30);
	} // default is a 30 coef avg filter good for high freq filtering, i.e. fft anti smearing

	FIR(int nCoeff) {
		setCoeff(coeffSetAVG(nCoeff), nCoeff);
	}

	FIR(double*coefs, int nCoeff) {
		setCoeff(coefs, nCoeff);
	}

	void filter(double*y, int n) {
		for (int i = 0; i < n; i++)
			y[i] = getOutputSample(y[i]);
	}

	void setCoeff(double*coefs, int nCoeff) {
		this->nCoeff = nCoeff;
		impulseResponse = coefs;
		delayLine = new double[nCoeff];
	}

	double getOutputSample(double inputSample) { // evaluate conv
		delayLine[count] = inputSample;
		double result = 0.0;
		int index = count;
		for (int i = 0; i < nCoeff; i++) {
			result += impulseResponse[i] * delayLine[index--];
			if (index < 0)
				index = nCoeff - 1;
		}
		if (++count >= nCoeff)
			count = 0;
		return result;
	}

	double*calcCoeff(int numCoeff, int numband, double*bands, double*desired,
		double*weights, int type) {
		remezCoeffCalc *rc = new remezCoeffCalc();
		double*h = new double[numCoeff];
		rc->remez(h, numCoeff, numband, bands, desired, weights, type);
		return h;
	}

	double*coeffSet01() {
		int numCoeff = 9;
		double desired[] = {0, 0, 0, 1, 1}, // band responses [numband]
			weights[] = {10, 1, 10, 1, 3}, // error weights [numband]
			bands[] = {0, 0.05, 0.1, 0.15, 0.18, 0.25, 0.3, 0.36, 0.41, 0.5
		}; // 0..1 range User-specified band edges [2 * numband]
		return calcCoeff(numCoeff, length(bands) / 2, bands, desired, weights,
			BANDPASS);
	}

	double*coeffSetAVG(int numCoeff)
	{ // avg filter, works fine for high freq signals -> good fft anti smearing filter
		double*h = new double[numCoeff];
		for (int i = 0; i < numCoeff; i++)
			h[i] = (double)i / (i + 1);
		return h;
	}

	double*coeffSet02() { // sample tests
		int numCoeff = 7;
		double *h, desired[] = {0, 1, 0, 1, 0}, // band responses [numband]
			weights[] = {10, 1, 3, 1, 20}, // error weights [numband]
			bands[] = {0, 0.05, 0.1, 0.15, 0.18, 0.25, 0.3, 0.36, 0.41, 0.5
		}; // User-specified band edges [2 * numband]
		h = new double[numCoeff];
		(new remezCoeffCalc())->remez(h, numCoeff, length(bands) / 2, bands,
			desired, weights, BANDPASS);
		return h;
	}
};

#endif
