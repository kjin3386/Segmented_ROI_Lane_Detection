# Segmented RoI for robust lane detection under varying illumination conditions.
##### This repository contains the source code for my paper:
##### CICS'24 [August, 2024] (https://www.dbpia.co.kr/journal/articleDetail?nodeId=NODE12051765)

### Overview
This project implements a lane detection algorithm designed to improve robustness under varying illumination conditions.  
The approach utilizes a segmented Region of Interest (RoI) method with a transformation matrix to account for perspective.  
![segmented RoIs](https://github.com/kjin3386/Segmented_ROI_Lane_Detection/blob/main/RoI.png)

Afterward, appropriate V values from the HSV colormap are applied to individual RoIs to enhance lane detection accuracy.
To determine the appropriate V value, I identified the mode of the V values in frames where lane markings were clear.
![V value histogram](https://github.com/kjin3386/Segmented_ROI_Lane_Detection/blob/main/V_value_hist.png)

This approach improved lane detection range in scenarios with significant illumination changes, such as entering or exiting a tunnel, compared to single RoI-based image processing.
![compare with single-RoI](https://github.com/kjin3386/Segmented_ROI_Lane_Detection/blob/main/comparsion.png)

![Example of lane Detection only using HSV threshold]([https://github.com/kjin3386/Segmented_ROI_Lane_Detection/blob/main/Result_example.png](https://github.com/kjin3386/Segmented_ROI_Lane_Detection/blob/main/result_example.png)


