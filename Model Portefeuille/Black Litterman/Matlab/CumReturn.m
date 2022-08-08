function CR = CumReturn(Rt,hor,freq,ext)

if nargin<3
    freq = 1;
end

if nargin<4
	ext = 0;
end

yt = Rt;
if min(min(yt))<-1
    yt = yt/100;
end

CR = exp(freq*movavg(log(1+yt),hor,ext))-1;

end