# ezBIDS
The cloud-based graphical user interface for automated DICOM to BIDS data ingestion

### About
This is the developmental repo for an automated [BIDS](https://bids.neuroimaging.io/) converter web service that allows users to upload a directory containing 
DICOM files, and analyze the directory structure and sidecars generated from dcm2niix in order to *infer* 
as much information about the data structure as possible. Users are then asked to verify/modify
those assumptions before generating the final BIDS structure. Users do not need to organize their DICOM directory in any specific manner. 

In lieu of DICOMs, users may instead upload a directory containing the NIFTI/JSON files generated by dcm2niix, if they do not have access to the original DICOMs.

Unlike other automated DICOM to BIDS converters, ezBIDS eliminates the need for the command line and heuristic/configuration setup.

Furthermore, ezBIDS provides options for the defacing of anatomical acquisitions.

The BIDS output can be downloaded back to the user's computer, or uploaded to open repositories such as
[OpenNeuro](https://openneuro.org/), or [brainlife.io](https://brainlife.io/)

ezBIDS accepts DICOMS from the three major MRI vendors: **Siemens**, **GE**, and **Phillips**


### Usage
To access the ezBIDS web service, please visit https://brainlife.io/ezbids (Chrome or Firefox broswer preferred).


### Authors
- [Soichi Hayashi](soichih@gmail.com)
- [Daniel Levitas](dlevitas@iu.edu)
- [Franco Pestilli](pestilli@utexas.edu)

### Funding Acknowledgement
brainlife.io is publicly funded and for the sustainability of the project it is helpful to Acknowledge the use of the platform. We kindly ask that you acknowledge the funding below in your code and publications. Copy and past the following lines into your repository when using this code.

[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations
We ask that you the following articles when publishing papers that used data, code or other resources created by the brainlife.io community.

1. Avesani, P., McPherson, B., Hayashi, S. et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). [https://doi.org/10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

Copyright © 2020 brainlife.io at University of Texas at Austin and Indiana University

