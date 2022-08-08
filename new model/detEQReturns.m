
function [m_eq, te]=detEQReturns(stdev, cormat, w0, fixed_assets, fixed_ret)
%
%
%

N = size(stdev,1);

% transformeer de correlatie matrix naar een cov matrix. 
sig = cormat.*(stdev*stdev');

vcm = sig;
P   = eye(N);

% % maak een relatieve covariantie matrix indien een bmnr is opgegeven. 
% if bm_nr>0
%     P(:,bm_nr) = P(:,bm_nr)-1;
%     vcm        = P*vcm*P';
% end

% voer de reverse engineering uit en bereken het evenwichtsrendement. 
[Pv,qv] = ReverseConstrainedMVO(w0,1,vcm,[],[],ones(1,N),1);
H       = eye(N);
Pv      = [H(fixed_assets(1),:);Pv];
qv      = [fixed_ret(1);qv];
q       = Pv\qv;
m_eq    = q*fixed_ret(2)/(H(fixed_assets(2),:)*q); % evenwichtrendement. 

% bereken de tracking error van de reversed engineered portfolio
te   = sqrt(w0'*vcm*w0);

end
