Manual Grain Intercept Measurement Tool
=======================================

Overview
--------
This MATLAB script provides an interactive workflow for measuring grain boundary
intercepts on microstructural images. It is designed for materials science
applications such as grain size analysis, stereology, and quantitative metallography.

Features
--------
- Interactive image loading (supports .tif, .png, .jpg, .jpeg)
- Scale calibration by clicking on the scale bar and entering its length
- Customizable line placement:
  * Define number of horizontal and vertical lines
  * Manually draw reference lines; script auto-generates evenly spaced additional lines
- Grain boundary intercept measurement:
  * Click grain boundary intersections along each line
  * Distances between successive points are automatically calculated in microns
- Annotated image output with lines and intercept points marked
- Excel export:
  * Detailed intercept data (Measurements sheet)
  * Summary statistics (Summary sheet)

Workflow
--------
1. Load Image
   - Select a microstructural image file
2. Calibrate Scale
   - Click two ends of the scale bar
   - Enter the known scale length (µm)
3. Define Lines
   - Input number of horizontal and vertical lines
   - Draw reference lines; script auto-generates the rest
4. Measure Intercepts
   - Click grain boundary intersections along each line
   - Press ENTER when finished with a line
5. Save Results
   - Outputs:
     * imageName.xlsx → Measurements + Summary
     * imageName_Measured.png → Annotated image

Output Example
--------------
Measurements Table:
- Line number, direction, point coordinates, intercept length (µm)

Summary Statistics:
- Total intercepts
- Average intercept length
- Standard deviation
- Minimum and maximum intercepts

Requirements
------------
- MATLAB R2018b or later (tested)
- Image Processing Toolbox (recommended)

Usage
-----
Open MATLAB and run:
    ManualGrainIntercept.m

Notes
-----
- Horizontal lines are displayed in green, vertical lines in cyan
- Intercept points are marked in red (horizontal) and magenta (vertical)
- Works best with polished and etched microstructural images where grain boundaries are clearly visible
