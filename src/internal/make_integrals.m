function [ integrals ] = make_integrals( params, codebooks )
%MAKE_INTEGRALS Summary of this function goes here
%   Detailed explanation goes here

    integrals = cell([1 length(codebooks)]);
    
    for ci=1:length(codebooks)
        codebook = codebooks{ci};
        
        integral.curid = codebook.curid;
                
        integral.I = cumsum(codebook.X, 3);
        integral.I = cumsum(integral.I, 4);
        integrals{ci} = integral;
    end
end

