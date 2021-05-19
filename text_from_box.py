
def text_from_box(boxfile):
    '''Reads Tesseract *.box file and returns its text string'''
    with open(boxfile, encoding='utf-8') as f:
        value = ''.join(l[0] for l in f)
    value = value.replace('\t', '\n').strip()

    return value

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Extracts text from tesseract BOX file')
    parser.add_argument('boxfile', nargs='+', help='One or more *.box files')

    args = parser.parse_args()

    for boxfile in args.boxfile:
        print(text_from_box(boxfile))
