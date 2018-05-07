#!/usr/bin/env python
"""Command-line utility that generates CMake list files based on templates.

The main intended usage is to generate CMake list files that describe compound
targets consisting of simpler ones described in a specific linear order (aka
pipeline) during configuration.

The output is dependent on the actual contents of the templates used, but at a
high-level, it generates a function that attaches dependent targets to a given
target passed as an argument. The dependence order of these targets is the one
used to specify the individual simpler target functions.

For more information check the command line option for help: ``[-h, -help]``).
"""

import sys

from argparse import ArgumentParser, FileType
from os import path
from string import Template

PREAMBLE_FILENAME = 'preamble.cmake.in'
MIDDLE_FILENAME = 'middle.cmake.in'
POSTAMBLE_FILENAME = 'postamble.cmake.in'


class CMakeCompoundPipelineGenerator:
    """A CMake lists file generator.

    This generator uses three :class:`string` templates to assemble and
    generate a CMake lists file. The template parts are:

        - a preamble template
        - a middle template
        - a postamble template

    The preamble and postamble templates are used once per generation and
    correspond to the parts of the generated file with the same name. The
    middle part is repeated N times, where N is the number of items in the
    comma-separated list provided to the 'pipelines' substitution mapping.

    The required mappings for each section are exposed by the following
    data attributes:

        - preamble_placeholders
        - middle_placeholder
        - postamble_placehodlers

    The templating used is based on Python's :class:`string.Template`.
    """

    preamble_placeholders = {'compound_pipeline'}
    middle_placeholder = 'pipelines'
    postamble_placeholders = {}

    def __init__(self, preamble, middle, postamble):
        """Create a new generator.

        :param string preamble: The preamble template.
        :param string middle: The middle template.
        :param string postamble: The postamble template.
        """
        self.preamble = Template(preamble)
        self.middle = Template(middle)
        self.postamble = Template(postamble)

    def generate(self, **kwargs):
        """Generate :class:`string` by applying substitutions to the template
        parts.

        :param kwargs: The required mappings for the template placeholders.

        :return string: The substituted text.
        """
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
        help='Path to the template dir')
    parser.add_argument(
        '-c',
        dest='compound_pipeline',
        required=True,
        help='Name of compound pipeline')
    parser.add_argument(
        '-p',
        dest='pipelines',
        required=True,
        help='Semicolon-separated list of pipelines')
    parser.add_argument(
        '-f',
        type=FileType('w'),
        dest='file',
        help='File name of output. Use stdout if not specified')

    args = vars(parser.parse_args())

    #

    fname = path.abspath(args['templatedir'] + '/' + PREAMBLE_FILENAME)
    preamble = open(fname).read()

    fname = path.abspath(args['templatedir'] + '/' + MIDDLE_FILENAME)
    middle = open(fname).read()

    fname = path.abspath(args['templatedir'] + '/' + POSTAMBLE_FILENAME)
    postamble = open(fname).read()

    g = CMakeCompoundPipelineGenerator(preamble, middle, postamble)
    txt = g.generate(
        compound_pipeline=args['compound_pipeline'],
        pipelines=args['pipelines'])

    outfile = args['file']
    if not outfile:
        outfile = sys.stdout

    outfile.write(txt)
