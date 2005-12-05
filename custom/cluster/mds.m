# $Id: mds.m,v 1.2 2005/12/05 01:44:39 frabcus Exp $
# Multidimensional scaling on matrix of distances between
# pairs of MPs, for some distance metric.
# Octave source file (should be compatible with Matlab)
    
# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# read in the matrix of distances between pairs of MPs
source "DN.m";
s=size(D);
mps=s(1)

# perform the MDS decomposition 
A=-0.5*D.*D;
H=eye(mps) - 1/mps; # idempotent H*H=H
B=H*A*H;

# this should be a diagonal decomposition because B is symmetric 
[U, S]=schur(B,"u");

# output data to file
ff = fopen("out.txt", "w");
fprintf(ff, "%d %f %f %f\n", mps, S(1,1), S(2,2), S(3,3));
for i=1:mps
        fprintf(ff, "%d %f %f %f \"%s\" \"%s\"\n", i, U(i,1),U(i,2),U(i,3),ns(i,:),ps(i,:));
endfor
fclose(ff)

