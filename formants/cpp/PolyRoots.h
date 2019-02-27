#ifndef PolyRootsH
#define PolyRootsH

#include <iostream>
#include <cmath>
#include <complex>
#include <cstdlib>
#include <vector>

using namespace std;
using std::vector;

typedef complex<double>Complex;

class PolyRoots {

public:
	static Complex poly(vector<double>A, Complex x) {
        auto n=A.size();
        Complex y = pow(x, n);
		for (int i = 0; i < n; i++)
			y += A[i] * pow(x, (n - i - 1));
		return y;
	}

	// polyroot uses the Durand-Kerner method to find all roots (real and complex) of a polynomial of the form:
	// f(x) = pow(x, n) + a1*pow(x, n - 1) + a2*pow(x, n - 2) + . . . + a(n - 2)*x*x + a(n - 1)*x + a(n)
	// where the vector A = {a1, a2, a3, . . . , a(n - 2), a(n - 1), a(n)}
	static vector<Complex>roots(vector<double>A) {
        
        auto n=A.size()-1;
        
		int iterations = 1000;
		Complex z = Complex(0.4, 0.9);
		vector<Complex>R = vector<Complex>(n);
        
        vector<double>a(n);
        double a0=A[0];
        
        for (int i=0; i<n; i++) a[i]=A[i+1] / (a0?a0:1);
        
		for (int i = 0; i < n; i++) R[i] = pow(z, i);
        
		for (int i = 0; i < iterations; i++) {
			for (int j = 0; j < n; j++) {
				Complex B = poly(a, R[j]);
				for (int k = 0; k < n; k++) {
					if (k != j)
						B /= R[j] - R[k];
				}
				R[j] -= B;
			}
		}
        
//        double sum=0; // -1 roots
//        for (int i = 0; i < n; i++) {
//            auto res=abs(poly(a,n, R[i]));
//            
//            cout    << "R[" << i << "] = " << R[i] <<
//                    "->" << res << endl;
//            
//            sum+=res;
//        }
//        cout << "sum = " << sum << endl;
        
        
		return R;
	}

	// TEST
	static int test() {
        // {0, -29, -58, 54, 216, 216}; //
        vector<double>A = { 1, 2,3,4,5,6,7,8 }; //
		auto R = roots(A);
		for (size_t i = 0; i < R.size(); i++)
			cout << "R[" << i << "] = " << R[i] << "->" << abs(poly(A, R[i])) << endl;
		return 0;
	}
};

/*
 function xroots = durand_kerner(polyCoeffs,toler)
 % DURAND_KERNER calculates the roots of a polynomial simultaneously. The
 %
 method is relatively simple and easy to implement. The Durand
 -
 Kerner
 % algorithm resembles the Gauss
 –
 Seidel method for solving simultneous linear
 % equations.
 n = length(polyCoeffs) - 1;
 xroots = zeros(n,1);
 for i=1:n
    xroots(i) = complex(0.4,0.9)^i;
 end
 
 bStop = false;
 while ~bStop
    lastRoots=xroots;
    for i=1:n
        prod = 1;
        for j=1:n
        if i~=j
            prod = prod * (xroots(i) - xroots(j));
        end
    end
    xroots(i) = xroots(i) - polyval(polyCoeffs, xroots(i))/prod;
 
 */
#endif
