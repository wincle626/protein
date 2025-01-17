% TESTCATSET Test suff_classify on various categorical data sets.
function testcatset(setname, nocv)

datasetdir = [fileparts(mfilename('fullpath')),filesep,'cat_datasets'];
if nargin == 0 || ~exist([datasetdir,filesep,setname,'.mat'],'file'),    
    dir([datasetdir,filesep,'*.mat']);
    return
end

if nargin == 1,
    nocv = 0;
end

load([datasetdir,filesep,setname]);

[n, nattr] = size(data);

if nocv,
    train_data = data(:,1:end-1);
    train_target = data(:,end);
    testsize = n;
    test_target = train_target;
else   
    cv = 10;
    testsize = fix(n/cv)
    trainsize = n - testsize
    perm = randperm(n);
    train_data = data(perm(1:trainsize),1:end-1);
    train_target = data(perm(1:trainsize),end);
    test_data = data(perm(trainsize+1:end),1:end-1);
    test_target = data(perm(trainsize+1:end),end);
end

options = struct(   'max_iterations',1,...                    
                    'new_classes',0,...
                    'remove_small',0,...                    
                    'final_adjust',0,...                                        
                    'potential_options',suffclass.potential.defaultoptions,...
                    'potval_options',suffclass.potential_values.defaultoptions);               
                
class_info = suffclass.classify(max(data(:,1:end-1),[],1),train_data,train_target, options);


if ~nocv,
    potvals = suffclass.potential_values(class_info.pot,class_info.options.potval_options);
    clpred = potvals.calcvals(test_data,class_info.potvals_priors);
    
    disp('test data confusion matrix:');
    confuspred = suffclass.utils.getfreq([test_target clpred]);
    disp(confuspred);
    q = sum(diag(confuspred))/sum(sum(confuspred));
    dprintf('diagonality: %.2f%%\n',q*100);
else
    disp('final confusion matrix:');
    disp(confus(:,:,end));
    q = trace(confus(:,:,end))/sum(sum(confus(:,:,end)));
    dprintf('diagonality: %.2f%%\n',q*100);
end
  
disp('random class confusion matrix:');
%rndcl = fix(rand(testsize,1)*max(train_target)) + 1;
rndcl = randperm(testsize);
rndcl = test_target(rndcl);
confrnd = suffclass.utils.getfreq([test_target rndcl]);
disp(confrnd);
q = trace(confrnd)/sum(sum(confrnd));
dprintf('diagonality: %.2f%%',q*100);
