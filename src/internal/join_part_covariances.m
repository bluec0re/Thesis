function neg_model = join_part_covariances(num_parts)
%JOIN_PART_COVARIANCES Joins multiple small files into one matrix
%
%   Syntax:     neg_model = join_part_covariances(num_parts)
%
%   Input:
%       num_parts - Number of files to join
%
%   Output:
%       neg_model - the negative model for whitened HoGs

filer = 'data/negative_models/covariance_wav.mat';

if ~exist(filer, 'file')

    Sq2 = 0;
    nC = 0;
    sum_inc = 0;

    for part_idx = 1:num_parts,

        filer_part = sprintf('data/negative_models/covariance_wav_part%d.mat', part_idx);
        part_data = load(filer_part);

        Sq2 = Sq2 + part_data.Sq2;
        nC = nC + part_data.nC;
        sum_inc = sum_inc + part_data.sum_inc;
    end

    neg_model.cov = (bsxfun(@minus,Sq2, sum_inc'*sum_inc/nC))/nC; %WORKS!!
    neg_model.mean = sum_inc/nC;
    neg_model.total_points = nC;

    save(filer, 'neg_model', '-v7.3');

else
   load(filer);
end
