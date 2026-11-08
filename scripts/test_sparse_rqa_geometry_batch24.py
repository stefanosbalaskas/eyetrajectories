#!/usr/bin/env python3
"""Frozen recurrence.py line conventions with SciPy COO/CSR, no R execution."""
import numpy as np
from scipy.sparse import csr_matrix
from collections import Counter

def runlengths(group, pos):
    if not len(group): return []
    order=np.lexsort((pos,group)); g=group[order]; p=pos[order]
    breaks=np.r_[True, (np.diff(g)!=0) | (np.diff(p)!=1)]
    starts=np.flatnonzero(breaks)
    return np.diff(np.r_[starts,len(g)]).tolist()

def main():
    n=12005
    left=np.array([0,1,0,99,100]); right=np.array([1,2,2,100,101])
    rows=np.r_[left,right];cols=np.r_[right,left]
    a=csr_matrix((np.ones(10,dtype=bool),(rows,cols)),shape=(n,n))
    coo=a.tocoo(); upper=coo.row<coo.col
    diagonal=runlengths(coo.col[upper]-coo.row[upper],coo.row[upper]);
    vertical=runlengths(coo.col,coo.row)
    dq=[x for x in diagonal if x>=2]; vq=[x for x in vertical if x>=2]
    det=sum(dq)/int(upper.sum());lam=sum(vq)/a.nnz
    corm=100*np.sum(coo.col[upper]-coo.row[upper])/((n-1)*upper.sum())
    assert sorted(diagonal)==[1,2,2],diagonal
    assert sorted(dq)==[2,2]
    assert sorted(vq)==[2,2]
    assert abs(det-.8)<1e-14 and abs(lam-.4)<1e-14
    assert abs(corm-100*6/(12004*5))<1e-14
    print('BATCH24_SCIPY_LINE_RQA_REFERENCE_PASS: nodes=12005 diag=2,2 vertical=2,2 DET=.8 LAM=.4')
if __name__=='__main__':main()
