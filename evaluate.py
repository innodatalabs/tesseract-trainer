import glob
from text_from_box import text_from_box
from PIL import Image
import contextlib
from difflib import SequenceMatcher as SQ
import pytesseract
import os


@contextlib.contextmanager
def open_image(basename):
    for suffix in ['.png', '.tif', '.jpeg', '.jpg']:
        if os.path.isfile(basename + suffix):
            with Image.open(basename + suffix) as im:
                yield im
            break
    else:
        raise RuntimeError(f'No image file found with base name {basename}')

def character_distance(text1, text2):
    distance = 0
    for tag, i1,i2, j1,j2 in SQ(None, text1, text2).get_opcodes():
        if tag != 'equal':
            distance += max(i2-i1, j2-j1)
    return distance

def metric(gold, ocr):
    dist = character_distance(ocr, gold)
    precision = 0
    if len(ocr) > 0:
        precision = (max(len(gold), len(ocr))-dist) / len(ocr)

    recall = 0
    if len(gold) > 0:
        recall = (max(len(gold), len(ocr))-dist) / len(gold)

    assert precision >= 0 and precision <= 1
    assert recall >= 0 and recall <= 1

    return {
        'dist': dist,
        'f1': 2 * precision * recall / (precision + recall + 1.e-8),
    }


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Computes evaluation statistics')
    parser.add_argument('lang', help='language to use')
    parser.add_argument('filelist', help='Files containing paths of files to evaluate')
    parser.add_argument('input_dir', help='Directory with the input images and box files')
    parser.add_argument('--psm', default='6', help='PSM flag passed to tesseract engine')

    args = parser.parse_args()

    total_gold = 0
    total_ocr = 0
    total_dist = 0
    total_f1 = 0.
    count = 0

    with open(args.filelist, 'r', encoding='utf-8') as f:
        files = [l.strip() for l in f]

    for fname in files:
        print(fname)
        assert fname.endswith('.tif.lstmf'), fname
        fname = os.path.basename(fname[:-10])
        gold = text_from_box(f'{args.input_dir}/{fname}.box')
        with open_image(f'{args.input_dir}/{fname}') as img:
            ocr = pytesseract.image_to_string(img, lang=args.lang, config=f'--psm {args.psm}')
        m = metric(gold, ocr)
        total_f1 += m['f1']
        count += 1
        total_dist += m['dist']
        total_gold += len(gold)
        total_ocr += len(ocr)

    precision = (max(total_gold, total_ocr)-total_dist) / (total_ocr + 1e-8)
    recall = (max(total_gold, total_ocr)-total_dist) / (total_gold + 1e-8)

    print(f'Evaluation on {count} images:')
    print(f'    F1 (micro): {total_f1 / count}')
    print(f'    F1 (macro): {2*precision*recall/(precision+recall+1e-8)}')
    print(f'    Gold length: {total_gold}')
    print(f'    OCR length: {total_ocr}')
    print(f'    Distance: {total_dist}')
