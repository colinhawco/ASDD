cd /mnt/tigrlab/projects/colin/ASDD/Data2/analysis

d=dir('sub*')

for pdx = 1:length(d)
    
    try
    cd(d(pdx).name)
    fname = deblank(ls(['*task-nbk_acq-*.tsv']))
    mf=tdfread(fname);
    FD(pdx)=mean(str2num(mf.FramewiseDisplacement(2:end,:)));
    name{pdx} = d(pdx).name; 
    end
    
    cd /mnt/tigrlab/projects/colin/ASDD/Data2/analysis
    
end



