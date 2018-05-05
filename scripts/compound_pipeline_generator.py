#!/usr/bin/env python

from argparse import ArgumentParser, FileType
from os import path
from string import Template

PREAMBLE_FILENAME = 'preamble.cmake.in'
MIDDLE_FILENAME = 'middle.cmake.in'
POSTAMBLE_FILENAME = 'postamble.cmake.in'


class PipelineGenerator:
    def __init__(self, preamble, middle, postamble):
        self.preamble = Template(preamble)
        self.middle = Template(middle)
        self.postamble = Template(postamble)

    def generate(self, **kwargs):
        pass

    # print template.substitute(kwargs)


if __name__ == '__main__':
    parser = ArgumentParser(description='Generate CMake compound pipeline')
    parser.add_argument(
        '-t',
        dest='templatedir',
        required=True,
        help='path to the template dir')
    parser.add_argument(
        '-f',
        type=FileType('w'),
        dest='file',
        # required=True,
        help='file name of output')
    parser.add_argument(
        '-c',
        dest='compound_pipeline',
        # required=True,
        help='name of compound pipeline')
    parser.add_argument(
        '-p',
        dest='pipelines',
        # required=True,
        help='semicolon-separated list of pipelines')

    args = vars(parser.parse_args())

    #

    fname = path.abspath(args['templatedir'] + '/' + PREAMBLE_FILENAME)
    preamble = open(fname).read()

    fname = path.abspath(args['templatedir'] + '/' + MIDDLE_FILENAME)
    middle = open(fname).read()

    fname = path.abspath(args['templatedir'] + '/' + POSTAMBLE_FILENAME)
    postamble = open(fname).read()

    g = PipelineGenerator(preamble, middle, postamble)