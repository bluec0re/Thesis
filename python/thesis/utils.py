import sys
from collections import namedtuple


BoundingBox = namedtuple('BoundingBox', 'x_min, y_min, x_max, y_max')
Result = namedtuple('Result', 'fileid, score, bbox')


def get_mean(in_results, field):
    fields = set([])
    for ir in in_results:
        fields.add(getattr(ir, field))
    out_results = []
    for f in fields:
        r = {field: f}
        num = 0
        for ir in in_results:
            other_fields = (of for of in ir._fields if of != field)
            if getattr(ir, field) == f:
                num += 1
                for of in other_fields:
                    if getattr(ir, of):
                        r[of] = r.get(of, 0) + getattr(ir, of)
                    else:
                        r[of] = 0
        for of in r.keys():
            if of == field:
                continue
            r[of] /= num

        r = type(in_results[0])(**r)
        out_results.append(r)

    return out_results


def breakpoint():
    import pdb
    pdb.Pdb().set_trace(sys._getframe().f_back)
