function x = touch( p, x, iseq )
if nargin < 3, iseq = false; end

if isa( x, 'cvx' ),
    global cvx___
    p  = index( p );
    b  = cvx_basis( x );
    y  = any( b, 2 );
    if iseq,
    	cvx___.canslack( find( y ) ) = false;
    end
    v  = cvx___.problems( p ).t_variable;
    nv = size( v, 1 );
    ny = length( y );
    if ny < nv, 
        y( nv, : ) = 0;
    elseif nv < ny, 
        y = y( 1 : nv, : );
    end
    cvx___.problems( p ).t_variable = v | y;
end

% Copyright 2008 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
