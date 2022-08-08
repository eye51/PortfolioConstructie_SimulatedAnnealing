
function [X0,y0,Gamma0,val_obj] =CorMatHdm(G,W,rhs,tau,TOL1)
%%%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%          This code is for computing 
%%%%%%%% "the H-weighted nearest correlation matrix problem"
%%%%%%                          based on 
%%%%%%  Houduo Qi and  Defeng Sun, "An augmented Lagrangian dual approach
%%%%%%  for the H-weighted nearest correlation matrix problem",
%%%%%%  March 2008, 
%%%%%%  Department of Mathematics, National University of Singapore
%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% 
%                        for solving 
%%              min  0.5 ||W o ( X - G )||^2    %%%% "o" is the Hadamard product symbol
%%              s.t.  X_ii =1, i=1,2,..., n   
%%                    X >= tau*I (symmetric and positive semi-definite; tau can be zero)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% %%%%%%%%%%%%%%%%%%%%%%%
% G: the estimated potentially inconsistent correlation matrix (n by n)
% W: the weight matrix for G
% rhs: === ones(n,1)
% tau: the lower bound for the smallest eigevalue of X0 (can be zero)
% TOL1: stopping crierion for the KKT system: 1.0e-4 ~ 1.0e-6
% X0: the calibrated correlation matrix
% y0: the Lagrangian dual variable corresponding to the equation
% Gamma0: the Lagrangian dual variable corresponding to X>= tau*I
% val_obj: final objective function value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Last updated on March 5, 2008 %%%%%%%%%%%%%%%%%%%%%%%%%%%%


t0 =cputime;
[n,m] =size(G);
eye_n =eye(n);
%rhs =ones(n,1);  

W_ave =sum(sum(W))/n^2

W = W/W_ave; % so the average element of W is one
 

%% set parameters
max_lambda = 1e5; %1.0e5; % maximum penalty parameter
lambda =10 %0.5; % 1.0e2;   
lambda =min(lambda, max_lambda); %the initial penalty parameter
rho =1.4;%1.4;% 10;  % the ration to increase the penalty parameter
mu = 1.0e-12;        % parameter used in the line search (it can be other small positive number)

rho1=0.0; %rho1>=0 controls the regularized quadratic term (can be zero)

tol =   1.0e-1;   %1.0e-2   %tolerance for the CG method 1.0e-1 ~5.0e-3 (relative error)

%TOLRel1 =TOL1;
TOL2 = 5.0e-1*TOL1;     %tolerance of || DL ||=0, slightly smaller than the outside tolerance
 
TOLrel2 =1.0e-2;         %initial tolerance of || DL ||=0
 

maxit =  500;% 200;    % maximum step the CG method
maxit1 = 200;     % maximum steps for k:  maximal number of outer iterations
maxit2 = 50;      % maximum steps for j: maximal number of inner iterations 
maxit3 = 20;      % maximum steps for t:  maxima number of line searches
iterk  = 0;


G =(G+G')/2;  % make sure that G is symmetric
W = (W+W')/2; % make sure that W is symmetric



Gamma0 = zeros(n,n);
X0 = zeros(n,n);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initial data (X, y, Gamma): 
%%%%%%% We first solve the following problem to get an initial guess %%%%%%%%%%%%%% 
%%%%%%%%  min 0.5*<X-G, X-G>
%%%%%%%   s.t. X_ii =1, i=1,2,...,n
%%%%%%%        X>=0 (symmetric and positive semi-definite) %%%%%%%%%%%%%%%
%%%%%%%%
%%%%%%  based on the algorithm  in %%%%%
%%%%%%  ``A Quadratically Convergent Newton Method for %%%
%%%%%%    Computing the Nearest Correlation Matrix" %%%%%
%%%%%%%   By Houduo Qi and Defeng Sun  %%%%%%%%%%%%
%%%%%%%   SIAM J. Matrix Anal. Appl. 28 (2006)360--385.
%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 
%%%%%% The outputs are the optimal primal and dual solutions %%%%%%%%
 
disp('     ')
disp('Start the initial correlation test approximation')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[X0,y0] = CorNewton2(G,rhs,tau); % to solve the equal weighted problem (i.e., W_ij =1) to get an initial estimate 

disp('The initial correlation test approximation finished')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Gamma0 =  X0 - G - diag(y0);  %% The initially guessed optimal Lagrangian multiplier matrix
Gamma0 = (Gamma0 + Gamma0')/2;
gap = mytrace(X0-tau*eye_n,Gamma0);
eig_time =0;
pcg_time =0;

Gamma = W.*(X0-G); % a temporary matrix 
val_obj = mytrace(Gamma, Gamma)/2; % objective function value at the starting point
Gamma = W.*Gamma -diag(y0)-Gamma0; % the left hand side of the first equation in the KKT system

Total_err = mytrace(Gamma,Gamma);
Total_err = Total_err^0.5; %norm of the initial error 
Total_err0 = Total_err;



 fprintf('\n')
 fprintf('The initial correlation test approximation ========================================== %d \n', Total_err)
 
 if Total_err > TOL1
     fprintf('\n')
     fprintf('The initial correlation test is not good enough, continue !!!!!!!!!! %d \n');
     fprintf('\n')
     fprintf('\n')
    
     fprintf('The Augmented Lagrangian method is activated!!!!!!!!!! %d \n');
     fprintf('\n')
    
 
     k=0;
     count_LS=0; % count the number of linear systems to be solved

     eig_t0 =cputime;

  %%%%%%%%%%%%%%%%%%%%%%%%%%  
  % compute the eigen-decomposition of $(Gamma0 -lambda*(X0-tau*I)$ 
     Gamma = Gamma0 - lambda*(X0-tau*eye_n);

     Gamma = (Gamma + Gamma')/2;

     eig_t0 =cputime;

     [P,D] = eig(Gamma);
              eig_time =  eig_time + cputime -eig_t0;
     d = diag(D);
     P =real(P);
     d =real(d);
    
   
     
    [f0,Fx] = grad(X0,y0,G,W,rhs,Gamma0,lambda,tau,d,P,X0,rho1);  %%% the gradient of the augmented Lagrangian function
              
     b = -Fx;
     f_eval =1;

     while (k < maxit1)
         j=0;
         f_eval0 =0;
         Tol2_k =min(TOLrel2, 0.5*Total_err);
         Tol2_k = max(TOL2, Tol2_k);

         norm_Lag = mytrace(b,b);
         norm_Lag = norm_Lag^0.5;

         fprintf('AugLagNewton: Norm of the Gradient === %d \n', norm_Lag)

         norm_Lag = 1.0e10; %Must do at least one step

         while (norm_Lag > Tol2_k) & (j<maxit2)
             
             [Omega12,P1,P2] = omega_mat(P,d); % generate the Omeage matrix (the off-diagonal part only)
              pcg_t0 =cputime;
           
             [dx,flag,relres,iterk] = p_cg(b,tol,maxit,W,Omega12,P1,P2,lambda,rho1);
             %dx=b; %corresponds to the steepest descent direction method
             
             pcg_time = pcg_time + cputime - pcg_t0;

             j=j+1; % the number of linear systems solved at this level
             count_LS = count_LS + 1; % the total number of linear system solved
             fprintf('AugLagNewton: Number of CG Iterations ===%d \n', iterk)
             
             tmp =  mu*mytrace(Fx,dx);

             alpha =1.0;
             Ok = false;

             t=0;
          
             while (Ok==false) & (t<maxit3)
                % update X
                
                 delta_x = alpha*dx;
                 
                 X = X0 + delta_x;
                 X = (X+X')/2;
                 Gamma = Gamma0 -lambda*(X -tau*eye_n);
                 Gamma = (Gamma +Gamma')/2;

                 eig_t0 =cputime;
                 [P,D] = eig(Gamma);
                 eig_time =  eig_time + cputime -eig_t0;
                 d = diag(D);
                 P = real(P);
                 d =real(d);
                 idx =find(d>0); % the index of positive eigenvalues
              

                 [f,Fx] =  grad(X,y0,G,W,rhs,Gamma0,lambda,tau,d,P,X0,rho1);     
                % fprintf('AugLagNewton: the Augmented Lagrangian function value === %d \n', f)
                 
                 f_eval0 = f_eval0 +1;

                 tmp1 =alpha*tmp;

                 dlag = f - f0 -tmp1;

                 if  ( dlag <1e-6) % dlag <= 0 (theoretically)
                     Ok = true;
                 else
                     alpha = alpha/2;
                 end
                 t=t+1;
             end  % This is the end of line search for one level Augmented Lagrangian function minimization
             f0 = f;
             % compute the first derivative of Lagrangian
             
             b = -Fx;
             norm_Lag = mytrace(b,b);
             norm_Lag = norm_Lag^0.5;
             %fprintf('AugLagNewton: Number of Line Search Steps =========== %d \n', t)
             %fprintf('AugLagNewton: Steplength ================= %d \n', alpha)
              fprintf('AugLagNewton: Norm of the Gradient === %d \n', norm_Lag)

             
             X0 = X;
             y = y0+lambda*(rhs-diag(X));


         end   %%%% $j$ while loop:::This is the end of one level Augmented Lagrangian function minimization

         f_eval = f_eval + f_eval0;


         fprintf('AugLagNewton: Number of  Steps at this level ================== %d \n', j)
         time_used = cputime -t0;
         fprintf('============: cputime used=============================== %d \n', time_used);
         fprintf('.... End of Another Level Aug Lagrangian Optimization  :):):):)...:):)...');
         fprintf('\n');


         k=k+1;
         %%% Update the dual variable and the penalty parameter %%%
         %%%%% Checking if convergence has reached %%%%%%
         
         Gamma = P';
         for i=1:n
             Gamma(i,:) =max(0,d(i))*Gamma(i,:);
         end
         Gamma = P*Gamma;  %  Gamma = Gamma0- lambda*(X-tau*I)
         Gamma = (Gamma + Gamma')/2;

        
         
         %Gamma = Gamma0 - lambda*Constraint_fuction(x0,m,C);
         Err_est1 = mytrace((Gamma0-Gamma), (Gamma0-Gamma));
         Err_est1 = Err_est1^0.5/(min(100,lambda^0.5));  % the test on the complementary condition
         
         Err_est2 = (rhs-diag(X))'*(rhs-diag(X));
         Err_est =max(Err_est2^0.5,Err_est1); 
         
         Total_err = max(norm_Lag,Err_est);
       


         fprintf('\n');
         fprintf('AugLagNewton: Total Absolute Error ======================================== %d \n', Total_err);

         if Total_err <= TOL1
             y0=y;
 
             X0 = X0 + (Gamma-Gamma0)/lambda;
             X0 = (X0 +X0')/2;
             Gamma0 = Gamma;
           
             
 
             gap = mytrace(X0-tau*eye_n,Gamma0);
             
             
             
             break; % successful already
         else

             klambda =0;

             if (lambda < max_lambda)
                 
                 if Total_err >(0.25)*Total_err0  %update lambda only if convergence is not fast

                     lambda = rho*lambda;  %new lambda

                     lambda= min(lambda, max_lambda);
                     klambda=1;
                 else
                     klambda=0;
                 end
             end
             % fprintf('AugLagNewton: The present penalty parameter ======================= %d \n',  lambda)
             Total_err0=Total_err;
             
             if klambda == 1  %% Only when lambda is updated we need recompute Gamma

                 Gamma = Gamma0 -lambda*(X -tau*eye_n);
                 Gamma = (Gamma + Gamma')/2;
                 
                 eig_t0 =cputime; 
                 [P,D] = eig(Gamma);
                 
                 eig_time =  eig_time + cputime -eig_t0;
                 eig_t1 = cputime;
                 eig_time  = eig_time + (eig_t1- eig_t0);
                 
                 d = diag(D);
                 P =real(P);
                 d =real(d);
                 
                 Gamma0 = P';
                 
                 for i=1:n
                     Gamma0(i,:) =max(0,d(i))*Gamma0(i,:);
                 end
                 Gamma0 = P*Gamma0; %  new Gamma
                 Gamma0 = (Gamma0 + Gamma0')/2;
                 
                 y0 = y0 +lambda*(rhs-diag(X)); % new y

                 f_eval =f_eval + 1;
                 
             else
                 Gamma0 = Gamma;
                 y0 = y;
             end
             
             Gamma = Gamma0 - lambda*(X0-tau*eye_n);

             Gamma = (Gamma + Gamma')/2;

             eig_t0 =cputime;

             [P,D] = eig(Gamma);
             eig_time =  eig_time + cputime -eig_t0;
             d = diag(D);
             P =real(P);
             d =real(d);
             
             [f0,Fx] =  grad(X0,y0,G,W,rhs,Gamma0,lambda,tau,d,P,X0,rho1); 
             b = -Fx;
            
         end % Total_err loop

     end % k while loop

     fprintf('\n');

     fprintf('\n');
     fprintf('Number of  Aug Lagrangian Optimization Levels solved===%d \n', k);
     fprintf('Number of  linear system solved ===%d \n',  count_LS);
     fprintf('Number of  function value calculations ===%d \n',  f_eval);
     fprintf('AugLagNewton: Error =========================== %d \n', Total_err);


 else
     fprintf('The ininial correlation test succeeds already: stop!!!!!!!!!! %d \n');
 end %%% corresponds to the first "if"


 
Feas_err = (rhs-diag(X0))'*(rhs-diag(X0));
Feas_err =Feas_err^0.5;
RelFeas_err =Feas_err/(1+ norm(rhs)^0.5);
Gamma = W.*(X0-G);
val_obj = mytrace(Gamma, Gamma)/2;
val_obj = W_ave^2*val_obj; % scale back to the original function value

Gamma = W.*Gamma - diag(y0) - Gamma0; % the residue of the first equation in the KKT system
KKT_err = mytrace(Gamma,Gamma);
KKT_err = KKT_err^0.5; % the norm of the residue of first KKT equation 
W2G = (W.*W);
W2G = W2G.*G;
scale_kkt = mytrace(W2G, W2G);
scale_kkt = scale_kkt^0.5;
RelKKT_err= KKT_err/(1+scale_kkt); %the norm of the relative residue of first KKT equation 
gap = gap*W_ave^2;
Relgap =gap/(1+abs(val_obj)); % relative gap

%%%%%%%% The Lagrangian multipliers to the original problem %%%%%%
y0 =W_ave^2*y0;
Gamma0 = W_ave^2*Gamma0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


time_used= cputime-t0;
fprintf('\n');
fprintf('AugLagNewton: Final objective function value==== %d \n', val_obj);
%fprintf('AugLagNewton: the least eigenvalue of the correlation matrix = %d \n', lambda_min);
fprintf('============: the norm of the residue of first KKT equation   = %d \n', KKT_err);
fprintf('============: the norm of the relative residue of first KKT equation   ========== %d \n', RelKKT_err);
fprintf('============: the norm of feasibility ======= ================= %d \n', Feas_err);
fprintf('============: the norm of relative feasibility ======= ========================== %d \n', RelFeas_err);
fprintf('============: the inner product between (X-tau*I) and its multiplier  = %d \n', abs(gap));
fprintf('============: the relative inner product between (X-tau*I) and its multiplier  ===%d \n', abs(Relgap));

fprintf('============: Eig decomposition time used   ================ %d \n', eig_time);
fprintf('AugLagNewton: Conjugate Gradient time used  ================ %d \n', pcg_time);

fprintf('============: cputime used======================================================== %d \n', time_used);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                       %%
%%% end of the main program %%
%%%                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%% trace function %%%
function val = mytrace(A,B);

if (nargin == 1)
   val = sum(diag(A));
elseif (nargin == 2)
   val = sum(sum(A.*B));
end
return
%%% end of trace funcion %%%%%%


%%%%%%
%%%%%% To generate f(x) and  F(x) %%%%%%%
%%%%%%%
function  [f,Fx] = grad(X,y,G,W,rhs,Gamma0,lambda,tau,d,P,X0,rho1);

[n,m] =size(X);

f=0.0;

Fx = zeros(n,n);
hy = zeros(n,1);
hy = rhs - diag(X);

%dp=max(0,d);
%H =diag(dp); %% H =P *diag(dp)* P^T
%  H =H*P'; %%% Assign H*P' to H
 H=P';
 i=1;
 while (i<=n)
     H(i,:)=max(d(i),0)*H(i,:);
     i=i+1;
 end
 
 H = P*H; 
 
 
 Fx = W.*(X-G);
 f = f + 0.5*mytrace(Fx,Fx);
 f = f+y'*hy +(hy'*hy)*lambda/2;
 f = f+(mytrace(H,H)-mytrace(Gamma0,Gamma0))/(2*lambda);
 f = f + mytrace(X-X0,X-X0)*rho1/(2*lambda);
 
 Fx = W.*Fx;
 Fx = Fx -diag(y+lambda*hy)-H;
 Fx = Fx + (X-X0)*(rho1/lambda);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% end of grad.m %%%%%%



%%%%%%%%%%%%%%        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% To generate the first -order difference of $\Pi_{S^n_+}( )$ at  d
%%%%%%%
function [Omega12,P1,P2] = omega_mat(P,d)

idx.idp = find(d>0);
idx.idm = find(d<=0);
n =length(d);
r = length(idx.idp);

if isempty(idx.idp)
    Omega12 = [];
elseif (r == n)
    Omega12 = ones(n,n);
else
    s = n-r;
    if idx.idp(r)< idx.idm(1) % to know largest eigenvalue comes first or not
    dp = d(1:r);
    dn = d(r+1:n); 
    else
    dp = d(s+1:n);
    dn = d(1:s);
    end
    Omega12 = (dp*ones(1,s))./(abs(dp)*ones(1,s) + ones(r,1)*abs(dn'));
end

%%***** perturbation *****
%Omega12 = max(1e-15,Omega12);

if ~isempty(idx.idp)
    P1 = P(:,idx.idp); P2 = P(:,setdiff([1:n],idx.idp));
else
    P1 = []; P2 = P;
end


return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% end of omega_mat.m %%%%%%%%%%

%%%%%% PCG method %%%%%%%
%%%%%%% This is exactly the algorithm by  Hestenes and Stiefel (1952)
%%%%%An iterative method to solve A(x) =b  
%%%%%The symmetric positive definite matrix M is a
%%%%%%%%% preconditioner for A. 
%%%%%%  See Pages 527 and 534 of Golub and va Loan (1996)

function [p,flag,relres,iterk] = p_cg(b,tol,maxit,W,Omega12,P1,P2,lambda,rho1);

% Initializations
[n,m] = size(b); % the dimension of the unknown 

%W_bar = W.*W;

%W_bar = W_bar + lambda*eye(n);
% W_bar =ones(n,n);
% W_bar = max(W_bar,1.e-4);
% 
% 
% W_bar = 1./W_bar;
% b = W_bar.*b;

r=b; %We take the initial guess x0=0 to save time in calculating A(x0) 
n2b =mytrace(b,b);  
n2b =n2b^0.5;   % norm of b

tolb = tol * n2b;  % relative tolerance 

p = zeros(n,n);
diag_d = zeros(n,1);

flag=1;
iterk =0;
relres=1000; %%% To give a big value on relres
% Precondition 
z =r;  %%%%% z = M\r; here M =diag(ww); if M is not the identity matrix 

rz1 = mytrace(r,z); 

rz2 = 1; 

dX = z;
% CG iteration
for k = 1:maxit
   if k > 1
       beta = rz1/rz2;
       dX = z + beta*dX;
   end
   
   diag_d =diag(dX);
   
   w= (W.*W).*dX +lambda*diag(diag_d)+lambda*Jacobian_mat(dX,Omega12,P1,P2)+ (rho1/lambda)*dX; 
   w = w + min(1.0e-2, 1.0e1*n2b)*dX; %w = A(d); Perturbed
   % w= W_bar.*(W.*(W.*d)) + lambda*(W_bar.*diag(diag_d))+ lambda*(W_bar.*Jacobian_mat(d,Omega,P)); %w = [W_bar.*A(d)]; 
  
   denom = mytrace(dX,w);
   iterk =k;
   norm_z = mytrace(z,z);
   norm_z = norm_z^0.5;
   relres =norm_z/n2b;              %relative residue =norm(z) / norm(b)
   if denom <= 0 
       norm_d = mystrace(dX,dX);
       norm_d =norm_d^0.5;
       p = dX/norm_d; % d is not a descent direction
       break % exit
   else
       alpha = rz1/denom;
       p = p + alpha*dX;
       r = r - alpha*w;
   end
   z = r; %  z = M\r if M is not the identity matrix;
   
   norm_z = mytrace(z,z);
   norm_z = norm_z^0.5;
   if norm_z <= tolb % Exit if Hp=b solved within the relative tolerance
       iterk =k;
       relres =norm_z/n2b;          %relative residue =norm(z) / norm(b)
       flag =0;
       break
   end
   rz2 = rz1;
   rz1 = mytrace(r,z);
end

return
%%% end of pre_cg.m%%%%%%%%%%%

%%%%%% To generate the Jacobain product with y: F'(x)(X) (generalized  Jacobian) %%%%%%%
function JFX=Jacobian_mat(X,Omega12,P1,P2)

n = length(X);
JFX = zeros(n);
 

if isempty(P2)
    JFX = X;
else
    if ~isempty(P1)
        tmp0 = P1'*X;
        tmp1 = (tmp0*P1)*P1';

        tmp2 = Omega12.*(tmp0*P2);
        tmp2 = P1*tmp2*P2';

        JFX = P1*tmp1 + tmp2 + tmp2';
        JFX = (JFX+JFX')/2; %check symmetry
    end
end
 
return
%end of Jacobian_mat.m%%%








