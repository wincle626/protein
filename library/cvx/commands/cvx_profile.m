function sout = cvx_profile( flag )

% CVX_PROFILE	CVX-specific profiler control.
%    This is a function used for internal CVX development to help determine 
%    performance limits within the CVX code itself, by turning off the profiler
%    when the solver is being called. End users will likely not find this
%    function to be useful.

cvx_global
s = cvx___.profile;
if nargin == 1,
    nflag = [];
    if isnumeric(flag) | islogical(flag),
        ns = double(flag) ~= 0;
    elseif ischar(flag) & size(flag,1) == 1,
        switch lower(flag),
            case 'true',
                ns = true;
            case 'false',
                ns = false;
            otherwise,
                error( 'String arugment must be ''true'' or ''false''.' );
        end
    else
        error( 'Argument must be a numeric scalar or a string.' );
    end
    if cvx___.profile ~= ns,
        cvx___.profile = ns;
        stat = profile('status');
        if ns & ~isempty( cvx___.problems ) & ~isequal( stat.ProfilerStatus, 'on' ),
            profile on
        elseif ~ns & isequal( stat.ProfilerStatus, 'on' ),
            profile off
        end
    end
end
if nargin == 0 | nargout > 0,
    sout = s;
end
  
% Copyright 2008 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
  

