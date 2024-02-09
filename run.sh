#!/bin/bash
source /root/.bashrc
conda activate photonics
jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.password='' --NotebookApp.token=''