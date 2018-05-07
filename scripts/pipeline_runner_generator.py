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

from argparse import ArgumentParser
from os import path
from string import Template

REPEAT_FILENAME = 'runner.repeat.cmake.in'


class CMakePipelineRunnerGenerator:
    """A CMake lists file generator.

    This generator uses three :class:`string` templates to assemble and
    generate a CMake lists file. The template parts are:

        - a repeat template

    The repeat template is repeated N times, where N is the number of items in
    the comma-separated list provided to the 'pipelines' substitution mapping.

    The required mappings for each section are exposed by the following
    data attributes:

        - repeat_placeholders

    The templating used is based on Python's :class:`string.Template`.
    """

    repeat_placeholders = frozenset(['pipelines', 'depends'])

    def __init__(self, repeat):
        """Create a new generator.

        :param string repeat: The repeat template.
        """

        self.repeat = Template(repeat)

    def generate(self, **kwargs):
        """Generate :class:`string` by applying substitutions to the template
        parts.

        :param kwargs: The required mappings for the template placeholders.

        :return string: The substituted text.

        :raises: :class:`ValueError`, :class:`KeyError`
        """

        pipelines = kwargs['pipelines'].split(';')

        for e in pipelines:
            if not len(e):
                raise ValueError('Pipeline name is empty')

        unique_pipelines = {x for x in pipelines}
        if not len(unique_pipelines) == len(pipelines):
            raise ValueError('Pipeline specified more than once')

        text = ""
        for pline in pipelines:
            text += self.repeat.substitute({
                'pipeline': pline,
                'depends': kwargs['depends']
            })

        return text


if __name__ == '__main__':
    parser = ArgumentParser(description='Generate CMake compound pipeline')
    parser.add_argument(
        '-t',
        dest='templatedir',
        required=True,
        help='Path to the template dir')
    parser.add_argument(
        '-p',
        dest='pipelines',
        required=True,
        help='Semicolon-separated list of pipelines')
    parser.add_argument(
        '-d',
        dest='depends',
        required=True,
        help='Name of entry target to attach to')
    parser.add_argument(
        '-f',
        dest='file',
        help='File name of output. Use stdout if not specified')

    args = vars(parser.parse_args())

    #

    fname = path.abspath(args['templatedir'] + '/' + REPEAT_FILENAME)
    repeat = open(fname).read()

    g = CMakePipelineRunnerGenerator(repeat)
    txt = g.generate(pipelines=args['pipelines'], depends=args['depends'])

    outfile = sys.stdout
    if args['file']:
        outfile = open(args['file'], 'w')

    outfile.write(txt)
