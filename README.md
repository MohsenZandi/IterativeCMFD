# IterativeCMFD
Implementation of our paper titled "Iterative Copy-Move Forgery Detection based on a new Interest Point Detector"

if you use this code please cite this paper:
{
Zandi, Mohsen, Ahmad Mahmoudi-Aznaveh, and Alireza Talebpour. "Iterative copy-move
 forgery detection based on a new interest point detector." IEEE Transactions on
 Information Forensics and Security 11.11 (2016): 2499-2512.
}

Example: [mask,result,time]=DetectCopyMove('sample_forged.png');

Some parts of the implementation are in c++ using OpenCV library(version: 2.4.6). The compiled versions (MEX) are also included for 64 bit windows versions.

Requirements:
Matlab 2013 or newer
vl_feat 0.9.20
opencv 2.4.6 (opencv_core246.dll), must be compatibe with compiled MEX files (x86 or x64)