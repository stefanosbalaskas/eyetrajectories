#!/usr/bin/env python3
"""Noncertifying SciPy ground-truth geometry for Batch 23 sparse algorithms."""
from scipy.sparse import csr_matrix
from scipy.sparse.csgraph import connected_components
import numpy as np

n=12005
u=np.array([0,1,0,99,100],dtype=int)
v=np.array([1,2,2,100,101],dtype=int)
m=csr_matrix((np.ones(10,dtype=bool),(np.r_[u,v],np.r_[v,u])),shape=(n,n))
assert m.nnz==10
assert (m!=m.T).nnz==0
assert not m.diagonal().any()
degree=np.asarray(m.sum(axis=1)).reshape(-1).astype(int)
assert degree[[0,1,2,99,100,101]].tolist()==[2,2,2,1,2,1]
components, labels=connected_components(m,directed=False)
assert components==12001
assert len(np.bincount(labels))==components
triangles=1
triples=int(np.sum(degree*(degree-1)//2))
assert triangles==1 and triples==4 and abs(3*triangles/triples-.75)<1e-15
joint=m.multiply(m).tocsr();joint.eliminate_zeros()
assert joint.nnz==m.nnz
eligible=n*(n-1)//2
assert eligible>0
assert np.sum(joint.nonzero()[0]<joint.nonzero()[1])==5
print('BATCH23_SCIPY_REFERENCE_PASS: nodes=12005 edges=5 components=12001 transitivity=.75')
