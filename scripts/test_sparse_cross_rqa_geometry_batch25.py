#!/usr/bin/env python3
"""Bounded source-geometry self-check; no R execution or certification."""
import numpy as np
from scipy.sparse import csr_matrix
from collections import Counter

row=np.array([0,1,2,2,3,4,5,0,1]);col=np.array([1,2,3,6,7,8,8,5,6]); nrow,ncol=7,9
matrix=csr_matrix((np.ones(row.size,dtype=bool),(row,col)),shape=(nrow,ncol))
assert matrix.nnz==9
coo=matrix.tocoo()
def runs(groups,positions):
    res=[]
    for g in sorted(set(groups.tolist())):
        ps=np.sort(positions[groups==g]);starts=np.r_[True,np.diff(ps)!=1]
        ids=np.flatnonzero(starts)
        res.extend(np.diff(np.r_[ids,len(ps)]))
    return res
D=[v for v in runs(coo.col-coo.row,coo.row) if v>=2]
V=[v for v in runs(coo.col,coo.row) if v>=2]
assert sorted(D)==[2,3,3],D
assert sorted(V)==[2,2],V
assert np.isclose(sum(D)/9,8/9)
assert np.isclose(sum(V)/9,4/9)
assert Counter(D)==Counter({2:1,3:2})
assert np.isnan(float('nan'))
print('BATCH25_SCIPY_RECTANGULAR_CROSS_RQA_PASS: points=9 diag=2,3,3 DET=8/9 vertical=2,2 LAM=4/9')
