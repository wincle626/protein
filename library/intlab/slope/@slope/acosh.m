function u = acosh(a)
%ACOSH        slope inverse hyperbolic cosine acosh(a)
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

  u = a;

  u.r = acosh(a.r);
  u.s = slopeconvexconcave('acosh','1./sqrt(sqr(%)-1)',a,0);
  
  if rndold~=0
    setround(rndold)
  end
