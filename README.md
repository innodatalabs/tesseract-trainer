# tesseract-trainer

Yet another docker to train Tesseract v4.1.1.

## Overview

* Prepare training data

* Put training data into directory named `input`

* Run docker to train on `input`. Intermediate files and result will
  be placed in the `output` directory

* Profit

## Limitations

* We only do fine-tuning on top of Western languages. Indic, Hebrew,
  Arabic, CJK were not tested and might not work as expected.

* Must prepare *.box files yourself. This repo does not provide any
  tooling for that

* Input images must be in *.tif format. One can use ImagMagic's `convert`
  utility to do the bulk conversion like this:
  ```bash
  for f in *.png; do convert $f ${f%.*}.tif; done
  ```

* Use hardcoded `--psm 6` configuration for training and evaluation. Again,
  one can hack the code to use other settings if needed, see below.

## Prepare training data

Training data for Tesseract v4.1.1 (LSTM) is a set of file pairs:

* TIF: a file with extension `*.tif` containing the image
* BOX: a file with the same name and extension `*.box` containing the
  labeling

Create a directory named `input` (name is important!) and copy all
training files there.

## Run the docker command to train the language

Make sure that there is no directory named `output/` in your current folder.

If you have previous runs, delete it to start training from scratch. If
you leave `output/` folder present, Tesseract will attempt to restart
training from the last saved checkpoint. This will not do much good unless
you are Ray Smith and know what you are doing :P.

From the directory containing the `input/` folder, run this:

```bash
docker run -v $PWD:/home -it mkroutikov/tesseract-trainer
```

Expect it to create `output/` folder and start training.

Once training is completed, the best checkpoint will be packed as
Tesseract langage file named `output/trained.traineddata`. Move it
to the location of tesseract languages (and rename). You now have
the new language available!

## Sample session
This repository proivides a set of sample training files.

To run a sample training session do this:

```bash
git clone git@github.com:innodatalabs/tesseract-trainer.git
cd tesseract-trainer/sample
docker run -v $PWD:/home -it mkroutikov/tesseract-trainer
```

## Configure training parameters

The following training parameters can be configured with via
docker environment variables:

|--------------------------------------------|
| Envirnment variable | Default | Description|
|--------------------------------------------|
| BASE_LANG           | eng     | Base language model (we use "best", not "fast" |
| LEARNING_RATE       | 0.0001  | Learning rate |
| MAX_ITERATIONS       | 10000  | Limit on the total number of traiing iterations |
| TARGET_ERROR_RATE | 0.01 | Target error rate |
|----------------------------------------------|

Example of training for 20000 iterations:
```bash
docker run -e MAX_ITERATIONS=20000 \
    -v $PWD:/home \
    -it \
    mkroutikov/tesseract-trainer
```

## Hacking

The actual training script is located at `/app/trainer.sh` in the docker
image.

You can run training from within the docker image like this:

```bash
docker run -v $PWD:/home -it mkroutikov/tesseract-trainer bash
bash /app/trainer.sh
...
exit
```

You can also edit training script before running. Once you inside the docker
open it in your favorite editor (vi), and look for the block of code like this:

```bash
for f in ${TRAINING_DATA}/*.tif
do
    x=`basename $f`
    tesseract $f ${WORKDIR}/data/$x --psm 6 lstm.train
done
```
Here you can change the `--psm` setting if needed.

Similarly, you can look for other hardcoded values and
change them. Script is relatively small and well-documented.

## Links
