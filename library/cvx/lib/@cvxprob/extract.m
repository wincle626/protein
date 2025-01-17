function [ dbcA, cones, dir, Q, P ] = extract( pp, destructive )
if nargin < 2 | nargout < 7, destructive = false; end

global cvx___
p = cvx___.problems( index( pp ) );
n = length( cvx___.reserved );

%
% Objective
%

dbcA = p.objective;
if isempty(p.objective),
    dir = 1;
    dbcA = cvx( [ 1, 1 ], [] );
elseif strcmp( p.direction, 'minimize' ) | strcmp( p.direction, 'epigraph' ),
    dbcA = sum( vec( dbcA ) );
    dir = 1;
else
    dbcA = - sum( vec( dbcA ) );
    dir = -1;
end

%
% Equality constraints
%

AA = cvx___.equalities;
ineqs = cvx___.needslack;
npre = p.n_equality;
ntot = length( AA );
if p.n_equality > 0,
    AA = AA( p.n_equality + 1 : end, : );
    ineqs = ineqs( p.n_equality + 1 : end, : );
    if destructive,
        cvx___.equalities( p.n_equality + 1 : end ) = [];
        cvx___.needslack( p.n_equality + 1 : end ) = [];
    end
elseif destructive,
    cvx___.equalities = cvx( [ 0, 1 ], [] );
    cvx___.needslack = logical( zeros( 0, 1 ) );
end
if ~isempty( AA ),
    ineqs = [ false ; ineqs ];
    dbcA = [ dbcA ; AA ];
    clear AA
end

%
% Linear forms
%

if p.n_linform > 0,
    A1 = cvx___.linforms( p.n_linform + 1 : end, : );
    A2 = cvx___.linrepls( p.n_linform + 1 : end, : );
    if destructive,
        cvx___.linforms( p.n_linform + 1 : end ) = [];
        cvx___.linrepls( p.n_linform + 1 : end ) = [];
    end
else
    A1 = cvx___.linforms;
    A2 = cvx___.linrepls;
    if destructive,
        cvx___.linforms = cvx( [ 0, 1 ], [] );
        cvx___.linrepls = cvx( [ 0, 1 ], [] );
    end
end
if ~isempty( A1 ),
    zV = cvx_vexity( A2 ); 
    zQ = ( zV == 0 ) - zV;
    dbcA = [ dbcA ; minus( zQ .* A1, zQ .* A2, true ) ];
    ineqs( end + 1 : end + length( A1 ), : ) = zV ~= 0;
    clear A1 A2 zV zQ
end

%
% Univariable forms
%

if p.n_uniform > 0,
    A1 = cvx___.uniforms( p.n_uniform + 1 : end, : );
    A2 = cvx___.unirepls( p.n_uniform + 1 : end, : );
    if destructive,
        cvx___.uniforms( p.n_uniform + 1 : end ) = [];
        cvx___.unirepls( p.n_uniform + 1 : end ) = [];
    end
else
    A1 = cvx___.uniforms;
    A2 = cvx___.unirepls;
    if destructive,
        cvx___.uniforms = cvx( [ 0, 1 ], [] );
        cvx___.unirepls = cvx( [ 0, 1 ], [] );
    end
end
if ~isempty( A2 ),
    zV = cvx_vexity( A2 );
    zQ = ( zV == 0 ) - zV;
    dbcA = [ dbcA ; minus( zQ .* A1, zQ .* A2, true ) ];
    ineqs( end + 1 : end + length( A1 ), : ) = zV ~= 0;
    clear A1 A2 zV zQ
end

%
% Convert to basis
%

dbcA = cvx_basis( dbcA );
nA = size( dbcA, 1 );
if nA < n,
    dbcA( n, end ) = 0;
elseif n < nA,
    dbcA = dbcA( 1 : n, : );
end

%
% Determine which inequalities need slack variables
%

if any( ineqs ),
    slacks = cvx___.canslack;
    if any( slacks ),
        ndxs   = find( ineqs );
        sterms = dbcA( slacks, ineqs );
        oterms = dbcA( slacks, 1 );
        if nnz( sterms ),
            sdirec = cvx___.vexity( slacks );
            pslack = sum( sterms < 0, 2 ) == 1 & sdirec >= 0 & ~any( oterms > 0, 2 );
            nslack = sum( sterms > 0, 2 ) == 1 & sdirec <= 0 & ~any( oterms < 0, 2 );
            qslack = pslack & nslack;
            temp = any( sterms( pslack & ~nslack, : ) < 0, 1 ) | ...
                   any( sterms( nslack & ~pslack, : ) > 0, 1 );
            ineqs( ndxs( temp ) ) = false;
            if any( qslack ),
                ndxs = ndxs( ~temp );
                [ rr, cc, vv ] = find( sterms( qslack, ~temp ) );
                [ c1, ci ] = unique( cc ); [ c2, ri ] = unique( rr( ci ) );
                [ c2, rj ] = unique( rr ); [ c2, cj ] = unique( cc( rj ) );
                if length( c2 ) < length( ri ), c2 = c1( ri ); end
                ineqs( ndxs( c2 ) ) = false;
            end
        end
    end
end

%
% Select the cones used
%

ocones = [];
cones = cvx___.cones;
used = full( any( dbcA, 2 ) );
if all( used ),
    cones = cvx___.cones;
else
    cones = [];
    for k = 1 : length( cvx___.cones ),
        cone = cvx___.cones( k );
        temp = any( reshape( used( cone.indices ), size( cone.indices ) ), 1 );
        if any( temp ),
            ncone = cone;
            ncone.indices = ncone.indices( :, temp );
            if isempty( cones ),
                cones = ncone;
            else
                cones = [ cones, ncone ];
            end
        end
        if destructive & ~all( temp ),
            cone.indices( :, temp ) = [];
            if isempty( ocones ),
                ocones = cone;
            else
                ocones = [ ocones, cone ];
            end
        end
    end
end
if destructive,
    cvx___.cones = ocones;
end

%
% Add the slack variables
%

nsl = nnz( ineqs );
if nsl ~= 0,
    dbcA = [ dbcA ; sparse( 1 : nsl, find( ineqs ), -1, nsl, length( ineqs ) ) ];
    ncone = struct( 'type', 'nonnegative', 'indices', n+1:n+nsl );
    if isempty( cones ),
        cones = ncone;
    else
        tt = find(strcmp({cones.type},'nonnnegative'));
        if ~isempty( tt ),
            cones(tt(1)).indices = [ cones(tt(1)).indices, ncone.indices ];
        else
            cones = [ ncone, cones ];
        end
    end
end

%
% Q and P matrices
%

used = find( used );
Q = sparse( used, used, 1, n, n + nsl );
P = sparse( [ 1, npre + 2 : ntot + 1 ], 1 : ntot - npre + 1, 1, ntot + 1, size( dbcA, 2 ) );

%
% Exponential and logarithm indices
%

esrc = find( cvx___.exponential );
edst = full( cvx___.exponential( esrc ) );
tt   = any(dbcA(esrc,:),2) & any(dbcA(edst,:),2);
if any( tt ),
    % Determine the indices of the exponentials
    esrc = esrc(tt);
    edst = edst(tt);
    nexp = length(esrc);
    lvar = n + nsl + 3 * nexp;
    % Create the exponential cones
    ncone.type = 'exponential';
    ncone.indices = reshape( n+nsl+1:lvar, 3, nexp );
    % Expand Q, P, dbCA
    Q(end,lvar) = 0;
    P(end,lvar) = 0;
    dbcA(lvar,end) = 0;
    % Add equality consraints to tie the exponential cones to esrc and edst
    % and set the exponential perspective variable to 1
    ndxc = reshape( 1 : 3 * nexp, 3, nexp );
    dbcA = [ dbcA, sparse( ...
        [ esrc(:)' ; ones(1,nexp) ; edst(:)' ; ncone.indices ], ...
        [ ndxc ; ndxc ], ... 
        [ ones(3,nexp) ; -ones(3,nexp) ] ) ];
    if isempty( cones ),
        cones = ncone;
    else
        tt = find(strcmp({cones.type},'exponential'));
        if ~isempty( tt ),
            cones(tt(1)).indices = [ cones(tt(1)).indices, ncone.indices ];
        else
            cones = [ cones, ncone ];
        end
    end
end

%
% Reserved flags
%

if destructive,
    cvx_pop( pp, 'extract' );
end

% Copyright 2008 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
