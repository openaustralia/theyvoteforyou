#!/usr/bin/perl
#
# Eigs.pm:
# Compute eigenvalues and eigenvectors of a real symmetric matrix.
#
# (From PoliticalSurvey.)
#
# Copyright (c) 2003 Chris Lightfoot. All rights reserved.
# Email: chris@ex-parrot.com; WWW: http://www.ex-parrot.com/~chris/
#
# $Id: Eigs.pm,v 1.1 2004/01/29 19:22:33 frabcus Exp $
#

package Eigs;

use strict;

use Error qw(:try);

use Inline C => Config => LIBS => '-lgslcblas -lgsl';

use Inline C => <<'END_C';

#include <math.h>
#include <stdio.h>  /* debugging */
#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_eigen.h>

/* gsl_vector_to_aryref VECTOR
 * Return a reference to a list whose elements are the elements of VECTOR. */
SV *gsl_vector_to_aryref(const gsl_vector *v) {
    AV *a;
    int i;
    a = newAV();
    for (i = 0; i < (int)v->size; ++i)
        av_push(a, newSVnv(gsl_vector_get(v, i)));
    return newRV_noinc((SV*)a);
}

/* compute_eigs VECTORS MATRIX
 * Compute the eigenvectors and eigenvalues of MATRIX, a reference to a list of
 * matrix rows. If VECTORS is true, returns a reference to a list of
 * [ eigenvalue, [v0, v1, ...] ]; or, if it is false, a reference to a list of
 * the eigenvalues alone. */
SV *compute_eigs(int vectors, SV *mat) {
    AV *rows;
    int nrows, i, j;
    gsl_matrix *M;

    if (!SvROK(mat) || SvTYPE(SvRV(mat)) != SVt_PVAV)
        croak("MATRIX is not a reference to a list");

    rows = (AV*)SvRV(mat);
    if (-1 == (nrows = (int)av_len(rows)))
        croak("no rows in MATRIX");

    ++nrows;
    
    /* Translate the perl reference-to-list-of-lists into a GSL matrix. */
    M = gsl_matrix_calloc(nrows, nrows);

    for (i = 0; i < nrows; ++i) {
        SV *r, **pr;
        AV *cols;
        if (!(pr = av_fetch(rows, i, 0))) {
            gsl_matrix_free(M);
            croak("NULL row in MATRIX");
        }
        r = *pr;
        if (!SvROK(r) || SvTYPE(SvRV(r)) != SVt_PVAV) {
            gsl_matrix_free(M);
            croak("one or more rows in MATRIX is not a reference");
        }
        cols = (AV*)SvRV(r);
        if (av_len(cols) != nrows - 1) {
            gsl_matrix_free(M);
            croak("MATRIX is not square");
        }
        for (j = 0; j < nrows; ++j) {
            SV *s, **ps;
            if (!(ps = av_fetch(cols, j, 0))) {
                gsl_matrix_free(M);
                croak("NULL element in MATRIX");
            }
            s = *ps;
            if (!SvOK(s) || !SvNOK(s)) {
                gsl_matrix_free(M);
                croak("one or more elements of MATRIX is not a number");
            }
            gsl_matrix_set(M, i, j, SvNVX(s));
        }
    }

    if (vectors) {
        /* Eigenvalues and eigenvectors. */
        SV *aryref;
        AV *ary;
        gsl_eigen_symmv_workspace *w;
        gsl_vector *vals;
        gsl_matrix *vecs;

        w = gsl_eigen_symmv_alloc(nrows);
        vals = gsl_vector_alloc(nrows);
        vecs = gsl_matrix_alloc(nrows, nrows);
        gsl_eigen_symmv(M, vals, vecs, w);
        gsl_eigen_symmv_sort(vals, vecs, GSL_EIGEN_SORT_ABS_DESC);

        /* Construct the return value. We want,
         *
         *  [ [ eigenvalue, [ ... eigenvector ... ] ],
         *    [ eigenvalue, [ ... eigenvector ... ] ],
         *          ... ]
         */
        ary = newAV();
        for (i = 0; i < nrows; ++i) {
            AV *item;
            SV *itemref;
            gsl_vector_view vv;
            item = newAV();
            av_push(item, newSVnv(gsl_vector_get(vals, i)));
            vv = gsl_matrix_column(vecs, i);
            av_push(item, (SV*)gsl_vector_to_aryref(&vv.vector));
            av_push(ary, (SV*)newRV_noinc(item));
        }

        gsl_eigen_symmv_free(w);
        gsl_vector_free(vals);
        gsl_matrix_free(vecs);
        gsl_matrix_free(M);
        
        return newRV_noinc((SV*)ary);
    } else {
        /* Eigenvalues only. */
        SV *aryref;
        gsl_eigen_symm_workspace *w;
        gsl_vector *vals;

        /* Construct workspace, compute eigenvectors. */
        w = gsl_eigen_symm_alloc(nrows);
        vals = gsl_vector_alloc(nrows);
        gsl_eigen_symm(M, vals, w);
    
        /* XXX should sort vals */

        /* Construct perl array. */
        aryref = gsl_vector_to_aryref(vals);
        
        gsl_eigen_symm_free(w);
        gsl_vector_free(vals);
        gsl_matrix_free(M);

        return aryref;
    }
}

END_C

1;
