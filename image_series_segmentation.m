%% --- clean ---
clearvars -except i data k N peri; clc; 

%% --- read files ---
%get the series path
selectedPath = uigetdir('.');
cd(selectedPath);
dirOutput = dir('*.jpg');
fileNames = {dirOutput.name}';
numFrames = numel(fileNames);

I = imread(fileNames{1});
%preallocate array
imageSeries = zeros([size(I) numFrames],class(I));
imageSeries(:,:,:,1) = I;

%read images to array
for p = 2:numFrames
    imageSeries(:,:,:,p) = imread(fileNames{p});
end

%% --- cropping ---
%crop images menually

img = imageSeries(:,:,:,1); %show the user one image
draw = 1; %a flag for the drawing loop. 1=>draw again 0=>crop


croppedImageSeries = [];
while draw == 1
clear croppedImageSeries;
figure(1)
imshow(img)
msgbox('Draw a rectengle to crop the image');
r1 = drawrectangle('Label','','Color',[1 0 0]);
%crop all images
for k = 1:numFrames
    croppedImageSeries(:,:,:,k) = imcrop(imageSeries(:,:,:,k),r1.Position);
end
figure(1)
title('Cropped images')
montage(croppedImageSeries)

selection = questdlg('Would you like to continue?', ...
	'Confirm cropped image series', ...
	'Confirm','Crop again','Crop again');
if strcmp(selection,'Confirm')
    draw = 0;
end
end
close(figure(1))

%% --- preprocessing ---
for k = 1:numFrames
% split channels- green channel
greenChannelSeries(:,:,k) = croppedImageSeries(:,:,2,k);
%Gaussian filter
guass(:,:,k) = imgaussfilt(greenChannelSeries(:,:,k),2);
% find threshold
OtsuLevel(:,k) = graythresh(guass(:,:,k));
% apply threshold
bw(:,:,k) = imcomplement(imbinarize(guass(:,:,k), OtsuLevel(:,k)));


% Erode mask with disk
radius = 8;
decomposition = 0;
se = strel('disk', radius, decomposition);
bw(:,:,k) = imerode(bw(:,:,k), se);
end

%% --- mask the inverted image with the thresholded image ---
for k = 1:numFrames
%medium mask
Medium_Bw_uint8(:,:,k) = uint8(bw(:,:,k)); % convert logical to integer
Medium_Masked(:,:,k) = greenChannelSeries(:,:,k) .* Medium_Bw_uint8(:,:,k); % mask image
end

%% --- measure grayscale values ---

for k = 1:numFrames
%medium measurements
MediumStats (k)= regionprops(Medium_Bw_uint8(:,:,k), Medium_Masked(:,:,k), 'MeanIntensity'); %mean intensity
MediumMI(k) = MediumStats(k).MeanIntensity 
end

%% --- find perimeter ---
for k = 1:numFrames 
findper(:,:,k) = bwperim(bw(:,:,k)); % perimeter
per(:,:,k) = greenChannelSeries(:,:,k) + 255 * uint8(findper(:,:,k)); % convert,scale, and overlay perimeter on image
end
