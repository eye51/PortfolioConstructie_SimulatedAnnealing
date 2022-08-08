%%%%%%%%% This code is designed to solve %%%%%%%%%%%%%
%%%%%%%%  min 0.5*<X-G, X-G>
%%%%%%%   s.t. X_ii =1, i=1,2,...,n
%%%%%%%        X>=tau*I (symmetric and positive semi-definite) %%%%%%%%%%%%%%%
%%%%%%%%
%%%%%%  based on the algorithm  in %%%%%
%%%%%%  ``A Quadratically Convergent Newton Method for %%%
%%%%%%    Computing the Nearest Correlation Matrix %%%%%
%%%%%%%   By Houduo Qi and Defeng Sun  %%%%%%%%%%%%
%%%%%%%   SIAM J. Matrix Anal. Appl. 28 (2006) 360--385.
%%%%%%%  
%%%%%% Last modified date:  March 18, 2008  %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% The  input argument is the given symmetric G   %%%%%%%%
%%%%%% The outputs are the optimal primal and dual solutions %%%%%%%%
%%%%%%% Diagonal Preconditioner is added         %%%%%%
%%%%%%% Send your comments and suggestions to    %%%%%%
%%%%%%% hdqi@soton.ac.uk  or matsundf@nus.edu.sg %%%%%%
%%%%%                          %%%%%%%%%%%%%%%
%%%%% Warning: Accuracy may not be guaranteed!!!!! %%%%%%%%

function [X,y] = CorNewton2(G,b,tau)
disp(' ---Newton method starts--- ')
t0=cputime;
[n,m] =size(G);

global  b0

G =(G+G')/2; % make G symmetric
% b0 =ones(n,1);
b0=b;

if nargin==3
   G  =  G-tau*eye(n); % reset G
   b0 = b0-tau*ones(n,1); % reset b0   
end


Res_b=zeros(300,1);



y=zeros(n,1);       %Initial point
%y=b0-diag(G);              

Fy=zeros(n,1);

k=0;
f_eval =0;

Iter_Whole=200;
Iter_inner =20; % Maximum number of Line Search in Newton method
maxit =200; %Maximum number of iterations in PCG
iterk =0;
Inner =0;
tol =1.0e-3; %relative accuracy for CGs

error_tol=1.0e-6; % termination tolerance
sigma_1=1.0e-4; %tolerance in the line search of the Newton method

x0=y;

 


prec_time = 0;
pcg_time = 0;
c = ones(n,1);
%M = diag(c); % Preconditioner to be updated

d =zeros(n,1);

  val_G = sum(sum(G.*G))/2;

 C = G + diag(y);
 C = (C + C')/2;
 
 [P,D]=eig(C);
 lambda=diag(D);
 P = real(P);
 lambda = real(lambda);
 
 [f0,Fy] = gradient(y,lambda,P,b0,n);
 f=f0;
 f_eval =f_eval + 1;
 b =b0-Fy;
 norm_b=norm(b);

 Initial_f = val_G-f0;
 fprintf('Newton: Initial Dual Objective Function value==== %d \n', Initial_f)
 fprintf('Newton: Norm of Gradient %d \n',norm_b)
 
 Omega = omega_mat(P,lambda,n);
 x0=y;

 while (norm_b>error_tol & k< Iter_Whole)

  cg_time0 =cputime;
     c = precond_matrix(Omega,P,n); % comment this line for  no preconditioning
  prec_time = prec_time + cputime -cg_time0;
  
 pcg_time0 =cputime;
 [d,flag,relres,iterk]=pre_cg(b,tol,maxit,c,Omega,P,n);
 pcg_time = pcg_time + cputime -pcg_time0;
 %d =b0-Fy; gradient direction
 fprintf('Newton: Number of CG Iterations %d \n', iterk)
  
  if (flag~=0); % if CG is unsuccessful, use the negative gradient direction
     % d =b0-Fy;
     disp('..... Not a full Newton step......')
  end
 slope =(Fy-b0)'*d; %%% nabla f d
 

    y = x0+d; %temporary x0+d 
    
     C = G + diag(y);
     C = (C + C')/2;
     [P,D] = eig(C); % Eig-decomposition: C =P*D*P^T

     lambda=diag(D);
     P =real(P);
     lambda = real(lambda);
 
     [f,Fy] = gradient(y,lambda,P,b0,n);

     k_inner=0;
     while(k_inner <=Iter_inner & f> f0 + sigma_1*0.5^k_inner*slope + 1.0e-6)
         k_inner=k_inner+1;
         y = x0 + 0.5^k_inner*d; % backtracking   
         C = G + diag(y);
         C = (C + C')/2;
         [P,D] = eig(C); % Eig-decomposition: C =P*D*P^T
         lambda = diag(D);
         P = real(P);
         lambda = real(lambda);
         
         [f,Fy] = gradient(y,lambda,P,b0,n);
      end % lop for while
      f_eval =f_eval+k_inner+1;
      x0 = y;
      f0 = f;
      
     k=k+1;
     b=b0-Fy;
     norm_b=norm(b);
     fprintf('Newton: Norm of Gradient %d \n',norm_b)

     Res_b(k)=norm_b;
    
     Omega = omega_mat(P,lambda,n);

 end %end loop for while i=1;

 P = real(P);
 C = P';
i=1;
while (i<n+1)
    C(i,:) = max(0,lambda(i))*C(i,:);
    i=i+1;
end
X = P*C; % Optimal solution X* 


 X = (X+X')/2;
 Final_f = val_G-f;
 val_obj = sum(sum((X-G).*(X-G)))/2;
 X = X+tau*eye(n); 
 time_used= cputime-t0;
 fprintf('\n')

%fprintf('Newton: Norm of Gradient %d \n',norm_b)
fprintf('Newton: Number of Iterations == %d \n', k)
fprintf('Newton: Number of Function Evaluations == %d \n', f_eval)
fprintf('Newton: Final Dual Objective Function value ========== %d \n',Final_f)
fprintf('Newton: Final Original Objective Function value ====== %d \n', val_obj)

fprintf('Newton: cputime for computing preconditioners == %d \n', prec_time)
fprintf('Newton: cputime for linear systems solving (cgs time) ====%d \n', pcg_time)
fprintf('Newton: cputime used for equal weight calibration ==== ============%d \n',time_used)



%%% end of the main program



%%%%%%
%%%%%% To generate F(y) %%%%%%%
%%%%%%%

function [f,Fy]= gradient(y,lambda,P,b0,n)
%global P omega
%[n,n]=size(P);
f=0.0;
Fy =zeros(n,1);
%Im =find(lambda<0);
%Ip =find(lamba>=0);
%lambdap=max(0,lambda);
%H =diag(lambdap); %% H =P^T* diag(x) *P
%  H =H*P'; %%% Assign H*P' to H
 H=P';
 i=1;
 while (i<=n)
     H(i,:)=max(lambda(i),0)*H(i,:);
     i=i+1;
 end
 i=1;
 while (i<=n)
       Fy(i)=P(i,:)*H(:,i);
 i=i+1;     
 end
 i=1;
 while (i<=n)
     f =f+(max(lambda(i),0))^2;
     i=i+1;
 end
 
f =0.5*f -b0'*y;

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% end of gradient.m %%%%%%

%%%%%%%%%%%%%%        %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% To generate the first -order difference of lambda
%%%%%%%

%%%%%%%%%%%%%%        %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% To generate the first -order difference of d
%%%%%%%
function Omega = omega_mat(P,lambda,n)
%We compute omega only for 1<=|idx|<=n-1
idx.idp = find(lambda>0);
idx.idm = setdiff([1:n],idx.idp);
n =length(lambda);
r = length(idx.idp);
Omega = zeros(n);

if ~isempty(idx.idp)
    if (r == n)
        Omega = ones(n,n);
    else
        s = n-r;
        if idx.idp(1)< idx.idm(1)
            dp = lambda(1:r);
            dn = lambda(r+1:n);
            Omega12 = (dp*ones(1,s))./(abs(dp)*ones(1,s) + ones(r,1)*abs(dn'));
            Omega12 = max(1e-15,Omega12);
            Omega =[ones(r) Omega12;Omega12' zeros(s)];
        else
            dp = lambda(s+1:n);
            dn = lambda(1:s);
            Omega12 = (dp*ones(1,s))./(abs(dp)*ones(1,s) + ones(r,1)*abs(dn'));
            Omega12 = max(1e-15,Omega12);
            Omega =[zeros(s) Omega12';Omega12 ones(r)];
        end

    end
end

    %%***** perturbation *****
    return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% end of omega_mat.m %%%%%%%%%%

%%%%%% PCG method %%%%%%%
%%%%%%% This is exactly the algorithm by  Hestenes and Stiefel (1952)
%%%%%An iterative method to solve A(x) =b  
%%%%%The symmetric positive definite matrix M is a
%%%%%%%%% preconditioner for A. 
%%%%%%  See Pages 527 and 534 of Golub and va Loan (1996)

function [p,flag,relres,iterk] = pre_cg(b,tol,maxit,c,Omega,P,n);
% Initializations
r = b;  %We take the initial guess x0=0 to save time in calculating A(x0) 
n2b =norm(b);    % norm of b
tolb = tol * n2b;  % relative tolerance 
p = zeros(n,1);
flag=1;
iterk =0;
relres=1000; %%% To give a big value on relres
% Precondition 
z =r./c;  %%%%% z = M\r; here M =diag(c); if M is not the identity matrix 
rz1 = r'*z; 
rz2 = 1; 
d = z;
% CG iteration
for k = 1:maxit
   if k > 1
       beta = rz1/rz2;
       d = z + beta*d;
   end
   %w= Jacobian_matrix(d,Omega,P,n); %w = A(d); 
   w = Jacobian_matrix(d,Omega,P,n); % W =A(d)
   denom = d'*w;
   iterk =k;
   relres = norm(r)/n2b;              %relative residue = norm(r) / norm(b)
   if denom <= 0 
       sssss=0
       p = d/norm(d); % d is not a descent direction
       break % exit
   else
       alpha = rz1/denom;
       p = p + alpha*d;
       r = r - alpha*w;
   end
   z = r./c; %  z = M\r; here M =diag(c); if M is not the identity matrix ;
   if norm(r) <= tolb % Exit if Hp=b solved within the relative tolerance
       iterk =k;
       relres = norm(r)/n2b;          %relative residue =norm(r) / norm(b)
       flag =0;
       break
   end
   rz2 = rz1;
   rz1 = r'*z;
end

return

%%%%%%%% %%%%%%%%%%%%%%%
%%% end of pre_cg.m%%%%%%%%%%%


%%%%%% To generate the Jacobain product with x: F'(y)(x) %%%%%%%
%%%%%%%

function Ax = Jacobian_matrix(x,Omega,P,n)

Ax =zeros(n,1);
%Im =find(lambda<0);
%Ip =find(lamba>=0);
%H =diag(x);
H =P;
i=1;
while (i<=n)
    H(i,:) = x(i)*H(i,:); % H=diag(x)*P
    i=i+1;
end   
H =P'*H; %% H =P^T* diag(x) *P
H = Omega.*H; %% H =[Omega o P^T* diag(x) *P]

 H =H*P'; %%% Assign H*P' to H= [Omega o (P^T*diag(x)*P)]*P^T
 i=1;
 while (i<=n)
       Ax(i)=P(i,:)*H(:,i);
       Ax(i) = Ax(i) + 1.0e-10*x(i); % add a small perturbation
       i=i+1;

 end
 
 return
 
%%%%%%%%%%%%%%%
%end of Jacobian_matrix.m%%%

%%%%%% To generate the diagonal preconditioner%%%%%%%
%%%%%%%

function c = precond_matrix(Omega,P,n)


c = ones(n,1);
H = P';

H = H.*H;
Omega = Omega*H;
H = H';
 for i=1:n
   c(i) = H(i,:)*Omega(:,i);
       if c(i) < 1.0e-8
         c(i) =1.0e-8;
       end
 end
return

 
%%%%%%%%%%%%%%%
%end of precond_matrix.m%%%

%



