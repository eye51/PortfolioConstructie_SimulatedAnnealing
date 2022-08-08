function se = std_alt(e)
    m = mean(e); 
    se = sqrt(mean(e.*e)-m.*m); 
end