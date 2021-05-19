#!/usr/bin/bash
set -e

## working directory for the training (we will create it if not present)
WORKDIR=/home/output

## input *.tif + *.box pairs should be there
TRAINING_DATA=/home/input

## base language
BASE_LANG=${BASE_LANG:-eng}

## learning rate
LEARNING_RATE=${LEARNING_RATE:-0.0001}

## max_iterations
MAX_ITERATIONS=${MAX_ITERATIONS:-10000}

## target error rate
TARGET_ERROR_RATE=${TARGET_ERROR_RATE:-0.01}

############################################################################
umask 0000;

mkdir -p ${WORKDIR}

exec > >(tee -a ${WORKDIR}/trainer.log) 2>&1

echo "*******************************************************************"
echo "*******************************************************************"
echo "BASE_LANG=${BASE_LANG}"
echo "LEARNING_RATE=${LEARNING_RATE}"
echo "MAX_ITERATIONS=${MAX_ITERATIONS}"
echo "TARGET_ERROR_RATE=${TARGET_ERROR_RATE}"
echo "*******************************************************************"

## make sure that base language was installed. If not, try installing.
if [ ! -f ${TESSDATA_PREFIX}/${BASE_LANG}.traineddata ]; then
    (
        echo "*** Downloading ${BASE_LANG} language model"
        cd /tmp
        wget https://github.com/tesseract-ocr/tessdata_best/raw/master/${BASE_LANG}.traineddata
        mv /tmp/${BASE_LANG}.traineddata ${TESSDATA_PREFIX}/
    )
fi

## Unpack base language model
combine_tessdata -u ${TESSDATA_PREFIX}/${BASE_LANG}.traineddata ${WORKDIR}/${BASE_LANG}

## Extract text from all ground truth examples
python3 -m text_from_box ${TRAINING_DATA}/*.box > ${WORKDIR}/all-text

## Analyse text and create "my.unicharset" file
unicharset_extractor --output_unicharset ${WORKDIR}/my.unicharset ${WORKDIR}/all-text

## Merge base charset with the "my.unicharset" and save as "unicharset"
merge_unicharsets ${WORKDIR}/${BASE_LANG}.lstm-unicharset ${WORKDIR}/my.unicharset  ${WORKDIR}/unicharset

## Pack TIF+BOX file into LSTMF file (for each training example)
mkdir -p ${WORKDIR}/data
for f in ${TRAINING_DATA}/*.tif
do
    x=`basename $f`
    tesseract $f ${WORKDIR}/data/$x --psm 6 lstm.train
done

## Split into eval/train sets
ls -1 ${WORKDIR}/data/*.lstmf | sort -R > ${WORKDIR}/all-lstmf

num_samples=`cat ${WORKDIR}/all-lstmf | wc -l`
echo "*** Collected ${num_samples} samples (total)"
num_eval=$((num_samples/5))
echo "*** Split into $num_eval evaluation and $((num_samples-num_eval)) training samples"

head -n $num_eval ${WORKDIR}/all-lstmf > ${WORKDIR}/list.eval
tail -n +$((num_eval+1)) ${WORKDIR}/all-lstmf > ${WORKDIR}/list.train

## Pack stuff into ${WORKDIR}/temp
cp /app/radical-stroke.txt ${WORKDIR}  # FIXME
combine_lang_model \
    --input_unicharset ${WORKDIR}/unicharset \
    --script_dir ${WORKDIR} \
    --output_dir ${WORKDIR} \
    --lang temp

## Start training
mkdir -p ${WORKDIR}/checkpoints
lstmtraining \
    --debug_interval 0 \
    --traineddata ${WORKDIR}/temp/temp.traineddata \
    --old_traineddata /usr/local/share/tessdata/${BASE_LANG}.traineddata \
    --continue_from ${WORKDIR}/${BASE_LANG}.lstm \
    --model_output ${WORKDIR}/checkpoints/temp \
    --train_listfile ${WORKDIR}/list.train \
    --eval_listfile ${WORKDIR}/list.eval \
    --learning_rate ${LEARNING_RATE} \
    --max_iterations ${MAX_ITERATIONS} \
    --target_error_rate ${TARGET_ERROR_RATE}

## Convert checkpoint to traineddata format (usable as a new language)
lstmtraining \
    --stop_training \
    --continue_from ${WORKDIR}/checkpoints/temp_checkpoint \
    --traineddata ${WORKDIR}/temp/temp.traineddata \
    --model_output ${WORKDIR}/trained.traineddata

echo "*** Ready-to-use language is in output/trained.traineddata"

exit 0