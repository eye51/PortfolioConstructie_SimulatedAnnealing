function [M_, S_]=Prior2Posterior(M,Q,M_Q,S,G,S_G)
%
% ref: Fully Flexible views: theory and practice, working paper Sept-2008
%       
%


M_=M+S*Q'*inv(Q*S*Q')*(M_Q-Q*M);                                % (21) pg. 7 
S_=S+(S*G')*( inv(G*S*G')*S_G*inv(G*S*G') -inv(G*S*G') )*(G*S);
