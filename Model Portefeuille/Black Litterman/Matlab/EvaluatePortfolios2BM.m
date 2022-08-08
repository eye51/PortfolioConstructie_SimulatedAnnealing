function [output] = EvaluatePortfolios2BM(wt,pars,mpn,mpr,lpm_par)

% PURPOSE: 	Evaluate asset mixes in one or more scenarios, in terms of mu and sigma
%			(absolute, wrt nominal liabilities and wrt real liabilities)
%---------------------------------------------------
% USAGE: output = EvaluatePortfolios(wt,pars)
% where:	wt: NxM matrix with portfolio weights (columnwise)
%			pars is a structure with
%				meanmat: NxK matrix with mean vectors (columnwise)
%				covmat:  NxNxK array with covariance matrices 
%				probs:	 Kx1 vector with probabilities per regime
%---------------------------------------------------
% RETURNS: 
%	output is a structure with
%			mu: 3xMxK matrix with expected returns. The 3 rows correspond to
%				1. absolute, 2. nominal and 3. real
%			te: 3xMxK matrix with tracking errors. The 3 rows correspond to
%				1. absolute, 2. nominal and 3. real
% --------------------------------------------------
% NOTES:	It is assumed that the first row of the inputs corresponds to the nominal
%			matching portfolio and that the second row corresponds to the real
%			matching portfolio. 
% --------------------------------------------------
% SEE ALSO: ...
%---------------------------------------------------
% REFERENCES:	Buckley, Saunders and Seco (2008), "Portfolio optimization
%					when asset returns have the Gaussian mixture distribution",
%					European Journal of Operational Research, 185, 1434-1461.
%---------------------------------------------------
% Written on September 22, 2009 by:
% Henk Hoek
% henk.hoek@mn-services.nl
%--------------------------------------------------

K = size(pars.probs,1); 
N = size(pars.meanmat,1);

hulp = pars;

%Calculate mu and sigma per scenario
for i=1:K
    hulp.probs           = pars.probs(i,:)';
    %[mua,cova]           = Mixture_Moments(hulp);
    [mua,sig1,sig2]      = AddMatchPortMix(hulp,mpn,mpr);
    param                = AddMatchPort(hulp,mpn,mpr);
    output.mu(:,i)       = mua'*wt;
    output.te1(:,i)      = sqrt(diag(wt'*sig1'*wt))';
	output.te2(:,i)      = sqrt(diag(wt'*sig2'*wt))';
    output.lpm(:,i)      = LPM_Utility(wt,param,lpm_par);
    output.totaal(:,i,:) = [output.mu(:,i) output.te1(:,i) output.te2(:,i) output.lpm(:,i)]';
end

end

function [U_lpm] = LPM_Utility(wts,pars,lpm_pars)    
	meanmat = pars.mu;
	sigmat  = pars.sig1;
	probs   = pars.probs;

    %Calculate mu and sigma per regime
    for j=1:size(meanmat,2)
        mu(:,j)    = wts'*meanmat(:,j);
        sig(:,j) = sqrt(sum(wts'*sigmat(:,:,j).*wts',2))';               
    end

    %Calculate utility
    U_lpm = LowerPartialMoments(lpm_pars.order,lpm_pars.target,mu,sig,probs);    
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
    lpm = lpm*probs;                   %Weight with regime probability
	if orde==2
		lpm = lpm.^(1/orde);
	end
    lpm = lpm';
end