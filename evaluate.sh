#!/usr/bin/bash
set -xe

## working directory for the training (we will create it if not present)
WORKDIR=/home/output

## make tesseract see the new language named "trained"
cp ${WORKDIR}/trained.traineddata ${TESSDATA_PREFIX}/

python3 -m evaluate ${EVAL_LANG:-trained} ${WORKDIR}/list.eval /home/input

