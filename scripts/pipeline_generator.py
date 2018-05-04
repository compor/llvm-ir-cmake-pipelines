#!/usr/bin/env python

from string import Template

template_str = """
${pipeline}(DEPENDS $${EXAMPLE_NAME}
    MAIN_TARGET PLINE_FOO_TRGT1
    TARGET_LIST PLINE_FOO_TRGTS)
"""


def generate_pipeline():
    template = Template(template_str)
    message = template.substitute(pipeline='loopc14n')
    print message


if __name__ == '__main__':
    generate_pipeline()
