function [output] = Check_Restricties_SA(R,doel,RetBounds,RiskBounds,pars,Niter,Nport,A,b,tekst,w_t0,Rest_turnover,lpm_par)

schaal = 2;             %Zorgt voor een grotere nauwkeurigheid
Nport  = Nport*schaal;
N      = size(R,2)-2;   %Eerste twee kolommen bevatten verplichtingenrendement
w_0    = ones(N,1)/N; 

w_i            = w_0*ones(1,Nport); 
[U_i,m_i,s_i]  = Utility(w_i,R,doel,pars,RetBounds,RiskBounds,A,b,w_t0,Rest_turnover,lpm_par);

T     = 1;
alpha = 0.95;

min_d   = max(1,1/Niter)/N;
dir_par = ones(Nport,N)*min_d;

wsbar = waitbar(0,tekst); 
for i=1:Niter
    if mod(i,round(0.01*Niter))==0
        waitbar(i/Niter,wsbar);
    end
    w_j           = dirichsim(dir_par)';
    [U_j,m_j,s_j] = Utility(w_j,R,doel,pars,RetBounds,RiskBounds,A,b,w_t0,Rest_turnover,lpm_par);
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
    h = mean(U_i>0);    
end

Nport = Nport/schaal;

[U_i,six] = sort(U_i);
w_i = VasteGewichten(w_i(:,six),b(1:2*size(w_i,1)));
m_i = m_i(:,six);
s_i = s_i(:,six);

output.wts  = w_i(:,1:Nport);
output.nut  = U_i(1:Nport);
output.mu   = m_i(:,1:Nport);
output.sig  = s_i(:,1:Nport);

close(wsbar);

end

function [U,re,te] = Utility(ww,Rscen,doel,pars,Retbnd,Riskbnd,A,b,w_t0,Rest_turnover,lpm_par)
    wt      = VasteGewichten(ww,b(1:2*size(ww,1)));
    U       = 0; 
    boete   = 9999;
    
    R       = Rscen(:,3:end);
    if pars.bm_er>0
        ER = matsub(R,Rscen(:,pars.bm_er));
    else
        ER = R;
    end
    if pars.bm_te1>0
        TE1 = matsub(R,Rscen(:,pars.bm_te1));
    else
        TE1 = R;
    end
    if pars.bm_te2>0
        TE2 = matsub(R,Rscen(:,pars.bm_te2));
    else
        TE2 = R;
    end
    
    re      = mean(ER*wt);
    te1     = std_alt(TE1*wt);
    te2     = std_alt(TE2*wt);    
	te      = [te1;te2];
    te_upp  = matsub(te,Riskbnd(2,:)');   % Te hoog risico
	te_low  = matsub(Riskbnd(1,:)',te);   % Te laag risico
    re_upp  = matsub(re,Retbnd(2));    % Te hoog rendement
	re_low  = matsub(Retbnd(1),re);    % Te laag rendement
    U       = U+boete*sum(te_upp.*(te_upp>0)+te_low.*(te_low>0));
	U    	= U+boete*(re_upp.*(re_upp>0)+re_low.*(re_low>0));

	%Check restricties op portefeuillegewichten
    rest    = matsub(A*wt,b);
    U       = U+boete*sum(rest.*(rest>0));    	
    
    rest    = sum(abs(matsub(wt,w_t0))/2)-Rest_turnover; 
    U       = U+boete*(rest.*(rest>0)); 
    
    if doel==1
        U = U-re;
    elseif doel==2
        U = U+Scenario_LPM(ER*wt,lpm_par.order,lpm_par.target);
    elseif doel==3
        U = U+te1;
    elseif doel==4
        U = U+te2;
    end
    
    %Nog een extra doelstelling: minimaliseer som gekwadrateerde gewichten
    %U = U+sum(wt.*wt);
    
end   

function [ww] = VasteGewichten(w,b)

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

end