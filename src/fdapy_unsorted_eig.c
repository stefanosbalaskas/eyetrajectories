/* Unsigned scientific raw order of LAPACK DGEEV, as NumPy linalg.eig.
 * This is a registered C wrapper: R does not expose raw dgeev via .Fortran
 * from package namespaces, especially on Windows. It is intentionally not
 * exported as a public R function or used for any Python invocation.
 */
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Lapack.h>
#include <R_ext/RS.h>
#include <math.h>
#include <string.h>
#include <limits.h>

SEXP etr_dgeev_unsorted(SEXP x) {
    if (TYPEOF(x) != REALSXP || !Rf_isMatrix(x))
        Rf_error("FDApy DGEEV input must be a double-precision matrix");
    SEXP dims = Rf_getAttrib(x, R_DimSymbol);
    int n = INTEGER(dims)[0];
    if (n < 2 || n != INTEGER(dims)[1] || n > 46340)
        Rf_error("FDApy DGEEV needs a square matrix with 2 <= n <= 46340");
    R_xlen_t count = (R_xlen_t)n * (R_xlen_t)n;
    for (R_xlen_t i = 0; i < count; ++i)
        if (!R_FINITE(REAL(x)[i]))
            Rf_error("FDApy DGEEV requires finite matrix values");

    SEXP a = PROTECT(Rf_duplicate(x));
    SEXP wr = PROTECT(Rf_allocVector(REALSXP,n));
    SEXP wi = PROTECT(Rf_allocVector(REALSXP,n));
    SEXP vr = PROTECT(Rf_allocMatrix(REALSXP,n,n));

    char jobvl = 'N', jobvr = 'V';
    int ldvl = 1, ldvr = n, lda = n, info = 0;
    double vl_dummy = 0.0, opt_work = 0.0;
    int lwork = -1;
    F77_CALL(dgeev)(&jobvl, &jobvr, &n, REAL(a), &lda,
        REAL(wr), REAL(wi), &vl_dummy, &ldvl, REAL(vr), &ldvr,
        &opt_work, &lwork, &info FCONE FCONE);
    if (info != 0 || !R_FINITE(opt_work) ||
        opt_work > (double)INT_MAX || opt_work < (double)(4*n))
        Rf_error("FDApy LAPACK DGEEV workspace query failed (INFO=%d)",info);

    lwork = (int)ceil(opt_work);
    double *work = (double*)R_alloc((size_t)lwork,sizeof(double));
    /* A is overwritten during a workspace query on some LAPACK builds. */
    memcpy(REAL(a),REAL(x),(size_t)count * sizeof(double));
    F77_CALL(dgeev)(&jobvl, &jobvr, &n, REAL(a), &lda,
        REAL(wr), REAL(wi), &vl_dummy, &ldvl, REAL(vr), &ldvr,
        work, &lwork, &info FCONE FCONE);
    if (info != 0)
        Rf_error("FDApy LAPACK DGEEV eigenvectors failed (INFO=%d)",info);
    for (int i = 0; i < n; ++i)
        if (!R_FINITE(REAL(wr)[i]) || !R_FINITE(REAL(wi)[i]) ||
            fabs(REAL(wi)[i]) > 1e-10 * (1.0 + fabs(REAL(wr)[i])))
            Rf_error("FDApy DGEEV returned a nonreal or nonfinite eigenpair");
    for (R_xlen_t i = 0; i < count; ++i)
        if (!R_FINITE(REAL(vr)[i]))
            Rf_error("FDApy DGEEV returned a nonfinite right eigenvector");

    SEXP out = PROTECT(Rf_allocVector(VECSXP,2));
    SEXP names = PROTECT(Rf_allocVector(STRSXP,2));
    SET_STRING_ELT(names,0,Rf_mkChar("values"));
    SET_STRING_ELT(names,1,Rf_mkChar("vectors"));
    SET_VECTOR_ELT(out,0,wr);
    SET_VECTOR_ELT(out,1,vr);
    Rf_setAttrib(out,R_NamesSymbol,names);
    UNPROTECT(6);
    return out;
}
