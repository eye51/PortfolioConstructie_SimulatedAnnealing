function Ra = AddScenariosDerivatives(R,derpar)

[T,K] = size(R);
Ra    = R;

for i=1:max(size(derpar.strike))    
    P1        = (1+R(:,2+derpar.onder(i)))-derpar.strike(i);
    P1        = max(derpar.type(i)*P1,0);
    Ra(:,K+i) = P1./derpar.P0(i)-1; 
end

end