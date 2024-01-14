#!/bin/bash

wget https://github.com/llvm/llvm-project/releases/download/llvmorg-9.0.1/llvm-9.0.1.src.tar.xz
tar -xvf llvm-9.0.1.src.tar.xz
cd llvm-9.0.1.src
mkdir llvm_build_dir
cd llvm_build_dir/
cmake ../ -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="ARM;X86;AArch64"
make -j4
sudo make install
cd bin/
echo "export LLVM_CONFIG=\""`pwd`"/llvm-config\"" >> ~/.bashrc
echo "alias llvm='"`pwd`"/llvm-lit'" >> ~/.bashrc
source ~/.bashrc
sudo pip3 install llvmlite

cd ../../..
rm -r llvm_build_dir


git clone https://github.com/wjakob/tbb.git
cd tbb/build
cmake ..
make -j4
sudo make install

cd ../..

rm -r tbb

sudo pip3 install llvmlite==0.30.0

pip3 install numba