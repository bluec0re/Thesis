from collections import namedtuple
from xml.etree import ElementTree as ET

from .config import ANNOTATION_PATH, IMAGE_PATH, ROOT
from .utils import BoundingBox

GroundData = namedtuple('GroundData', 'fileid, I, positive, bbox, objectid')


class GroundTruth:
    pascal_class = 'bicycle'
    data = None
    positives = []
    negatives = []

    def __init__(self, data):
        self._data = data[:]

    def __getitem__(self, name):
        results = []
        for gd in self._data:
            if gd.fileid == name:
                results.append(gd)
        return tuple(results)

    def __iter__(self):
        return iter(self._data)

    def delete(self, fileid, objectid):
        for i, gd in enumerate(self._data):
            if gd.fileid == fileid and gd.objectid == objectid:
                self._data.pop(i)
                break

    def pop(self):
        return self._data.pop()

    def __len__(self):
        return len(self._data)

    @classmethod
    def get(cls):
        if not cls.data:
            cls.load()
        return GroundTruth(cls.data)

    @classmethod
    def load_ids(cls):
        with (ROOT / "data" / "{}_database.txt".format(cls.pascal_class)).open() as fp:
            for line in fp:
                id, type = line.split()
                if type == '1':
                    cls.positives.append(id)
                else:
                    cls.negatives.append(id)

    @classmethod
    def load(cls):
        cls.load_ids()
        cls.data = []
        for fileid in cls.positives + cls.negatives:
            xml = ET.parse(str(ANNOTATION_PATH / (fileid + '.xml')))
            objid = 0
            for obj in xml.iterfind('object'):
                if obj.find('name').text == cls.pascal_class:
                    bndbox = obj.find('bndbox')
                    bndbox = BoundingBox(
                        int(bndbox.find('xmin').text)-1,
                        int(bndbox.find('ymin').text)-1,
                        int(bndbox.find('xmax').text)-1,
                        int(bndbox.find('ymax').text)-1,
                    )
                    gd = GroundData(
                        fileid,
                        IMAGE_PATH / "{}.jpg".format(fileid),
                        fileid in cls.positives,
                        bndbox,
                        objid+1
                    )
                    cls.data.append(gd)
                    objid += 1

            if fileid in cls.negatives or objid == 0:
                gd = GroundData(
                    fileid,
                    IMAGE_PATH / "{}.jpg".format(fileid),
                    fileid in cls.positives,
                    None,
                    objid
                )
                cls.data.append(gd)


def pascal_overlap(A, B):
    """
    >>> pascal_overlap(BoundingBox(0, 0, 10, 10), BoundingBox(0, 0, 10, 10))
    1.0
    >>> pascal_overlap(BoundingBox(0, 0, 10, 20), BoundingBox(0, 0, 10, 10))
    0.5
    >>> pascal_overlap(BoundingBox(0, 0, 10, 10), BoundingBox(0, 5, 10, 10))
    0.5
    >>> pascal_overlap(BoundingBox(0, 0, 10, 5), BoundingBox(0, 5, 10, 10))
    0
    """
    dx = int(min(A.x_max, B.x_max) - max(A.x_min, B.x_min))
    dy = int(min(A.y_max, B.y_max) - max(A.y_min, B.y_min))
    if dy > 0 and dx > 0:
        intersectionArea = dx * dy
    else:
        return 0

    dx = int(max(A.x_max, B.x_max) - min(A.x_min, B.x_min))
    dy = int(max(A.y_max, B.y_max) - min(A.y_min, B.y_min))
    if dy > 0 and dx > 0:
        unionArea = dx * dy
    else:
        unionArea = 0
    overlap = intersectionArea / unionArea
    return overlap
