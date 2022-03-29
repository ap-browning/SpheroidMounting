%% GET FILES
files = dir();
ignore = false(length(files),1);
for i = 1:length(files)
    fname = files(i).name;
    ignore(i) = length(fname) < 4 || ~strcmp(fname(end-2:end),'tif');
end
files = {files(~ignore).name};

%% GET METADATA
data = [];
for i = 1:length(files)
    info = split(files(i),"_");
    data(i).fname = files{i};
    data(i).hours = str2double(info{1}(1:end-1));
    data(i).condition = info{2};
    data(i).replicate = str2double(info{3}(1:end-4));
end

%% LOOP THROUGH
for i = 1:length(files)
    
    fname = data(i).fname;
    meta  = imfinfo(fname);

    dap = im2double(imread(fname,1));
    grn = im2double(imread(fname,2));
    red = im2double(imread(fname,3));
    brf = im2double(imread(fname,4));

    dap = dap / max(dap,[],'all');
    grn = grn / max(grn,[],'all');
    red = red / max(red,[],'all');
    brf = brf / max(brf,[],'all');

    %% COLORS
    msk1 = imbinarize(imadjust(dap + grn + red));
    msk1 = imdilate(msk1,strel('disk',20));
    msk1 = imfill(msk1,'holes');
    msk1 = bwareafilt(msk1,1);
    imshow(msk1);

    %% FILTER
    filt = stdfilt(imadjust(brf));
    msk  = imbinarize(filt) & msk1;
    msk  = imdilate(msk,strel('disk',20));
    msk  = imerode(msk,strel('disk',20));
    msk  = imfill(msk,'holes');
    msk  = imclearborder(msk);
    msk  = bwareafilt(msk,1);

    clf();
    imshow(brf); hold on;
    visboundaries(msk);
    title(fname);
    
    data(i).area = nnz(msk) / meta(1).XResolution^2;
    
end


