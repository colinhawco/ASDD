%%
%%%%%%%%%%%
% ASD DISTANCE MATRIICES
%%%%%%%%%%%%%
% examined the distances between pariticpants

%folder with contrast files from 2-Back - 0-Back, separated by subject
cd F:\ASDD\Data2\PALM\glm_separated

%gr 1 is ASD, gr 2 is CON
g(1:29) = 1; g(30:49) = 2; 
%load data into matlab
 f=dir('*con1.dscalar.nii')
 for idx=1:length(f)
     %cifti matlab toolbox needed
     d = ft_read_cifti(f(idx).name);
     dat(idx,:) = d.dscalar; 
 end
 
 % remove subcortical
 cort=96854/3*2;
 dat=dat(:,1:cort); 
 % dat includes some NAN columns, need to remove
 dat = dat(:, ~isnan(dat(1,:)));

 %% Distances
 
pdis = pdist(dat(:,:), 'euclidean');
sdis = squareform(pdis);

cordis=pdist(dat, 'correlation');
scordis = squareform(cordis);

%calc mean distance for each sub
for idx = 1:49
    %mean euclidean distance
    mdis(idx) = mean(nonzeros(sdis(idx,:)));
    %mean correlational distance
    mcdis(idx) = mean(nonzeros(scordis(idx,:)));
end

%% plot matrix frm figure 4
%organize the data for plotting
s1=sortrows([ mcdis(1:29)', (1:29)'], 'descend');
s2=sortrows([ mcdis(30:49)', (30:49)']);
ord=[s1(:,2); s2(:,2)]

% plot color map of distances, as in Figure 4 in the paper
figure; imagesc(scordis(ord,ord), [0.3 1]); colormap(winter)

% boxplots or Figure 4
h= figure; boxplot([mcdis'], g,  'notch' , 'on', 'colors', [0 0 0])

% add subject data
hold on
plot([g',],[mcdis'], 'ok')
set(gca,'XTick',0)
saveas(gcf,['ROI_' num2str(idx) '.tiff'])

