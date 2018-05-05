#!/usr/bin/env python

import sys

from argparse import ArgumentParser, FileType
from os import path
from string import Template

PREAMBLE_FILENAME = 'preamble.cmake.in'
MIDDLE_FILENAME = 'middle.cmake.in'
POSTAMBLE_FILENAME = 'postamble.cmake.in'


class PipelineGenerator:
    preamble_placeholders = {'compound_pipeline'}
    middle_placeholder = 'pipelines'
    postamble_placeholders = {}

    def __init__(self, preamble, middle, postamble):
        self.preamble = Template(preamble)
        self.middle = Template(middle)
        self.postamble = Template(postamble)

    def generate(self, **kwargs):
        text = self.preamble.substitute(
            {k: kwargs[k]
             for k in kwargs if k in self.preamble_placeholders})

        middle_subs = {
            'pipeline': None,
            'depends': None,
            'output_target': None
        }

        pipelines = kwargs[self.middle_placeholder].split(';')

        middle_subs['pipeline'] = pipelines[0]
        middle_subs['depends'] = 'TRGT0'
        middle_subs['output_target'] = 'OUT_TRGT0'
        text += self.middle.substitute(middle_subs)

        pipelines = pipelines[1:]

        for i, pline in enumerate(pipelines):
            middle_subs['pipeline'] = pline
            middle_subs['depends'] = 'OUT_TRGT{}'.format(i)
            middle_subs['output_target'] = 'OUT_TRGT{}'.format(i + 1)
            text += self.middle.substitute(middle_subs)

        text += self.postamble.substitute(
            {k: kwargs[k]
             for k in kwargs if k in self.postamble_placeholders})

        return text


if __name__ == '__main__':
    parser = ArgumentParser(description='Generate CMake compound pipeline')
    parser.add_argument(
        '-t',
        dest='templatedir',
        required=True,
        help='path to the template dir')
    parser.add_argument(
        '-c',
        dest='compound_pipeline',
        required=True,
        help='name of compound pipeline')
    parser.add_argument(
        '-p',
        dest='pipelines',
        required=True,
        help='semicolon-separated list of pipelines')
    parser.add_argument(
        '-f', type=FileType('w'), dest='file', help='file name of output')

    args = vars(parser.parse_args())

    #

    fname = path.abspath(args['templatedir'] + '/' + PREAMBLE_FILENAME)
    preamble = open(fname).read()

    fname = path.abspath(args['templatedir'] + '/' + MIDDLE_FILENAME)
    middle = open(fname).read()

    fname = path.abspath(args['templatedir'] + '/' + POSTAMBLE_FILENAME)
    postamble = open(fname).read()

    g = PipelineGenerator(preamble, middle, postamble)
    txt = g.generate(
        compound_pipeline=args['compound_pipeline'],
        pipelines=args['pipelines'])

    outfile = args['file']
    if not outfile:
        outfile = sys.stdout

    outfile.write(txt)
