#!/bin/bash

cp ./configure.sh /tmp
rm -rf ./*
cp /tmp/configure.sh ./

module purge
module load cmake cuda/10.1 kokkos/serial_omp_cuda

cmake ../ \
  -DCMAKE_CXX_COMPILER=nvcc_wrapper \
  -DMG_USE_CUDA=true \
  -DQDPXX_DIR=/home/pvelesko/local/qdpxxRecursive/build \
  -DCMAKE_WARN_DEPRECATED=false
