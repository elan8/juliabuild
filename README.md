# Julia Build Without GPL Libraries

This repository contains documentation and scripts for building Julia without GPL licensed libraries using the `USE_GPL_LIBS=0` build option.

## Overview

Julia can be built without GPL licensed dependencies by setting the `USE_GPL_LIBS=0` build option. This creates a more permissive build that avoids GPL licensing restrictions while maintaining core functionality.

## ⚠️ Important Warning: SparseArrays Exclusion

**This build completely excludes SparseArrays and related functionality.** The following features will **NOT** work with this GPL-free build:

### Excluded Functionality:
- **Sparse matrix operations** - All sparse matrix types and operations
- **SuiteSparse integration** - CHOLMOD, UMFPACK, and other SuiteSparse components
- **LinearAlgebra sparse methods** - Sparse matrix factorization and solving
- **Statistics sparse extensions** - Sparse matrix statistical operations
- **Any code that depends on SparseArrays** - Third-party packages requiring sparse matrices

### What Still Works:
- **Dense matrix operations** - All standard LinearAlgebra functionality
- **Core Julia functionality** - All base language features
- **Most standard libraries** - Everything except SparseArrays and related components
- **Third-party packages** - Any package that doesn't depend on SparseArrays

### Use Cases:
This build is suitable for:
- **Embedded systems** - Where GPL licensing is problematic
- **Commercial applications** - Requiring permissive licensing
- **Educational environments** - Where sparse matrices aren't needed
- **General computing** - Where dense matrices are sufficient

**If you need sparse matrix functionality, use the standard Julia build instead.**

## 🗺️ Roadmap: PaStiX Integration

We are planning to replace the excluded SuiteSparse functionality with **PaStiX**, a high-performance sparse matrix library with permissive licensing. https://gitlab.inria.fr/solverstack/pastix

### Planned Features:
- **Sparse matrix types** - Reimplement sparse matrix data structures
- **Direct solvers** - Sparse LU, Cholesky, and QR factorizations
- **Iterative solvers** - Conjugate gradient, GMRES, and other Krylov methods
- **LinearAlgebra integration** - Full compatibility with Julia's LinearAlgebra interface
- **Statistics support** - Sparse matrix statistical operations

### Benefits of PaStiX:
- **Permissive licensing** - Compatible with commercial and embedded use
- **High performance** - Optimized for modern architectures
- **Active development** - Well-maintained and feature-rich
- **MPI support** - Parallel sparse matrix operations

### Contributing:
We welcome contributions to this effort! Areas where help is needed:

- **Core sparse matrix implementation** - Data structures and basic operations
- **LinearAlgebra integration** - Interface compatibility with Julia's standard library
- **Testing and validation** - Ensuring correctness and performance
- **Documentation** - User guides and API documentation
- **Performance optimization** - Benchmarking and tuning

**Interested in helping?** Please open an issue or submit a pull request to discuss your contribution ideas.

