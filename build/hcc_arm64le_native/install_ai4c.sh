# !/bin/bash

cur_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

# Locate the .whl files to install.
ai4cglob=( $cur_dir/../lib64/AI4C/ai4c-*.whl )
opentunerglob=( $cur_dir/../lib64/AI4C/huawei_opentuner-*.whl )
autotunerglob=( $cur_dir/../lib64/AI4C/autotuner-*.whl )

python3=$(type -p python3)
$python3 -m pip install "${ai4cglob[-1]}"
$python3 -m pip install "${opentunerglob[-1]}"
$python3 -m pip install "${autotunerglob[-1]}"
$python3 -m pip install xgboost 
$python3 -m pip install scikit-learn
