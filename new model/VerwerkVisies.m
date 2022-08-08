N  = size(beta,1);
ns = size(beta,2);

for i=1:ns
    m_view(:,i) = m_eq+beta*(gewicht.*schokken(i,:))';    
end

