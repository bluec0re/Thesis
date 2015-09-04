function t = get_pyramid(I, params)
%Extract feature pyramid from variable I (which could be either an image,
%or already a feature pyramid)

if isnumeric(I)
  if (params.detect_add_flip == 1)
    I = flip_image(I);
  else    
    %take unadulterated "aka" un-flipped image
  end
  
  clear t
  t.size = size(I);

  t_ang = t;
  t_orig = t;
  %Compute pyramid
  [t.hog, t.scales] = esvm_pyramid(I, params);
%   [t_orig.hog, t_orig.scales] = esvm_pyramid_original(I, params);
%   [t_ang.hog, t_ang.scales] = esvm_pyramid_angela(I, params);
  
  t.padder = params.detect_pyramid_padding;
  for level = 1:length(t.hog)
    t.hog{level} = padarray(t.hog{level}, [t.padder t.padder 0], 0);
  end
  
  minsizes = cellfun(@(x)min([size(x,1) size(x,2)]), t.hog);
  t.hog = t.hog(minsizes >= t.padder*2);
  t.scales = t.scales(minsizes >= t.padder*2);  
else
  fprintf(1,'Already found features\n');
  
  if iscell(I)
    if params.detect_add_flip==1
      t = I{2};
    else
      t = I{1};
    end
  else
    t = I;
  end
end