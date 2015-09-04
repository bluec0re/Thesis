function neg_model = get_full_neg_model()

%old
%neg_model = join_part_covariances(5);
load_ex('data/negative_models/covariance_wav.mat');
neg_model.cov = neg_model.cov(6*6*31+1:end,6*6*31+1:end);
neg_model.mean(1:6*6*31) = [];
size_ex = [12 12];
neg_model.idx_hog = 1:prod([size_ex 31]);  
cov_hog = neg_model.cov(neg_model.idx_hog,neg_model.idx_hog);
diag_idx = sub2ind(size(cov_hog), 1:size(cov_hog,1), 1:size(cov_hog,1));
cov_hog(diag_idx) =  cov_hog(diag_idx) + 0.01;       

neg_model.cov_hog = cov_hog;
neg_model.invcov_hog = inv(cov_hog);
neg_model.cov = [];



% % originally from Jose
% neg_model = join_part_covariances(5);
% neg_model.cov = neg_model.cov(6*6*31+1:end,6*6*31+1:end);
% neg_model.mean(1:6*6*31) = [];
% num_dims_hog = 31;
% num_dims_inv = 16;
% num_pixels_inv = 16;
% size_ex = [12 12];
% neg_model.idx_hog = 1:prod([size_ex 31]);  
% num_hog_dims = 12*12*31;
% num_wav_dims = 12*12*num_pixels_inv;
% neg_model.idx_wavA = num_hog_dims+1:num_hog_dims+prod([12 12])*num_pixels_inv;
% neg_model.idx_wavH = num_hog_dims+num_wav_dims+1:num_hog_dims+num_wav_dims+prod([12 12])*num_pixels_inv;
% neg_model.idx_wavV = num_hog_dims+2*num_wav_dims+1:num_hog_dims+2*num_wav_dims+prod([12 12])*num_pixels_inv;
% neg_model.cov_hog_wavA = neg_model.cov(neg_model.idx_wavA,neg_model.idx_hog);
% neg_model.cov_hog_wavH = neg_model.cov(neg_model.idx_wavH,neg_model.idx_hog);
% neg_model.cov_hog_wavV = neg_model.cov(neg_model.idx_wavV,neg_model.idx_hog);
% cov_hog = neg_model.cov(neg_model.idx_hog,neg_model.idx_hog);
% cov_hogwav = neg_model.cov([neg_model.idx_hog neg_model.idx_wavA],[neg_model.idx_hog neg_model.idx_wavA]);
% diag_idx = sub2ind(size(cov_hog), 1:size(cov_hog,1), 1:size(cov_hog,1));
% cov_hog(diag_idx) =  cov_hog(diag_idx) + 0.01;    
% 
% diag_idx = sub2ind(size(cov_hogwav), 1:size(cov_hogwav,1), 1:size(cov_hogwav,1));
% cov_hogwav(diag_idx) =  cov_hogwav(diag_idx) + 0.01;    
% 
% neg_model.cov_hog = cov_hog;
% neg_model.invcov_hog = inv(cov_hog);
% neg_model.invcov_hogwav = inv(cov_hogwav);
% neg_model.wavA = neg_model.cov_hog_wavA * neg_model.invcov_hog;
% neg_model.wavH = neg_model.cov_hog_wavH * neg_model.invcov_hog;
% neg_model.wavV = neg_model.cov_hog_wavV * neg_model.invcov_hog;

end

