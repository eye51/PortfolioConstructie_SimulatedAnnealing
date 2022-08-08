function [m_eq,cov_eq,rt] = IR_assumptions(data,bjaar,ejaar,bm_reeks,bm_rend,ir)

%
%   data = historische jaar rendementen (gegeven in excel)
%   bjaar = start jaar voor analyse
%   ejaar = eind jaar voor analyze 
%   bm_reeks = id van return series die als benchmark gebruikt moet worden
%   bm_rend = gegeven rendement vd BM
%   ir = inverse informatie ratio BM (1/IR)
%

% 1e methode -> wordt later overschreven door IR methode
% bepaal evenwichts rendementen + covariantie matrix uit historische data

jaar      = data(:,1);                          % time-stamps
ex        = (jaar>=bjaar) & (jaar<=ejaar);      % filter voor date-range
yt        = data(ex,2:end);                     % observaties tussen bjaar en ejaar
yt(yt==0) = NaN;

[m_eq,cov_eq,rt] = EM_miss(yt); % vul missing observaties

%rt     = CumReturn(rt,3,1,1); %driejaars rendementen
%cov_eq = cov(rt);

%Alternatief -> gebasseerd op IR BM

P = eye(size(yt,2));
if bm_reeks>0
    P = matsub(P,P(bm_reeks,:));
end

cov_bm = P*cov_eq*P';
m_eq   = bm_rend+sqrt(diag(cov_bm))/ir;

end