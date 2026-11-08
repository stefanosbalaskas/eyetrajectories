#!/usr/bin/env python3
"""Frozen Python SciPy 1D fixed-radius neighbor oracle, no R execution."""
import numpy as np
from scipy.sparse import coo_matrix
from scipy.spatial import cKDTree

def auto(x,radius,theiler):
    pairs={tuple(sorted((int(i),int(j)))) for i,j in
        cKDTree(np.asarray(x,float)[:,None]).query_pairs(radius)
        if abs(i-j)>theiler}
    return pairs

def main():
    x=np.array([0,1,.05,3,3.05,8,9])
    edges=auto(x,.1,1)
    assert edges=={(0,2)},edges
    pairs={tuple(sorted((int(i),int(j)))) for i,j in
       cKDTree(np.array([0,2,0,3,3,5])[:,None]).query_pairs(0)}
    assert pairs=={(0,2),(3,4)}
    y=np.array([.01,1.02,2.2,3.05])
    z=np.array([0,1,2,3,4])
    p=cKDTree(z[:,None]).query_ball_tree(cKDTree(y[:,None]),.1)
    assert p==[[0],[1],[],[3],[]],p
    n=12005
    assert not auto(np.arange(n),.49,0)
    print('BATCH26_SCIPY_SPARSE_CONSTRUCTION_REFERENCE_PASS=TRUE;'
          'auto_edge_pairs=1;cross_edge_pairs=3;large_nodes=12005')

if __name__=='__main__':main()
