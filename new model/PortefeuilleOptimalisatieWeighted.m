function [output] = PortefeuilleOptimalisatieWeighted(doel,pars,restricties,Niter,Nport,tekst)

schaal = 3; %Zorgt voor een grotere nauwkeurigheid
Nport  = Nport*schaal;
N      = size(pars.meanmat,1); 
w_0    = ones(N,1)/N; 
w_i    = w_0*ones(1,Nport); 

%Random start
w_i = 0.1+rand(N,Nport);
w_i = matdiv(w_i,sum(w_i,1));

%BEREKEN HIER DE RELATIEVE COVARIANTIE MATRIX.
if pars.bm>0
    P = eye(N);
    P(:,pars.bm) = P(:,pars.bm)-1;
    for i=1:size(pars.meanmat,2)
        pars.meanmat(:,i)  = P*pars.meanmat(:,i);
        pars.covmat(:,:,i) = P*pars.covmat(:,:,i)*P';
    end
end

[U_i,m_i,s_i]  = Utility(w_i,doel,pars,restricties,restricties.Ax,restricties.onx,Nport);
%[U_i,m_i,s_i]  = Utility(w_i,doel,pars,restricties,restricties.onx,Nport);

T     = 1;
alpha = 0.95;

min_d   = max(1,1/Niter)/N;
dir_par = ones(Nport,N)*min_d;

if nargin<6
    wsbar = waitbar(0,'Even geduld...'); 
else
    txt = strcat('Doorrekenen: ',tekst);
    wsbar = waitbar(0,txt);
end

for i=1:Niter
    if mod(i,round(0.1*Niter))==0
        waitbar(i/Niter,wsbar);
    end
    w_j           = dirichsim(dir_par)';
    [U_j,m_j,s_j] = Utility(w_j,doel,pars,restricties,restricties.Ax,restricties.onx,Nport);
    prob          = min([ones(1,Nport);exp(-(U_j-U_i)/T)]);
    if doel==0
        prob = matmul(U_i>0,prob);
    end
    ex            = rand(1,Nport)<prob;
    w_i           = matmul(ex,w_j)+matmul(1-ex,w_i);
    U_i           = matmul(ex,U_j)+matmul(1-ex,U_i);
    m_i           = matmul(ex,m_j)+matmul(1-ex,m_i);    
    s_i           = matmul(ex,s_j)+matmul(1-ex,s_i);
    T             = alpha*T;     
    dir_par       = dir_par+i*w_i'/Niter;     
    if doel==0 && sum(U_i)==0
        break;
    end
end

Nport = Nport/schaal;

[U_i,six] = sort(U_i);
NN  = size(w_i,1);
w_i = VasteGewichten(w_i(:,six),restricties.b(1:2*NN),restricties.A(2*NN+1:4*NN,:),restricties.Ax,restricties.onx);
m_i = m_i(:,six);
s_i = s_i(:,six);

output.wts  = w_i(:,1:Nport);
output.nut  = U_i(1:Nport);
output.mu   = m_i(:,1:Nport);
output.sig  = s_i(:,1:Nport);

close(wsbar);

end

function [U,re,te] = Utility(ww,doel,pars,restricties,Ax,onx,Nport)
        
    A = restricties.A;
    b = restricties.b;

    N  = size(ww,1);
    wt = VasteGewichten(ww,b(1:2*N),A(2*N+1:4*N,:),Ax,onx);
    U  = 0;      
   
  	%Check restricties op portefeuillegewichten
    boete = 999999; 
    rest  = matsub(A*wt,b);
    U     = U+boete*sum(rest.*(rest>0),1);    	
    rest  = sum(abs(matsub(wt,restricties.w0))/2,1)-restricties.dw0;
    U     = U+boete*(rest.*(rest>0));
    
    %Check extra restricties
    
    
    if (restricties.ExtraActive)
    
        maxER = max(restricties.onx);

        % bepaal relatieve gewichten
        boete = 99999;     
        for ii=1:maxER

%         relativeW = matdiv(restricties.Ax(restricties.onx==ii,:)*wt,(sum(abs(restricties.Ax(restricties.onx==ii,:)*wt),1)/2));
% 
% 
%         % check restrictie relative weights
%         rest=matsub(relativeW,restricties.bx(restricties.onx==ii,:));
%         U     = U+boete*sum(rest.*(rest>0),1);  

        % check restrictie sum-weights in group
        boete = 99999;     

        rest  = sum(abs(restricties.Ax(restricties.onx==ii,:)*wt),1)/2-restricties.groupLB(min(find(restricties.onx==ii)));    % lower bound group
        U     = U+boete*(-rest.*(rest<0));

        rest  = sum(abs(restricties.Ax(restricties.onx==ii,:)*wt),1)/2-restricties.groupUB(min(find(restricties.onx==ii)));    % upper bound group
        U     = U+boete*(rest.*(rest>0));

        end
    
%     rest  = matsub(restricties.Ax'*wt,restricties.bx');
%     U     = U+boete*restricties.onx*(rest.*(rest>0));
%     rest  = matsub(-restricties.Ax'*wt,restricties.bx');
%     U     = U+boete*restricties.onx*(rest.*(rest>0));
    end
    
    
%    [mu,sig] = Mixture_Moments(pars);
    
    sig=pars.covmat;
    
    
	% rest restricties
    boete = 999999; 
    noViews = size(pars.probs,2)
    
    re=0;

    for ii=1:noViews
    
    re       = re+pars.probs(ii)*(pars.meanmat(:,ii)'*wt);
    
    end
    
    te       = sqrt(sum(wt'*sig.*wt',2))';
    lpm      = LPM_Utility(wt,pars);
    te_upp   = matsub(te,restricties.MaxTE);   % Te hoog risico
    re_low   = matsub(restricties.MinRet,re);  % Te laag rendement
    lpm_upp  = matsub(lpm,restricties.MaxLPM); % Te hoge LPM
    
    U = U+boete*restricties.MaxTE_actief*sum(te_upp.*(te_upp>0),1);
    U = U+boete*restricties.MinRet_actief*re_low.*(re_low>0);
    U = U+boete*restricties.MaxLPM_actief*sum(lpm_upp.*(lpm_upp>0),1);
        
    if doel==1
        U = U-re;
    elseif doel==2
        U = U+te;
    elseif doel==3
        U = U+lpm;
    end 
end

function [ww] = VasteGewichten(w,b,A,Ax,onx)

% if sum(onx==1)>0
%     P = Ax(:,onx==1);
%     w = w-pinv(P)'*(P'*w);
% end

w = matdiv(w,sum(w,1));

N      = size(b,1)/2;
b1     = -b(1:N);
b2     = b(N+1:end);
bounds = [b1 b2];

[N,K] = size(w);

ww = w;
ex = bounds(:,1)==bounds(:,2);
if sum(ex)>0
    ww(ex,:)      = bounds(ex,1)*ones(1,K);
    xsum          = matdiv(ww(not(ex),:),sum(ww(not(ex),:)));
    ww(not(ex),:) = ww(not(ex),:)+matmul(sum(w(ex,:)-ww(ex,:),1),xsum); 
end

%Tweede check gewichten binnen matching cq return portefeuille
A1 = A(1:N,:);
A2 = A(N+1:2*N,:);
AA = A1+A2;
ex = sum(AA.*AA,2)==0;
if sum(ex)>0
    Nex = sum(ex);
    A1  = A(ex,:);
    hh  = [-A1*ww;zeros(1,size(ww,2))]; 
    A1  = [A1;ones(1,N)];
    dw  = pinv(A1)*hh; 
    ww  = ww+dw;
end    

end

function [U_lpm] = LPM_Utility(wts,pars)    
	meanmat = pars.meanmat;
	sigmat  = pars.covmat;
	probs   = pars.probs;

    %Calculate mu and sigma per regime
    for j=1:size(meanmat,2)
        mu(:,j)  = wts'*meanmat(:,j);
%        sig(:,j) = sqrt(sum(wts'*sigmat(:,:,j).*wts',2))';               
        sig(:,j) = sqrt(sum(wts'*sigmat.*wts',2))';               

    end

    %Calculate utility
    U_lpm = LowerPartialMoments(pars.lpm_orde,pars.lpm_target,mu,sig,probs);    
end


function [lpm] = LowerPartialMoments(orde,target,mu,sigma,probs)
    a_i = (target-mu)./sigma;       %Standardized value of return target
    if (orde==0)
        lpm = normcdf(a_i);
    elseif (orde==1)        
        lpm = sigma.*(normpdf(a_i)+a_i.*normcdf(a_i));
    elseif (orde==2)
        lpm = sigma.*sigma.*(a_i.*normpdf(a_i)+(1+a_i.*a_i).*normcdf(a_i));        
    else
        lpm = 0;
        error('Lower Partial Moments: k>2 not implemented yet') 
    end
    lpm = lpm*probs';                   %Weight with regime probability
	if orde==2
		lpm = lpm.^(1/orde);
	end
    lpm = lpm';
end