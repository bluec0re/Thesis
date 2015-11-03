import sys
from collections import namedtuple


BoundingBox = namedtuple('BoundingBox', 'x_min, y_min, x_max, y_max')
Result = namedtuple('Result', 'fileid, score, bbox')


def get_mean(in_results, field):
    """
    Group data by given field and calc mean for others

    Equiv to
    SELECT AVG(field1), AVG(field2), ..., field FROM ... GROUP BY field
    """
    fields = set([])
    # collect possible field values
    for ir in in_results:
        fields.add(getattr(ir, field))

    out_results = []
    for f in fields:
        r = {field: f}
        num = 0
        # sum fields up
        for ir in in_results:
            other_fields = (of for of in ir._fields if of != field)
            if getattr(ir, field) == f:
                num += 1
                for of in other_fields:
                    # is field part of ir?
                    if getattr(ir, of):
                        r[of] = r.get(of, 0) + getattr(ir, of)
                    else:
                        r[of] = 0

        # Divide summed fields
        for of in r.keys():
            if of == field:
                continue
            r[of] /= num

        # construct single result
        r = type(in_results[0])(**r)
        out_results.append(r)

    return out_results


def breakpoint():
    """
    Set a debug breakpoint

    Equiv to MATLABs keyboard
    """
    import pdb
    pdb.Pdb().set_trace(sys._getframe().f_back)
