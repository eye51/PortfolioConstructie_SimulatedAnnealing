function [lpm] = Scenario_LPM(RetScen,lpm_orde,lpm_target)
    R   = max(lpm_target-RetScen,0);
    if lpm_orde>0
        R = R.^lpm_orde;
    else
        R = R>0;
    end
    lpm = mean(R);
	if lpm_orde>0
		lpm = lpm.^(1/lpm_orde);
	end
end