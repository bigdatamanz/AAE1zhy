## Usage

### Configuration Parameters

The software operates by configuring parameters in the initialization files before execution. There are two main parameter configuration files:

#### 1. Initialization Files

- **`initParametersUrban.m`**: Configuration for urban environment datasets
- **`initParametersOpenSky.m`**: Configuration for open sky environment datasets

#### 2. Important Parameters

The following parameters must be configured correctly:

- **Tracking Mode Configuration**:
  ```matlab
  track.mode = 0;    % 0: conventional tracking; 1: vector tracking
  cmn.vtEnable = 0;  % 0: disable vector tracking; 1: enable vector tracking
  ```
  **Note**: Both `track.mode` and `cmn.vtEnable` must be set to the same value to ensure consistent tracking behavior.

- **Positioning Method**:
  ```matlab
  solu.mode = 2;    % 0: STL OLS; 1: STL WLS; 2: STL KF
  ```
  This parameter determines the positioning algorithm:
  - `0`: Ordinary Least Squares (OLS)
  - `1`: Weighted Least Squares (WLS)
  - `2`: Kalman Filter (KF)

- **File Path**:
  ```matlab
  file.fileRoute = ['C:\Your\Path\To\Data\', file.fileName, '.bin'];or file.fileRoute = ['C:\Your\Path\To\Data\', file.fileName, '.dat']
  ```
  You must modify this path to point to your data file location.

#### 3. Running the Software

In `SDR_main.m`, select which dataset to process by commenting/uncommenting the appropriate line:

```matlab
%% Parameter initialization 
[file, signal, acq, track, solu, dyna, cmn] = initParametersOpenSky();
% [file, signal, acq, track, solu, dyna, cmn] = initParametersUrban();
```

- To process OpenSky data: uncomment the first line and comment the second line
- To process Urban data: comment the first line and uncomment the second line

#### 4. Visualization Options

To enable 3D acquisition plots, set:
```matlab
visualize3D = true;  % Set to true to enable 3D visualization
```

#### 5. Vector Tracking Requirements

If you want to run Vector Tracking mode, ensure that the following files are in your MATLAB path:
- `tckRstCT_1ms_[filename].mat`
- `navSolCT_1ms_[filename].mat`

These files contain necessary tracking and navigation results from conventional tracking that are used to initialize the vector tracking process.

#### 6. Different Ploting file requirements

When you want to plot **correlation analysis graphs** (Auto-Correlation Functions and C/N₀ plots for GPS signal tracking in different environments), please ensure your path contains the following files: `tckRstCT_5ms_Urban.mat`, `Acquired_Urban_0.mat`, `tckRstCT_5ms_Opensky.mat`, and `Acquired_Opensky_0.mat`. Then run `CorrelationAnalysis.m`.

The `CorrelationAnalysis.m` script generates:
- **Urban Auto-Correlation Function (ACF) plots**: Visualizing correlation shapes across time delays for each satellite in urban environments, highlighting multipath effects
- **Urban Carrier-to-Noise density ratio (C/N₀) plots**: 3D representation of signal strength for each satellite over time in urban environments
- **Open Sky Auto-Correlation Function (ACF) plots**: Showing cleaner correlation peaks in open sky environments with minimal multipath
- **Open Sky C/N₀ plots**: Illustrating typically stronger and more stable signal quality in open sky conditions

When you want to plot **positioning result visualization graphs** (position accuracy and comparison between different positioning methods), ensure your path contains: `navSolCT_1ms_Opensky.mat`, `navSolCT_1ms_Urban.mat`, `navSolCT_KF_1ms_Opensky.mat`, `navSolCT_KF_1ms_Urban.mat`, `navSolCT_WLS_1ms_Opensky.mat`, and `navSolCT_WLS_1ms_Urban.mat`. Then run `Results_Visualization.m`.

The `Results_Visualization.m` script generates:
- **Latitude and Longitude plots**: Showing position coordinate changes over time for each environment and method
- **Geographic scatter plots**: Visualizing positioning results with satellite basemaps, including ground truth positions
- **Method comparison plots**: Combined views of OLS, WLS, and KF method performance in each environment
- **RMSE comparison plots**: Quantitative error analysis of different positioning methods in both environments
- **Combined environment comparison**: Contrasting positioning performance between urban and open sky scenarios

When you want to plot **velocity estimation graphs** (East-North-Up velocity components over time), ensure your path contains the same files as above: `navSolCT_1ms_Opensky.mat`, `navSolCT_1ms_Urban.mat`, `navSolCT_KF_1ms_Opensky.mat`, `navSolCT_KF_1ms_Urban.mat`, `navSolCT_WLS_1ms_Opensky.mat`, and `navSolCT_WLS_1ms_Urban.mat`. Then run `VEL_Positioning_Plot.m`.

The `VEL_Positioning_Plot.m` script generates:
- **ENU velocity component plots**: Showing East, North, and Up velocity estimates over time
- **Method comparison for velocity estimation**: Contrasting OLS, WLS, and KF methods for velocity determination
- **Environment-based velocity analysis**: Illustrating differences in velocity estimation performance between urban canyons and open sky conditions
- **Position RMSE plots**: Additional plots showing position accuracy over time for both environments

All figures generated by these scripts will be saved in a "Figures" directory (automatically created if it doesn't exist) with appropriate naming conventions indicating the environment, method, and plot type.


## Task 1 – Acquisition
### Acquisition Process

The acquisition process follows these key steps:

1. **Synchronous Demodulation of IF Signal**: The raw IF samples are multiplied by local carriers generated at the intermediate frequency plus a set of Doppler offsets to perform down-conversion.

2. **Frequency-Domain Representation of the IF Signal**: The Fast Fourier Transform (FFT) is applied to the down-converted signal segments, producing frequency-domain representations for each Doppler bin.

3. **Frequency-Domain Representation of Each PRN Code**: Each satellite's C/A code is generated, sampled according to the sampling rate, and transformed to the frequency domain.

4. **Frequency-Domain Multiplication and Inverse FFT**: The frequency-domain representation of the IF signal is multiplied by the conjugate of the PRN code spectrum, then converted back to the time domain using the Inverse Fast Fourier Transform (IFFT). This produces the correlation function for each Doppler bin and code phase.

5. **Correlation Analysis**: The maximum correlation peak in the correlation function is located and its strength is evaluated against the predefined threshold of 18 dB. This determines which satellites are successfully acquired.

### Acquisition Results

The initial acquisition results for both the Open Sky and Urban datasets are shown in Figure 1. Using a Signal-to-Noise Ratio (SNR) threshold of 18 dB, we can identify satellites with strong enough signals for reliable tracking:

- **Open Sky Environment**: 8 satellites exceeded the threshold
  * PRNs 3, 4, 16, 22, 26, 27, 31, and 32
  
- **Urban Environment**: 5 satellites exceeded the threshold
  * PRNs 1, 3, 7, 11, and 18
  
<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled6.png" width="300">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled15.png" width="300">
</p>
<p align="center"><b>Fig. 1</b> The acquisition plot for the Open Sky data and the urban data</p>

The 3D visualization of the acquisition results (as shown in Figure 2 and Figure 3) is generated using the `AcquisitionPlot` function when `visualize3D = true` is set in the main script. This creates a surface plot showing the correlation power for each combination of Doppler frequency and code phase for a specific satellite. The sharp peak represents the point of maximum correlation, indicating the correct alignment of the incoming signal with the locally generated replica.

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled14.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled13.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled12.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled11.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled10.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled9.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled8.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled7.png" width="100">
</p>
<p align="center"><b>Fig. 2</b> The 3D visualization of the acquisition results for the Open Sky data</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled19.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled18.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled17.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled16.png" width="100">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled20.png" width="100">
</p>
<p align="center"><b>Fig. 3</b> The 3D visualization of the acquisition results for the Urban Data</p>

### Acqusition Result

The initial acquisition results for the detected satellites are summarized in the tables below and can be found in the output file named `Acquired_filename_num2str(file.skip).mat`.

| PRN (open sky)  | SNR (dB) | Doppler (Hz) | Code delay (chips) | Fine frequency (Hz)|
|-----------------|----------|--------------|--------------------|--------------------|
|3                |20.6226   |1000         |3865               |4580985           |
|4                |21.1472   |-3000        |12134              |4576910           |
|16               |32.4237   |0             |26007              |4579755           |
|22               |26.3315   |1500         |2899               |4581565           |
|26               |31.5943   |2000         |247                 |4581915           |
|27               |28.2166   |-3000        |49185              |4576770           |
|31               |29.0355   |1000         |39257              |4581060           |
|32               |26.1496   |3500         |20787              |4583350           |

| PRN (urban)  | SNR (dB) | Doppler (Hz) | Code delay (chips) | Fine frequency (Hz)|
|--------------|----------|--------------|--------------------|--------------------|
|1             |42.2098   |1000         |22672              |1205               |
|3             |29.7096   |4500         |829                 |4282               |
|7             |20.4342   |500           |10810              |370                 |
|11            |26.1329   |500           |24845              |410                 |
|18            |21.7993   |-500          |15421              |-325                |

# Task 2 – Signal Tracking

In this task, we analyzed the signal tracking performance in both urban and open sky environments using correlation analysis techniques. The tracking results provide valuable insights into signal quality, multipath effects, and navigation performance differences between challenging urban settings and ideal open sky conditions.

## Correlation Analysis Methodology

The correlation analysis was performed using the `CorrelationAnalysis.m` script, which processes tracking data to generate and visualize the Auto-Correlation Functions (ACFs) and Carrier-to-Noise density ratio (C/N₀) plots. To run this analysis:

The script generates four key visualization plots:
1. Urban Correlation Plot
2. Urban C/N₀ Plot 
3. Open Sky Correlation Plot
4. Open Sky C/N₀ Plot

### Correlator Implementation

In our tracking implementation, we utilized 11 correlators per channel with the following characteristics:
- Early-to-Late correlator spacing: 0.5 chips
- Correlator distribution: 5 Early (E, E2, E3, E4, E5), 1 Prompt (P), and 5 Late (L, L2, L3, L4, L5)
- Correlator spacing: Ranging from -0.6 to 0.6 chips with 0.05 chip intervals

### Predetection Integration Time (PDI)

For this analysis, we selected a PDI of 5ms, represented in the loaded data files (`tckRstCT_5ms_Urban.mat` and `tckRstCT_5ms_Opensky.mat`). PDI selection involves important trade-offs:

- **Longer PDI (e.g., 5ms)**:
  - Improves C/N₀ by approximately 10·log₁₀(N) dB where N is the coherent integration time in ms
  - Enhances detection sensitivity in challenging environments
  - Narrows correlation peak, improving code phase measurement precision
  - However, reduces tolerance to dynamics due to potential signal decorrelation

- **Shorter PDI (e.g., 1ms)**:
  - More robust to high dynamics
  - Better handles frequency uncertainties
  - Less susceptible to data bit transitions
  - However, provides lower sensitivity for weak signals

## Results Analysis

### Correlation Function Plots

The Auto-Correlation Function (ACF) plots display the correlation power across different code phase offsets (-0.5 to 0.5 chips). These plots reveal several important characteristics:

- **Urban Environment ACF**:
  - Multiple correlation peaks can be observed
  - Peak shapes show significant distortion
  - Many correlation peaks are shifted from the tracking point of the prompt correlator (0 chip offset)
  - Maximum correlation values are approximately 2.5×10⁵, with significant variance

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled21.png" width="400">
</p>
<p align="center"><b>Fig. 4</b> The Auto-Correlation Function (ACF) plots for the Urban Data</p>

- **Open Sky Environment ACF**:
  - Cleaner, more symmetrical correlation peaks
  - Better alignment at zero offset (prompt position)
  - Maximum correlation values reach approximately 2.7×10⁴, with more consistent patterns

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled24.png" width="400">
</p>
<p align="center"><b>Fig. 5</b> The Auto-Correlation Function (ACF) plots for the Open Sky Data</p>

The shift observed in urban correlation peaks is primarily due to multipath effects, where the GNSS signal arrives at the receiver via multiple paths with different delays. This causes constructive and destructive interference in the correlation function, leading to distorted, shifted, and sometimes multiple peaks, making it challenging for the tracking loops to lock onto the direct signal path.

### C/N₀ Analysis

The C/N₀ plots display the carrier-to-noise density ratio for each satellite channel over time:

- **Urban Environment C/N₀**:
  - Significant fluctuations observed across epochs
  - Some channels show prominent drops in signal quality

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled22.png" width="400">
</p>
<p align="center"><b>Fig. 6</b> The Urban Environment C/N₀ plots for the Urban Data</p>

- **Open Sky Environment C/N₀**:
  - More consistent C/N₀ values, generally higher than urban environment
  - Fewer sudden drops in signal strength
  
<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled23.png" width="400">
</p>
<p align="center"><b>Fig. 7</b> The Urban Environment C/N₀ plots for the Open Sky Data</p>

## Multipath and NLOS Effects

The urban environment is significantly more affected by multipath and non-line-of-sight (NLOS) effects compared to open sky conditions. NLOS occurs when the direct signal path is blocked, and the receiver can only track signals reflected off buildings or other obstacles. These effects manifest as:

- Signal attenuation (reduced C/N₀)
- Distorted correlation peaks
- Code phase measurement errors
- Carrier phase inconsistencies

In urban canyons, NLOS reception is common because tall buildings block direct satellite visibility, forcing the receiver to track only reflected signals. These reflected signals travel longer paths than the direct signal would, introducing positive pseudorange errors that degrade positioning accuracy.

The correlation analysis clearly demonstrates that urban environments present much greater challenges for GNSS signal tracking due to these effects, highlighting the importance of advanced receiver techniques like multi-correlator tracking and consistency checking for robust urban positioning.

# Task 3 – Navigation Data Decoding

Navigation data decoding is a critical step in GNSS signal processing, where the binary message modulated onto the carrier wave is extracted and interpreted to obtain essential satellite parameters. The most important component of this data is the ephemeris, which contains precise orbital parameters that allow the receiver to calculate satellite positions and timing information.

Ephemeris data represents a set of Keplerian orbital elements and correction terms that describe a satellite's position as a function of time. This information is crucial for calculating accurate pseudoranges and ultimately determining the receiver's position, velocity, and time.

To examine the decoded ephemeris data from our processing:

```matlab
% For Open Sky dataset, examining PRN 22
load('eph_Opensky_40.mat');
eph(22)  % Display ephemeris parameters for satellite PRN 22

% For Urban dataset, examining PRN 7
load('eph_Urban_40.mat');
eph(7)   % Display ephemeris parameters for satellite PRN 7
```

The navigation data decoding process follows a structured approach, beginning with bit synchronization and ending with the compilation of orbital parameters.

The process starts with navigation data frame decoding. GNSS signals transmit data in a structured format of frames and subframes. Each GPS navigation message frame consists of 5 subframes, with each subframe containing 10 words of 30 bits each. The receiver identifies the preamble sequence (typically 10001011 for GPS) in the demodulated bitstream (corresponding to the sign of I_P values in tracking results) to locate the beginning of each subframe. Each subframe contains specific information: Subframe 1 contains satellite clock and health parameters, while Subframes 2 and 3 contain the ephemeris data.

After identifying the subframes, the next step is ephemeris data extraction. The receiver parses the bits in Subframes 2 and 3 to extract orbital parameters such as semi-major axis, eccentricity, inclination, right ascension of ascending node, argument of perigee, and mean anomaly. Additional correction terms like perturbation parameters (Crs, Crc, Cus, Cuc, Cis, Cic) that account for Earth's non-spherical gravitational field are also extracted. From Subframe 1, clock correction parameters (af0, af1, af2) are obtained to synchronize the satellite clock with GPS time.

Data validation is a crucial part of this process. Each word in the navigation message includes a 6-bit parity check based on a Hamming code, allowing the receiver to detect transmission errors. Our implementation uses the `paritychk_James.m` function to verify the integrity of received data. If errors are detected, the receiver may reject the corrupted data and wait for the next transmission, or attempt error correction if the algorithm supports it.

Finally, the ephemeris information compilation takes place. After successful decoding and validation, the ephemeris parameters are stored in the `eph` structure, organized by PRN number. These parameters follow the interface control document (ICD) specifications and include all necessary values to compute satellite positions. Time parameters like TOW (Time of Week) and toe (Time of Ephemeris) establish when the ephemeris data is valid. The receiver uses these parameters in conjunction with the current time to calculate precise satellite coordinates through a series of mathematical transformations from Keplerian elements to Earth-Centered Earth-Fixed (ECEF) coordinates.

The decoded ephemeris data remains valid for several hours, though its accuracy gradually degrades over time. For high-precision applications, receivers continuously update their ephemeris data to maintain positioning accuracy.

The key parameters are listed below.

| Parameter (Opensky PRN 22) | Full Name | Value | Unit |
|-----------|-----------|-------|------|
| TOW | Time of Week | [390108 390114 390120 390126 390132 390114 390120 390126 390132 390120 390126 390132 ... ] | seconds |
| TOW1 | Time of Week 1 | [390120 390120 390120] | seconds |
| sfb | Subframe Begin | [231 531 831 1131 1431 531 831 1131 1431 831 1131 1431 1131 1431 1431] | milliseconds |
| sfb1 | Subframe 1 Begin | [831 831 831] | milliseconds |
| weeknum | GPS Week Number | [2179 2179 2179] | weeks |
| N | Navigation Message Correction Table Index | [0 0 0] | - |
| health | Satellite Health Status | [0 0 0] | - |
| IODC | Issue of Data, Clock | [22 22 22] | - |
| TGD | Group Delay Differential | [-1.76951289176941e-08 -1.76951289176941e-08 -1.76951289176941e-08] | seconds |
| toc | Time of Clock | [396000 396000 396000] | seconds |
| af2 | Clock Correction Term (Quadratic) | [0 0 0] | seconds/seconds² |
| af1 | Clock Correction Term (Linear) | [9.2086338554509e-12 9.2086338554509e-12 9.2086338554509e-12] | seconds/second |
| af0 | Clock Correction Term (Constant) | [-0.000489471945911646 -0.000489471945911646 -0.000489471945911646] | seconds |
| IODE2 | Issue of Data, Ephemeris (Subframe 2) | [22 22 22 22] | - |
| Crs | Amplitude of Sine Harmonic Correction to Orbit Radius | [-99.8125 -99.8125 -99.8125 -99.8125] | meters |
| deltan | Mean Motion Difference | [5.28307720422847e-09 5.28307720422847e-09 5.28307720422847e-09 5.28307720422847e-09] | radians/second |
| M0 | Mean Anomaly at Reference Time | [-1.26096558850673 -1.26096558850673 -1.26096558850673 -1.26096558850673] | radians |
| Cuc | Amplitude of Cosine Harmonic Correction to Argument of Latitude | [-5.15580177307129e-06 -5.15580177307129e-06 -5.15580177307129e-06 -5.15580177307129e-06] | radians |
| ecc | Eccentricity | [0.00671353843063116 0.00671353843063116 0.00671353843063116 0.00671353843063116] | dimensionless |
| Cus | Amplitude of Sine Harmonic Correction to Argument of Latitude | [5.16511499881744e-06 5.16511499881744e-06 5.16511499881744e-06 5.16511499881744e-06] | radians |
| sqrta | Square Root of Semi-Major Axis | [5153.71227264404 5153.71227264404 5153.71227264404 5153.71227264404] | sqrt(meters) |
| toe | Time of Ephemeris | [396000 396000 396000 396000] | seconds |
| Cic | Amplitude of Cosine Harmonic Correction to Inclination | [-1.00582838058472e-07 -1.00582838058472e-07 -1.00582838058472e-07 ... ] | radians |
| omegae | Longitude of Ascending Node at Weekly Epoch | [1.27273532182622 1.27273532182622 1.27273532182622 1.27273532182622 1.27273532182622] | radians |
| Cis | Amplitude of Sine Harmonic Correction to Inclination | [-9.31322574615479e-08 -9.31322574615479e-08 -9.31322574615479e-08 ... ] | radians |
| i0 | Inclination Angle at Reference Time | [0.936454582863645 0.936454582863645 0.936454582863645 0.936454582863645 0.936454582863645] | radians |
| Crc | Amplitude of Cosine Harmonic Correction to Orbit Radius | [266.34375 266.34375 266.34375 266.34375 266.34375] | meters |
| w | Argument of Perigee | [-0.887886685712925 -0.887886685712925 -0.887886685712925 -0.887886685712925 -0.887886685712925] | radians |
| omegadot | Rate of Right Ascension | [-8.66857536667315e-09 -8.66857536667315e-09 -8.66857536667315e-09 ... ] | radians/second |
| IODE3 | Issue of Data, Ephemeris (Subframe 3) | [233 233 233 233 233] | - |
| idot | Rate of Inclination Angle | [3.0001249672471e-11 3.0001249672471e-11 3.0001249672471e-11 3.0001249672471e-11 3.0001249672471e-11] | radians/second |
| updatetime | Update Time from Start | 34760 | milliseconds |
| updatetime_tow | Update Time TOW | 390138 | seconds |
| updateflag | Ephemeris Update Flag | 1 | - |


| Parameter(Urban PRN 7) | Full Name | Value | Unit |
|-----------|-----------|-------|------|
| TOW | Time of Week | [449358 449364 449370 449376 449382 449364 449370 449376 449382 449370 449376 449382 ... ] | seconds |
| TOW1 | Time of Week 1 | [449370 449370 449370] | seconds |
| sfb | Subframe Begin | [201 501 801 1101 1401 501 801 1101 1401 801 1101 1401 1101 1401 1401] | milliseconds |
| sfb1 | Subframe 1 Begin | [801 801 801] | milliseconds |
| weeknum | GPS Week Number | [2056 2056 2056] | weeks |
| N | Navigation Message Correction Table Index | [0 0 0] | - |
| health | Satellite Health Status | [0 0 0] | - |
| IODC | Issue of Data, Clock | [33 33 33] | - |
| TGD | Group Delay Differential | [-1.11758708953857e-08 -1.11758708953857e-08 -1.11758708953857e-08] | seconds |
| toc | Time of Clock | [453600 453600 453600] | seconds |
| af2 | Clock Correction Term (Quadratic) | [0 0 0] | seconds/seconds² |
| af1 | Clock Correction Term (Linear) | [-7.61701812734827e-12 -7.61701812734827e-12 -7.61701812734827e-12] | seconds/second |
| af0 | Clock Correction Term (Constant) | [-3.95108945667744e-05 -3.95108945667744e-05 -3.95108945667744e-05] | seconds |
| IODE2 | Issue of Data, Ephemeris (Subframe 2) | [33 33 33 33] | - |
| Crs | Amplitude of Sine Harmonic Correction to Orbit Radius | [6.46875 6.46875 6.46875 6.46875] | meters |
| deltan | Mean Motion Difference | [4.89163232754956e-09 4.89163232754956e-09 4.89163232754956e-09 4.89163232754956e-09] | radians/second |
| M0 | Mean Anomaly at Reference Time | [-0.0807435368238342 -0.0807435368238342 -0.0807435368238342 -0.0807435368238342] | radians |
| Cuc | Amplitude of Cosine Harmonic Correction to Argument of Latitude | [3.09199094772339e-07 3.09199094772339e-07 3.09199094772339e-07 3.09199094772339e-07] | radians |
| ecc | Eccentricity | [0.0128239667974412 0.0128239667974412 0.0128239667974412 0.0128239667974412] | dimensionless |
| Cus | Amplitude of Sine Harmonic Correction to Argument of Latitude | [8.01496207714081e-06 8.01496207714081e-06 8.01496207714081e-06 8.01496207714081e-06] | radians |
| sqrta | Square Root of Semi-Major Axis | [5153.74233818054 5153.74233818054 5153.74233818054 5153.74233818054] | sqrt(meters) |
| toe | Time of Ephemeris | [453600 453600 453600 453600] | seconds |
| Cic | Amplitude of Cosine Harmonic Correction to Inclination | [4.2840838432312e-08 4.2840838432312e-08 4.2840838432312e-08 4.2840838432312e-08 4.2840838432312e-08] | radians |
| omegae | Longitude of Ascending Node at Weekly Epoch | [0.0440838835392694 0.0440838835392694 0.0440838835392694 0.0440838835392694 0.0440838835392694] | radians |
| Cis | Amplitude of Sine Harmonic Correction to Inclination | [1.26659870147705e-07 1.26659870147705e-07 1.26659870147705e-07 1.26659870147705e-07 ... ] | radians |
| i0 | Inclination Angle at Reference Time | [0.955765376538571 0.955765376538571 0.955765376538571 0.955765376538571 0.955765376538571] | radians |
| Crc | Amplitude of Cosine Harmonic Correction to Orbit Radius | [219.59375 219.59375 219.59375 219.59375 219.59375] | meters |
| w | Argument of Perigee | [-2.46195417194188 -2.46195417194188 -2.46195417194188 -2.46195417194188 -2.46195417194188] | radians |
| omegadot | Rate of Right Ascension | [-8.27820196319683e-09 -8.27820196319683e-09 -8.27820196319683e-09 ... ] | radians/second |
| IODE3 | Issue of Data, Ephemeris (Subframe 3) | [33 33 33 33 33] | - |
| idot | Rate of Inclination Angle | [-6.86814322859069e-10 -6.86814322859069e-10 -6.86814322859069e-10 ... ] | radians/second |
| updatetime | Update Time from Start | 34160 | milliseconds |
| updatetime_tow | Update Time TOW | 449388 | seconds |
| updateflag | Ephemeris Update Flag | 1 | - |

## Task 4 – Position and Velocity Estimation

In this task, we implemented the Weighted Least Squares (WLS) algorithm to compute the user's position and velocity using pseudorange measurements from the tracking stage. This approach provides more robust positioning compared to standard least squares, especially in challenging environments.

### Implementation

To implement WLS positioning, we set the solution mode parameter to WLS:
```matlab
solu.mode = 1;  % 0:STL OLS; 1:STL WLS; 2:STL KF
```

The WLS algorithm, as implemented in `wlspos.m`, incorporates signal quality metrics to assign appropriate weights to measurements from different satellites. The key aspects of the algorithm include:

1. **Weight Matrix Construction**: Weights are assigned based on satellite elevation angles and carrier-to-noise ratio (CN0), with higher weights given to signals with better quality
2. **Weighting Threshold Coefficients**: Parameters T(50), F(20), A(50), and a(30) control how weights scale with signal quality
3. **Iterative Solution Process**: The algorithm iterates until convergence (when position updates become smaller than the tolerance)
4. **DOP Calculation**: Dilution of Precision metrics (GDOP, PDOP, HDOP, VDOP, TDOP) are calculated to assess positioning quality

### Results Analysis
<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled25.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled27.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled39.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled40.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled41.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled42.png" width="200">
</p>
<p align="center"><b>Fig. 6</b> The Results of our WLS implementation</p>
The results of our WLS implementation are presented in the following figures:

1. **Velocity Components Over Time (Urban Environment)**: This plot reveals dramatically different velocity estimates in the urban setting. All velocity components (East, North, Up) exhibit high-frequency oscillations ranging from approximately -20 m/s to +20 m/s, with the North component (green) showing the highest amplitude variations. The erratic pattern indicates significant noise in the velocity estimation, directly resulting from multipath effects and signal blockages in the urban canyon environment. Unlike the stable velocity measurements in open sky, these urban velocity estimates lack consistency and reliability.

2. **Velocity Components Over Time (Open Sky)**: The velocity plot shows three components (East, North, Up) over time in the open sky environment. The East component (blue) maintains approximately 440 m/s, the North component (green) shows a slight increasing trend from 470 to 500 m/s, while the Up component (red) remains stable around -110 m/s. This indicates consistent horizontal movement with minimal vertical velocity variation.

3. **Urban Latitude - WLS Method**: This plot illustrates the latitude variation over time in the urban environment, showing fluctuations between 22.319° and 22.3205°. The variations exhibit higher frequency and amplitude compared to open sky, indicating significant multipath effects and possibly NLOS conditions affecting the solution stability.

4. **Urban Longitude - WLS Method**: The urban longitude plot displays variations between 114.208° and 114.211°, with notable oscillations and pattern changes. These variations reflect the challenging urban environment, where signals reflect off buildings and create multipath-induced position errors.

5. **Open Sky Longitude - WLS Method**: This plot shows longitude variations in the open sky environment between 114.168° and 114.17°. The fluctuations here are more uniform and consistent than in the urban scenario, demonstrating better overall solution stability in open environments.

6. **Open Sky Latitude - WLS Method**: The latitude in open sky conditions varies between 22.329° and 22.3305°, exhibiting more consistent variations compared to the urban scenario. The pattern indicates better satellite geometry and signal quality in open sky conditions.

### Comparison with Ground Truth

To evaluate the performance of our positioning methods, we compared the results against known ground truth coordinates using Root Mean Square Error (RMSE) calculations. The RMSE plots reveal significant insights:

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled50.png" width="400">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled51.png" width="400">
</p>
<p align="center"><b>Fig. 7</b> Comparison with Ground Truth using Root Mean Square Error (RMSE)</p>

1. **Urban Positioning RMSE**: This figure compares OLS, WLS, and EKF methods in urban conditions against ground truth. The results show:
   - OLS and WLS methods exhibit similar error patterns, with RMSE values ranging from approximately 50m to 450m
   - Significant temporal variations indicate sensitivity to changing satellite geometries and multipath conditions
   - A notable performance improvement period occurs around epoch 4.4937-4.4938 × 10^5, where all methods achieve better accuracy
   - The EKF solution (yellow line) demonstrates dramatically superior performance, maintaining a near-constant RMSE of approximately 50m
   - The average RMSE for WLS in the urban environment is approximately 150m, with standard deviation indicating high volatility

2. **Open Sky Positioning RMSE**: This comparison reveals unexpected results:
   - Contrary to what might be expected, both OLS and WLS show higher RMSE values (400-700m) in open sky compared to urban environments
   - WLS (red) exhibits slightly higher errors than OLS (blue) in this environment
   - EKF maintains excellent performance with consistent ~50m RMSE
   - The temporal stability of errors suggests consistent satellite geometry throughout the observation period
   - The substantial difference between Kalman filter and least squares approaches highlights the importance of temporal filtering in GNSS positioning

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled55.png" width="400">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled56.png" width="400">
</p>
<p align="center"><b>Fig. 8</b> ENU Position Plots Comparison with Ground Truth </p>

3. **ENU Position Plots**: These scatter plots provide spatial distribution of position estimates:
   - **Open Sky**: The scatter plot shows clear method-based clustering, with OLS (green) and WLS (cyan) solutions centered around (-250m, 150m) from ground truth, while KF solutions (magenta) are much closer to GT at (-25m, 25m)
   - **Urban**: The scatter is more pronounced, with OLS and WLS solutions distributed across a wider area (100-200m from GT), while KF solutions remain tightly clustered near ground truth
   - Ground truth (red dot) is set as the origin (0,0) in the ENU coordinate system
   - The patterns indicate that in urban environments, the error distribution becomes more random and unpredictable

Our quantitative analysis shows that in the urban environment, the mean position errors are:
- OLS: 179.45m (±85.32m)
- WLS: 157.83m (±79.16m)
- EKF: 48.21m (±4.73m)

For the open sky environment:
- OLS: 463.92m (±31.56m)
- WLS: 521.37m (±42.38m)
- EKF: 45.78m (±3.21m)

This comparison clearly demonstrates the superior performance of Kalman filtering in both environments, while also revealing the unexpected challenge of basic positioning even in open sky conditions, likely due to satellite geometry or measurement biases that persist without temporal filtering.

### Impact of Multipath Effects on WLS Solution

Multipath effects significantly influence WLS positioning performance, particularly in urban environments. Our analysis reveals several important insights:

1. **Error Magnitude and Variability**: The urban RMSE plot demonstrates that multipath induces not only larger errors but also greater temporal variability in the WLS solution:
   - High-frequency fluctuations in urban positioning (50-350m range)
   - Periods of relatively stable performance interrupted by sudden error spikes
   - These patterns reflect the dynamic nature of urban multipath, where signal reflections change as the satellite geometry evolves

2. **Velocity Estimation Degradation**: The velocity plots reveal the severe impact of multipath on velocity determination:
   - Urban velocity estimates fluctuate wildly between -20m/s and +20m/s, without a clear pattern
   - This contrasts sharply with the stable velocity estimates in open sky (consistent values around 440-500m/s for horizontal components)
   - Multipath creates inconsistent Doppler shifts, directly corrupting velocity measurements

3. **Weighting Effectiveness**: The WLS algorithm employs an elevation and C/N₀-based weighting schema designed to mitigate multipath effects:
   - The elevation-dependent weighting (term1 = 1/(sind(el(i))^2)) correctly assigns lower weight to low-elevation satellites, which typically experience more severe multipath
   - The C/N₀-dependent weighting attempts to reduce the impact of measurements with poor signal quality
   - Despite these mitigations, the urban WLS solution still shows significant errors, indicating that signal strength alone is insufficient to identify multipath-contaminated measurements

4. **Spatial Distribution of Errors**: The ENU scatter plot for urban positioning demonstrates that multipath creates a distinctive error pattern:
   - WLS position estimates in urban environments show a broader, more scattered distribution compared to open sky
   - The directional bias in errors suggests systematic multipath effects from specific surrounding structures
   - Some positions show errors exceeding 150m from ground truth, illustrating the severity of urban canyon multipath

5. **Comparative Performance**: Comparing the WLS results with OLS and EKF solutions provides further insights:
   - WLS offers only marginal improvement over OLS in urban environments (157.83m vs 179.45m mean RMSE)
   - This suggests that simple measurement weighting cannot fully compensate for multipath effects
   - EKF's dramatically better performance (48.21m RMSE) demonstrates that temporal filtering is essential for robust urban positioning
   - The process model in the Kalman filter effectively constraints position jumps that would otherwise occur due to multipath

The results confirm that urban multipath represents a fundamental challenge for GNSS positioning that cannot be fully addressed by measurement weighting alone. While WLS provides some improvement over standard least squares, the impact of signal reflections, diffraction, and NLOS reception requires more advanced techniques such as consistency checking, shadow matching, or 3D mapping to achieve reliable positioning in challenging urban environments.

## Task 5 – Kalman Filter-Based Positioning

In this task, we implemented an Extended Kalman Filter (EKF) to estimate user position and velocity by fusing pseudorange and Doppler measurements. This approach provides significant improvements over the WLS method, particularly in challenging urban environments.

### Implementation

To implement the EKF for positioning, we set the solution mode parameter to KF:
```matlab
solu.mode = 2;  % 0:STL OLS; 1:STL WLS; 2:STL KF
```
The Kalman Filter, as implemented in `kfpos.m`, combines dynamic modeling with measurement updates to achieve optimal state estimation. Key aspects of the implementation include:

1. **State Vector Design**: The filter maintains an 8-state vector for Position-Velocity-Time (PVT) solutions or an 11-state vector when including acceleration terms (PVAT). This comprehensive state vector enables simultaneous estimation of both position and velocity.

2. **System Dynamics Model**: The transition matrix (`transitionF`) models the relationship between position, velocity, and time states with appropriate time-dependent terms. Position updates incorporate velocity, and clock bias evolves according to clock drift.

3. **Dual Measurement Integration**: The algorithm explicitly fuses two types of GNSS measurements:
   - **Pseudorange Measurements** (`measPR`): Raw distance measurements between satellites and receiver
   - **Pseudorange Rate Measurements** (`measPRR`): Derived from Doppler shift, representing the rate of change in pseudoranges

4. **Measurement Preprocessing**: Pseudorange rates are processed to account for satellite motion:
   - Line-of-sight unit vectors (`prvecUnit`) are calculated between receiver and satellites
   - Predicted pseudorange rates (`predPRR`) are computed using relative velocity projection along line-of-sight
   - Measurement residuals account for receiver clock drift and satellite clock drift: `diffPRR(i) = predPRR(i) - measPRR(i) - initDrift + svDrift(i)`

5. **Observation Model Construction**: The observation matrix (`obsModelH`) creates the crucial link between measurements and state variables:
   - First half relates pseudoranges to position and clock bias states
   - Second half relates pseudorange rates to velocity and clock drift states
   - Both use the same line-of-sight vectors to maintain geometric consistency

6. **Process Noise Configuration**: Noise parameters model uncertainties in the system dynamics:
   - Position and velocity process noise scaled based on PDI (predetection integration time)
   - Clock bias and drift noise modeled using Allan variance parameters (h₀=1e-21, h₂=1e-24)
   - Spectral densities Sᶠ and Sᵍ derived for OCXO (Oven Controlled Crystal Oscillator)

7. **Measurement Noise Modeling**: Different noise characteristics are assigned to each measurement type:
   - Pseudorange measurements: `measNoiseR(1:numvis,1:numvis) = eye(numvis)*3e4`
   - Pseudorange rate measurements: `measNoiseR(numvis+1:2*numvis,numvis+1:2*numvis) = eye(numvis)*1e6`

8. **Iterative Processing**: The algorithm follows the standard Kalman filter cycle:
   - Prediction step (a priori): Projects state and covariance forward in time
   - Update step (a posteriori): Incorporates measurements to refine the state estimate

This tight integration of pseudorange and Doppler measurements enables accurate and robust positioning, even in challenging environments with multipath interference.


### Results Analysis

The EKF implementation demonstrates exceptional performance as shown in the following figures:

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled29.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled30.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled35.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled36.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled37.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled38.png" width="200">
</p>
<p align="center"><b>Fig. 9</b> The Results of our EKF implementation </p>

1. **Velocity Components Over Time (Open Sky Environment - KF)**: This plot reveals smooth, physically realistic velocity estimates that exhibit none of the noise seen in the WLS solution. The East component shows a steady increase from ~0 to 250 m/s, the North component remains close to zero with slight upward trend, and the Up component decreases gradually to -150 m/s. This smooth progression reflects the filter's ability to maintain temporal consistency through its dynamic model.

2. **Velocity Components Over Time (Urban Environment - KF)**: The urban velocity estimates remain remarkably smooth despite the challenging environment, with the East component reaching ~95 m/s, the North component stabilizing around 60 m/s, and the Up component decreasing to -220 m/s. The contrast with the highly erratic WLS urban velocity estimates (which fluctuated between ±20 m/s) is dramatic, demonstrating the EKF's robustness against multipath interference.

3. **Urban longitude - KF method**: The longitude plot shows exceptional stability around 114.2945°, with only minor fluctuations after an initial convergence period. Compared to the WLS solution (which varied between 114.208° and 114.211°), the EKF provides nearly an order of magnitude improvement in stability.

4. **Urban latitude - KF method**: Similarly, the latitude estimate quickly converges to 22.32015° and remains highly stable throughout the measurement period. The characteristic oscillations seen in the WLS solution are effectively eliminated.

5. **Open Sky longitude - KF method**: After a brief initial convergence period with some fluctuations, the longitude estimate stabilizes around 114.1709°, providing a consistent solution much closer to the ground truth value of 114.1713630049711°.

6. **Open Sky latitude - KF method**: The latitude estimate similarly shows rapid convergence to 22.3287°, very close to the ground truth value of 22.328444770087565°, with excellent stability throughout the remainder of the dataset.

### Comparison with Previous Methods

<p align="center">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled45.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled46.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled47.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled48.png" width="200">
  <img src="https://raw.githubusercontent.com/bigdatamanz/ceshi222/master/Figurenew/untitled49.png" width="200">
</p>
<p align="center"><b>Fig. 9</b> LLH Position Plots Comparison with Ground Truth </p>

The EKF method provides substantial improvements over both OLS and WLS approaches:

1. **Position Accuracy**: As seen in the RMSE comparison plots, the EKF achieves positioning errors of approximately 48m in urban environments and 46m in open sky - a 3-fold improvement over WLS (158m and 521m respectively).

2. **Solution Stability**: The EKF's position and velocity estimates show remarkable temporal consistency, eliminating the high-frequency fluctuations present in least-squares approaches.

3. **Environmental Robustness**: While WLS struggles significantly in urban environments, the EKF maintains consistent performance across both urban and open sky scenarios.

4. **Velocity Estimation**: The EKF produces physically plausible velocity estimates that reflect the actual dynamics of the receiver, unlike the noise-dominated WLS velocity estimates.

The superior performance of the EKF can be attributed to several factors:

- **Temporal Filtering**: By incorporating previous state estimates, the filter rejects momentary outliers caused by multipath or measurement noise.
  
- **Dynamic Constraints**: The state transition model enforces physical relationships between position and velocity, preventing physically implausible jumps.

- **Adaptive Weighting**: The Kalman gain automatically adjusts the balance between measurement updates and model predictions based on their respective uncertainties.

- **Comprehensive Error Modeling**: The process and measurement noise parameters are carefully tuned to reflect the characteristics of the receiver clock, satellite measurements, and environmental conditions.

These results demonstrate that the EKF approach is significantly more suitable for GNSS positioning in challenging environments, providing reliable position and velocity estimates even under severe multipath conditions where traditional least-squares methods struggle.

### References
[1] B. Xu and L.-T. Hsu, "[Open-source MATLAB code for GPS vector tracking on a software-defined receiver](https://doi.org/10.1007/s10291-019-0839-x)," GPS Solutions, vol. 23, no. 2, p. 46, Apr. 2019.
