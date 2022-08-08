   function showPlotAnnealing (output)
        
   
    figure('Units','normalized','Position',[0.05 0.5 0.4 0.4]);
    plot(100*output.sig,100*output.mu,'or','LineWidth',3);

    grid on;
    axis tight;

    xlabel('Tracking error (%)','FontSize',20);
    ylabel('Verwacht overrendement (%)','FontSize',20);
    set(gca,'FontSize',18);

               
        
    end

