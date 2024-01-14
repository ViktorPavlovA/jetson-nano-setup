#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export OCV_BUILD_CUDA_CC=5.3
export OCV_BUILD_PYTHON_V=3.6
export OCV_BUILD_PYTHON_PACK_PATH=/usr/local/lib/python3.6/dist-packages/
export OCV_BUILD_PYTHON_BIN_PATH=/usr/bin/python3


# CUDA & OPENCV
sudo apt update
sudo apt install -y cmake-data=3.10.2-1ubuntu2 libcairo2=1.15.10-2 libcairo-gobject2=1.15.10-2 \
              libxcb-shm0=1.13-1 libxkbcommon0=0.8.0-1ubuntu0.1 libgtk-3-0=3.22.30-1ubuntu1 \
              gir1.2-gtk-3.0=3.22.30-1ubuntu1 libcanberra-gtk-module 
sudo apt install -y smbclient wget cmake build-essential libprotobuf-dev protobuf-compiler \
                    libgl1-mesa-glx ffmpeg libsdl-image1.2-dev libportmidi-dev \
                    libswscale-dev libavformat-dev libavcodec-dev libfreetype6-dev  \
                    libsdl-mixer1.2-dev libsdl-ttf2.0-dev libsdl1.2-dev libsmpeg-dev \
                    unzip libfaac-dev libavresample-dev gfortran libblas-dev \
                    libgoogle-glog-dev checkinstall x264 libjpeg-dev libdc1394-22-dev \
                    libvorbis-dev libv4l-dev libx264-dev libpng-dev libopenblas-dev\
                    v4l-utils python3-pip python3-numpy libopencore-amrwb-dev \
                    libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev libxine2-dev \
                    libtheora-dev yasm libmp3lame-dev libatlas-base-dev libhdf5-dev \
                    libgtk2.0-dev gstreamer1.0-tools libtbb2 libgflags-dev \
                    libprotobuf-dev git libxvidcore-dev python3.6-dev libgtk-3-dev \
                    libtbb-dev liblapack-dev libtiff-dev libeigen3-dev \
                    libavcodec-dev libopencore-amrnb-dev \
                    libavformat-dev libswscale-dev libdc1394-22 pkg-config \
                    protobuf-compiler python-dev libsdl-image1.2-dev libsdl-mixer1.2-dev \
                    libsdl-ttf2.0-dev libsdl1.2-dev libsmpeg-dev python-numpy subversion \
                    libportmidi-dev ffmpeg libswscale-dev libavformat-dev \
                    libavcodec-dev libfreetype6-dev libdbus-1-dev libdbus-glib-1-dev \
		    build-essential libssl-dev libffi-dev python-dev

sudo ln -s /usr/bin/python3 /usr/bin/python
python3 -m pip install --upgrade pip setuptools
sudo python3 -m pip install pytest pyyaml Jetson.GPIO umodbus wheel onnx==1.4.1 numpy==1.19.3 
sudo python3 -m pip install --global-option=build_ext --global-option="-I/usr/local/cuda/targets/aarch64-linux/include/" --global-option="-L/usr/local/cuda/targets/aarch64-linux/lib/" pycuda==2020.1 
python3 -m pip install -U protobuf
python3 -m pip install -U --ignore-installed PyYAML
python3 -m pip install pygame==1.9.6

echo "export PATH=/usr/local/cuda/bin:$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc

# install opencv with support cuda

mkdir -p ~/dev/general/opencv-build && cd ~/dev/general/opencv-build
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.5.3.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.5.3.zip
unzip -q opencv.zip
unzip -q opencv_contrib.zip
rm -f opencv_contrib.zip opencv.zip
cd opencv-4.5.3
mkdir build && cd build

cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local/ \
      -D WITH_TBB=ON \
      -D BUILD_TBB=ON \
      -D ENABLE_FAST_MATH=ON \
      -D CUDA_FAST_MATH=ON \
      -D WITH_CUBLAS=ON \
      -D WITH_CUDA=ON \
      -D WITH_CUDNN=ON \
      -D OPENCV_DNN_CUDA=ON \
      -D CUDA_ARCH_BIN=$OCV_BUILD_CUDA_CC \
      -D WITH_V4L=ON \
      -D WITH_QT=OFF \
      -D WITH_OPENGL=ON \
      -D WITH_GSTREAMER=ON \
      -D OPENCV_GENERATE_PKGCONFIG=ON \
      -D OPENCV_PC_FILE_NAME=opencv4.pc \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D OPENCV_PYTHON3_INSTALL_PATH=$OCV_BUILD_PYTHON_PACK_PATH \
      -D PYTHON_EXECUTABLE=$OCV_BUILD_PYTHON_BIN_PATH \
      -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.5.3/modules \
      -D INSTALL_PYTHON_EXAMPLES=OFF \
      -D INSTALL_C_EXAMPLES=OFF \
      -D BUILD_EXAMPLES=OFF \
      -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
      -D WITH_OPENCL=OFF \
      -D CUDA_ARCH_PTX="" \
      -D WITH_OPENMP=ON \
      -D BUILD_TIFF=ON \
      -D WITH_FFMPEG=ON \
      -D BUILD_TESTS=OFF \
      -D WITH_EIGEN=ON \
      -D WITH_LIBV4L=ON ..

make -j$(nproc)

sudo make install

sudo ldconfig -v
# test opencv with for python and c 
python3 -c "import cv2; print('Opencv with cuda install in python3: {}'.format(cv2.cuda.getCudaEnabledDeviceCount()))"
cd 
echo '#include <iostream>
using namespace std;

#include <opencv2/core.hpp>
using namespace cv;

#include <opencv2/cudaarithm.hpp>
using namespace cv::cuda;

int main()
{
    printShortCudaDeviceInfo(getDevice());
    int cuda_devices_number = getCudaEnabledDeviceCount();
    cout << "Opencv for C++ "<< endl;
    cout << "CUDA Device(s) Number: "<< cuda_devices_number << endl;
    DeviceInfo _deviceInfo;
    bool _isd_evice_compatible = _deviceInfo.isCompatible();
    cout << "CUDA Device(s) Compatible: " << _isd_evice_compatible << endl;
    return 0;
}' > main.cpp

export FLAGS="$(pkg-config opencv4 --libs --cflags)"

g++ main.cpp -o test $FLAGS
./test
rm -f main.cpp test.o

# HELPFULL package 

pip3 install shapely==1.8.5.post1 filterpy==1.4.5 numpy==17.0.0 jetson-stats opencv-python==4.5.4.60 opencv-contrib-python==4.5.4.60  
sudo apt-get install libgeos-dev



# Visual style of console


echo -e '\n# <<< GIT VIEW <<<' >> ~/.bashrc
echo '# Adaptation of' >> ~/.bashrc
echo '# - functions from https://dev.to/vuong/let-s-add-cygwin-into-windows-terminal-and-customize-it-for-development-looks-1hp8' >> ~/.bashrc
echo '# - prompt arrangement from https://gist.github.com/justintv/168835#gistcomment-3554316' >> ~/.bashrc
echo -e '\nfunction __short_wd_cygwin() ' >> ~/.bashrc
echo '{' >> ~/.bashrc
echo '    num_dirs=3' >> ~/.bashrc
echo '    newPWD="${PWD/#$HOME/~}"' >> ~/.bashrc
echo '    if [ $(echo -n $newPWD | awk -F \'/\' \'{print NF}\') -gt $num_dirs ]; then' >> ~/.bashrc
echo '        newPWD=$(echo -n $newPWD | awk -F \'/\' \'{print $1 "/.../" $(NF-1) "/" $(NF)}')' >> ~/.bashrc
echo '    fi' >> ~/.bashrc
echo -e '\n    echo -n $newPWD' >> ~/.bashrc
echo '}' >> ~/.bashrc
echo -e '\nfunction __short_wd_cygpath() ' >> ~/.bashrc
echo '{' >> ~/.bashrc
echo '    num_dirs=3' >> ~/.bashrc
echo '    newPWD=$(cygpath -C ANSI -w ${PWD/#$HOME/~})' >> ~/.bashrc
echo '    if [ $(echo -n $newPWD | awk -F \'\\\' \'{print NF}\') -gt $num_dirs ]; then' >> ~/.bashrc
echo '        newPWD=$(echo -n $newPWD | awk -F \'\\\' \'{print $1 "\\...\\" $(NF-1) "\\" $(NF)}')' >> ~/.bashrc
echo '    fi' >> ~/.bashrc
echo -e '\n    echo -n $newPWD' >> ~/.bashrc
echo '}' >> ~/.bashrc
echo -e '\nFFMT_BOLD="\[\e[1m\]"' >> ~/.bashrc
echo 'FMT_DIM="\[\e[2m\]"' >> ~/.bashrc
echo 'FMT_RESET="\[\e[0m\]"' >> ~/.bashrc
echo 'FMT_UNBOLD="\[\e[22m\]"' >> ~/.bashrc
echo 'FMT_UNDIM="\[\e[22m\]"' >> ~/.bashrc
echo 'FG_BLACK="\[\e[30m\]"' >> ~/.bashrc
echo 'FG_BLUE="\[\e[34m\]"' >> ~/.bashrc
echo 'FG_CYAN="\[\e[36m\]"' >> ~/.bashrc
echo 'FG_GREEN="\[\e[32m\]"' >> ~/.bashrc
echo 'FG_GREY="\[\e[37m\]"' >> ~/.bashrc
echo 'FG_MAGENTA="\[\e[35m\]"' >> ~/.bashrc
echo 'FG_RED="\[\e[31m\]"' >> ~/.bashrc
echo 'FG_WHITE="\[\e[97m\]"' >> ~/.bashrc
echo 'BG_BLACK="\[\e[40m\]"' >> ~/.bashrc
echo 'BG_BLUE="\[\e[44m\]"' >> ~/.bashrc
echo 'BG_CYAN="\[\e[46m\]"' >> ~/.bashrc
echo 'BG_GREEN="\[\e[42m\]"' >> ~/.bashrc
echo 'BG_MAGENTA="\[\e[45m\]"' >> ~/.bashrc
echo -e '\nexport PS1=\\' >> ~/.bashrc
echo '"\n${FG_BLUE}╭─${FG_MAGENTA}◀${BG_MAGENTA}${FG_CYAN}${FMT_BOLD}\d ${FG_WHITE}\t${FMT_UNBOLD} ${FG_MAGENTA}${BG_BLUE}▶ "' >> ~/.bashrc
echo '"${FG_GREY}\$(__short_wd_cygwin) ${FG_BLUE}${BG_CYAN}▶ "' >> ~/.bashrc
echo '"${FG_BLACK}📂 \$(find . -mindepth 1 -maxdepth 1 -type d | wc -l) "' >> ~/.bashrc
echo '"📄 \$(find . -mindepth 1 -maxdepth 1 -type f | wc -l) "' >> ~/.bashrc
echo '"🔗 \$(find . -mindepth 1 -maxdepth 1 -type l | wc -l) "' >> ~/.bashrc
echo '"${FMT_RESET}${FG_CYAN}"' >> ~/.bashrc
echo '"\$(git branch 2> /dev/null | grep '\''^*'\'' | colrm 1 2 | xargs -I BRANCH echo -n \"${BG_GREEN}▶${FG_BLACK}🔀 BRANCH ${FMT_RESET}${FG_GREEN}\")"' >> ~/.bashrc
echo -e '"\n${FG_BLUE}╰▶${FG_CYAN}🤖 ${FMT_RESET}"' >> ~/.bashrc
echo -e '\nalias reboot='\''sudo reboot'\''' >> ~/.bashrc
echo 'alias poweroff='\''sudo poweroff'\''' >> ~/.bashrc
echo 'alias pm-hibernate='\''sudo pm-hibernate'\''' >> ~/.bashrc
echo 'alias hibernate='\''sudo pm-hibernate'\''' >> ~/.bashrc
echo 'alias shutdown='\''sudo shutdown'\''' >> ~/.bashrc


