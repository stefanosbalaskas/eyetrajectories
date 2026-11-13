#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

extern SEXP etr_dgeev_unsorted(SEXP);

static const R_CallMethodDef call_entries[] = {
    {"etr_dgeev_unsorted", (DL_FUNC) &etr_dgeev_unsorted, 1},
    {NULL, NULL, 0}
};

void R_init_eyetrajectories(DllInfo *dll) {
    R_registerRoutines(dll, NULL, call_entries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
