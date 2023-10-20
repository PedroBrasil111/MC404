#include <math.h>
#include <stdio.h>

#ifndef M_PI_4
#define M_PI_4 (3.1415926535897932384626433832795/4.0)
#endif

double FastArcTan(double x) {
  return M_PI_4*x - x*(fabs(x) - 1)*(0.2447 + 0.0663*fabs(x));
}

#define A 0.0776509570923569
#define B -0.287434475393028
#define C (M_PI_4 - A - B)
#define FMT "% 16.8f"

double Fast2ArcTan(double x) {
  double xx = x * x;
  return ((A*xx + B)*xx + C)*x;
}

int main() {
  double mxe1 = 0, mxe2 = 0;
  double err1 = 0, err2 = 0;
  int n = 100;
  for (int i=-n;i<=n; i++) {
    double x = 1.0*i/n;
    //double y = atan(x);
    double y_fast1 = FastArcTan(x);
    double y_fast2 = Fast2ArcTan(x);
    printf("%3d x:% .3f y:" FMT "y1:" FMT "y2:" FMT "\n", i, x, 1, y_fast1, y_fast2);
  }
  printf("max error1: " FMT "sum sq1:" FMT "\n", mxe1, err1);
  printf("max error2: " FMT "sum sq2:" FMT "\n", mxe2, err2);
}