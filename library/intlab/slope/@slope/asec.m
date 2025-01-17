function u = asec(a)
%ASEC         Slope inverse secant asec(a)
%

% written  12/06/98     S.M. Rump
% modified 04/04/04     S.M. Rump  set round to nearest for safety
% modified 04/06/05     S.M. Rump  rounding unchanged
%

  e = 1e-30;
  if 1+e==1-e                           % fast check for rounding to nearest
    rndold = 0;
  else
    rndold = getround;
    setround(0)
  end

  global INTLAB_SLOPE

  u = a;

  u.r = asec(a.r);
  indexc = 1:INTLAB_SLOPE.NUMVAR;
  indexr = 2:INTLAB_SLOPE.NUMVAR+1;
  Xxs = hull(a.r(:,indexc),a.r(:,indexr));
  Index = 1:size(a.r.inf,1);

  index = all( a.r.sup<=0 , 2);
  if any(index)
    aindex.r = a.r(index,:);
    aindex.s = a.s(index,:);
    u.s(index,:) = ...
      slopeconvexconcave('asec','1./(abs(%).*sqrt(sqr(%)-1))',aindex,1);
    Index(index) = 0;
  end

  index = all( a.r.inf>=0 , 2);
  if any(index)
    aindex.r = a.r(index,:);
    aindex.s = a.s(index,:);
    u.s(index,:) = ...
      slopeconvexconcave('asec','1./(abs(%).*sqrt(sqr(%)-1))',aindex,0);
    Index(index) = 0;
  end

  if any(Index)
    Index( Index==0 ) = [];
    Xxs = Xxs(Index);
    u.s(Index,:) = a.s(Index,:) ./ ( abs(Xxs) .* sqrt( sqr(Xxs)-1 ) );
  end
  
  if rndold~=0
    setround(rndold)
  end
