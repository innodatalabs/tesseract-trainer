#!/usr/bin/bash
set -e

## working directory for the training (we will create it if not present)
WORKDIR=/home/output
EVAL_LANG=${EVAL_LANG:-trained}

exec > >(tee -a ${WORKDIR}/evaluate.log) 2>&1

echo "****************************************************************"
echo "****************************************************************"
echo "EVAL_LANG=${EVAL_LANG}"
echo "****************************************************************"

## make tesseract see the new language named "trained"
cp ${WORKDIR}/trained.traineddata ${TESSDATA_PREFIX}/

## make sure that base language was installed. If not, try installing.
if [ ! -f ${TESSDATA_PREFIX}/${EVAL_LANG}.traineddata ]; then
    (
        echo "*** Downloading ${EVAL_LANG} language model"
        cd /tmp
        wget https://github.com/tesseract-ocr/tessdata_best/raw/master/${EVAL_LANG}.traineddata
        mv /tmp/${EVAL_LANG}.traineddata ${TESSDATA_PREFIX}/
    )
fi

python3 -m evaluate ${EVAL_LANG} ${WORKDIR}/list.eval /home/input

