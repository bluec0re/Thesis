#!/usr/bin/env python
# encoding: utf-8

from pathlib import Path
from collections import namedtuple

Doc = namedtuple('Doc', 'name, description, syntax, inputs, outputs')


def get_doc(lines):
    docs = []
    for line in lines:
        if line.startswith('%'):
            docs.append(line[1:].strip())
        else:
            break
    return docs


def get_name(docs):
    return docs[0].split(' ')[0]


def get_description(docs):
    description = docs[0].split(' ', 1)[1]
    for d in docs[1:]:
        if not d:
            break
        description += d
    return description


def get_syntax(docs):
    for d in docs:
        if 'Syntax:' in d:
            return d.replace('Syntax:', '').strip()


def get_puts(docs, type):
    found = False
    inputs = {}
    current = None
    for d in docs:
        if found:
            if not d:
                break
            if '-' in d:
                current = d.split('-')[0].strip()
                inputs[current] = d.split('-', 1)[1].strip()
            elif current:
                inputs[current] += d
        elif type in d:
            found = True
    return inputs


def parse_doc(f):
    with f.open() as fp:
        content = fp.read()

    lines = list(map(lambda x: x.strip(), content.split('\n')))
    function_found = False
    result = []
    for i, line in enumerate(lines):
        if function_found:
            docs = get_doc(lines[i:])
            if docs:
                name = get_name(docs)
                syntax = get_syntax(docs)
                description = get_description(docs)
                inputs = get_puts(docs, 'Input:')
                outputs = get_puts(docs, 'Output:')

                # print("Name:", name)
                # print("Syntax:", syntax)
                # print("Description:", description)
                # print("Inputs:", inputs)
                # print("Outputs:", outputs)
                result.append(Doc(name, description, syntax, inputs, outputs))
            function_found = False
        elif line.startswith('function'):
            function_found = True
    return result


if __name__ == '__main__':
    import sys

    result = []
    for f in Path(sys.argv[1]).glob('**/*.m'):
        result += parse_doc(f)

    for r in result:
        if None in r:
            continue

        s = r"""
\subsection{%(name)s}

%(description)s

\paragraph{Syntax:} \verb|%(syntax)s|
""" % {k: v.replace('_', '\\_') if k in ('name', 'description') else v for k, v in r._asdict().items()}

        if r.inputs:
            s += r"""
\bigskip
Inputs:

\begin{tabular}{|p{0.4\textwidth}|p{0.6\textwidth}|}
\hline
\textbf{Name} & \textbf{Description} \\
\hline \hline
"""
            for n, d in r.inputs.items():
                s += r"""%s & %s  \\ \hline
""" % (n.replace('_', r'\_'), d.replace('_', r'\_'))
            s += "\\end{tabular}\n"

        if r.outputs:
            s += r"""
\bigskip
Outputs:

\begin{tabular}{|p{0.4\textwidth}|p{0.6\textwidth}|}
\hline
\textbf{Name} & \textbf{Description} \\
\hline \hline
"""
            for n, d in r.outputs.items():
                s += r"""%s & %s  \\ \hline
""" % (n.replace('_', '\\_'), d.replace('_', '\\_'))
            s += r"\end{tabular}"

        print(s)
