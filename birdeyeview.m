%% 버드아이뷰 테스트
% 비디오 파일 읽기
videoFile = 'tunnel_blackbox.mp4'; 
video = VideoReader(videoFile);

while hasFrame(video)
    
    I = readFrame(video);
    gray_I = rgb2gray(I);
    [rows, cols] = size(gray_I);

    imageSize = [720 1280];
    focalLength = [imageSize(2)/2, imageSize(1)/2];
    principalPoint = [imageSize(2)/2, imageSize(1)/2];
    

    camIntrinsics = cameraIntrinsics(focalLength,principalPoint,imageSize);
    
    
    height = 0.8;
    pitch = 1;
    
    
    sensor = monoCamera(camIntrinsics,height,'Pitch',pitch); 
    
    
    distAhead = 13; %센서로부터 앞쪽 거리
    spaceToOneSide = 7; %도로의 한쪽 공간
    bottomOffset = 5; 
    
    outView = [bottomOffset,distAhead,-spaceToOneSide,spaceToOneSide];
    
    outImageSize = [rows cols];
    
    birdsEye = birdsEyeView(sensor,outView,outImageSize);
    
    BEVImage = transformImage(birdsEye, I);
    
    
    %imshow(BEVImage); %버드아이뷰 변환이 완료된 이미지 
    
    
    
    gray_I = im2gray(BEVImage);
    

     % 최종 이미지를 초기화 (원본 이미지와 같은 크기)
    combined_image = im2double(zeros(size(BEVImage), 'like', BEVImage));
    
    % ROI 설정 및 평균 조도 계산 (원거리, 중거리, 근거리, 초근거리)
    rois = {
        struct('bottom_left', [cols * 0.3, rows * 0.25], 'top_left', [cols * 0.3, 0], ...
               'top_right', [cols *0.7, 0], 'bottom_right', [cols * 0.7, rows * 0.25], 'color', 'red'),
               
        struct('bottom_left', [cols * 0.3, rows * 0.5], 'top_left', [cols * 0.3, rows * 0.25], ...
               'top_right', [cols * 0.7, rows * 0.25], 'bottom_right', [cols * 0.7, rows * 0.5], 'color', 'green'),
               
        struct('bottom_left', [cols * 0.3, rows * 0.75], 'top_left', [cols * 0.3, rows * 0.5], ...
               'top_right', [cols * 0.7, rows * 0.5], 'bottom_right', [cols * 0.7, rows * 0.75], 'color', 'blue'),
               
        struct('bottom_left', [cols * 0.3, rows * 1], 'top_left', [cols * 0.3, rows * 0.75], ...
               'top_right', [cols * 0.7, rows * 0.75], 'bottom_right', [cols * 0.7, rows * 1], 'color', 'yellow')
    };
    
    % ROI마다 처리 수행
    for i = 1:length(rois)
        roi = rois{i};
        roi_mask = poly2mask([roi.bottom_left(1), roi.top_left(1), roi.top_right(1), roi.bottom_right(1)], ...
                             [roi.bottom_left(2), roi.top_left(2), roi.top_right(2), roi.bottom_right(2)], ...
                             rows, cols);
        gray_image_roi = bsxfun(@times, BEVImage, cast(roi_mask, 'like', BEVImage));
        mean_brightness = mean(gray_image_roi(:));

        % 흰색 검출
        filtered_image = hsv_white_detection(BEVImage, mean_brightness, roi_mask);
        %imshow(filtered_image); %roi를 확인할 수 있는 이미지
        combined_image = combined_image + im2double(filtered_image);
    end

    % ROI별로 합쳐진 이미지 표시
    combined_image = rgb2gray(combined_image);
    
    edges = edge(combined_image, 'Canny', [0.1, 0.3], 3);

    imshow(combined_image); %4개의 roi를 합친 이미지
    
    
    
    % 프레임 속도에 맞게 잠시 대기 (프레임 속도 조절)
    pause(1 / video.FrameRate);
    
end


function filtered_image = hsv_white_detection(I, mean_brightness, roi_mask)
    % HSV 색 공간으로 변환
    hsv_image = rgb2hsv(I);
    
    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도)
    sat_max = 0.3;      % 채도 범위
    
    val_max = 1;        % 명도 범위
    
    % 밝기에 따른 명도 범위 설정
    fprintf("평균 밝기 : %f\n", mean_brightness);
    if mean_brightness < 7 %어두운 경우
        val_min = 0.05;
        fprintf("어두움 감지\n");
    elseif mean_brightness > 19
        fprintf("!!!밝음 감지!!!\n")
        hsv_image(:,:,3) = hsv_image(:,:,3) * 0.5; % 밝기(명도)를 50%로 낮춤
        val_min = 0.5;
    else %평상시 밝기
        val_min = 0.7;
    end
    
    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
           (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
           (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % ROI 마스크 적용
    masked_image = bsxfun(@times, hsv_image, cast(mask, 'like', hsv_image));
    masked_image = bsxfun(@times, masked_image, cast(roi_mask, 'like', masked_image));
    
    % 필터링된 이미지를 RGB로 변환
    rgb_image = hsv2rgb(masked_image);
    filtered_image = rgb2gray(rgb_image);
    
end
    