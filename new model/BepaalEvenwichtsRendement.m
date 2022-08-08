
function [m_eq, te]=detEQReturns(stdev, cormat)
%
%
%

N = size(stdev,1);

% transformeer de correlatie matrix naar een cov matrix. 
sig = cormat.*(stdev*stdev');

vcm = sig;
P   = eye(N);

% maak een relatieve covariantie matrix indien een bmnr is opgegeven. 
if bm_nr>0
    P(:,bm_nr) = P(:,bm_nr)-1;
    vcm        = P*vcm*P';
end

% voer de reverse engineering uit en bereken het evenwichtsrendement. 
[Pv,qv] = ReverseConstrainedMVO(w0,1,vcm,[],[],ones(1,N),1);
H       = eye(N);
Pv      = [H(vast_nr(1),:);Pv];
qv      = [vast_ret(1);qv];
q       = Pv\qv;
m_eq    = q*vast_ret(2)/(H(vast_nr(2),:)*q); % evenwichtrendement. 

% bereken de tracking error van de reversed engineered portfolio
te   = sqrt(w0'*vcm*w0);

end
