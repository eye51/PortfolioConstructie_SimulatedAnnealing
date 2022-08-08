function yt = GetData(data,bjaar,ejaar)

jaar      = data(:,1);
ex        = (jaar>=bjaar) & (jaar<=ejaar);
yt        = data(ex,2:end);
yt(yt==0) = NaN;

%yt = CumReturn(yt,3,1,1);  %driejaars mutatie

end