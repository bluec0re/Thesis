function param = sigmoid_fit(data)

BINS = 100;

t1=data;

%     fprintf('Calibration seed %d/%d \n',c,length(seed_numbers));
%     idx=find(t(:,1)==i);
%     t1=t(idx,2);

%         figure(1)
%         hist(t1,50);

    [n, xout]=hist(t1,BINS);
    binwidth=xout(2)-xout(1);
    minx=floor(xout(1)-binwidth/2);
    maxx=ceil(xout(end)+binwidth/2);

    %     percent=0.01;
    %     sortval=sort(t1(:));
    %     %sortval=sortval(sortval>10);
    % %quantile=sortval(end-ceil(sum(maghist(2:end))*percent):end);
    %     quantile=sortval(end-ceil(sum(n)*percent):end);
    %     t2=quantile;
    %     [n2, xout2]=hist(t2,50);
    %     binwidth2=xout2(2)-xout2(1);
    %     minx2=floor(xout2(1)-binwidth2/2);
    %     maxx2=ceil(xout2(end)+binwidth2/2);

    %p=mle(t1,'pdf',@shiftedlogipdf,'start',[ mean(t1) std(t1) 0]);
    p=mle(t1,'distribution','logistic');
    %y= shiftedlogipdf([minx:maxx], p(1), p(2), p(3));

    % figure plot probability distribution function
    %y1= shiftedlogipdf([xout], p(1), p(2), p(3));
    y1=pdf('logistic',xout,p(1),p(2));
%         figure(2)
%         plot(xout,y1./max(y1)*max(n));
%         hold on
%         plot(xout,n./max(n)*max(n),'r')
%         hold off

    % plot cumulative distribution function
    %cdf=cumsum(y);
    %idx = round(linspace(1,length(cdf),30));
    %cdf=shiftedlogicdf([xout], p(1), p(2), p(3));
    cdf1=cdf('logistic',xout,p(1),p(2));
%         figure(3);plot(xout,cdf1);hold on;plot(xout,cumsum(n)./sum(n),'r')
%         hold off
%     pause



param = p;