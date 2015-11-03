from pathlib import Path as P

__all__ = (
    'ROOT', 'ESVM_PATH', 'RESULT_PATH', 'PASCAL_PATH', 'ANNOTATION_PATH',
    'IMAGE_PATH', 'TIMING_PATH', 'PERFORMANCE_PATH', 'FILES', 'ESVM_FILES',
    'ESVM_IDS'
)

# Project root
ROOT = P(__file__).absolute().parent.parent
# Masatos ExemplarSVM project location
ESVM_PATH = ROOT / '..' / 'masato' / 'timo2'
# Detection results
RESULT_PATH = ROOT / 'results'
# PASCAL Image Database
PASCAL_PATH = ROOT / 'DBs' / 'Pascal' / 'VOC2011'
ANNOTATION_PATH = PASCAL_PATH / 'Annotations'
IMAGE_PATH = PASCAL_PATH / 'JPEGImages'

# Results from timings script
TIMING_PATH = RESULT_PATH / 'timings'
PERFORMANCE_PATH = RESULT_PATH / 'performance'

# Query files
FILES = ('2008_004363', '2009_004882', '2010_005116', '2009_000634', '2010_003701')
# Corresponding ESVM file numbers
ESVM_FILES = (11, 30, 39, 21, 36)
# Mapping
ESVM_IDS = (
    '2007_008932',
    '2008_000133',
    '2008_000176',
    '2008_000562',
    '2008_000691',
    '2008_002098',
    '2008_002369',
    '2008_002491',
    '2008_003287',
    '2008_003970',
    '2008_004363',
    '2008_004872',
    '2008_005147',
    '2008_005190',
    '2008_007103',
    '2008_008395',
    '2008_008611',
    '2008_008724',
    '2009_000545',
    '2009_000632',
    '2009_000634',
    '2009_000985',
    '2009_002087',
    '2009_002295',
    '2009_002928',
    '2009_002954',
    '2009_003208',
    '2009_004364',
    '2009_004551',
    '2009_004882',
    '2009_004934',
    '2010_000254',
    '2010_000342',
    '2010_001899',
    '2010_002814',
    '2010_003701',
    '2010_004365',
    '2010_004921',
    '2010_005116',
    '2010_005951',
    '2010_006031',
    '2010_006274',
    '2010_006366',
    '2010_006668',
    '2011_000053',
    '2011_001138',
    '2011_001726',
    '2011_002110',
    '2011_002217',
    '2011_004221'
)
