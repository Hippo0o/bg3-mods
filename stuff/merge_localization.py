import sys
import xml.etree.ElementTree as ET

results = []

# Read the file paths from stdin
# fd .xml | python ../../../stuff/merge_localization.py
for line in sys.stdin:
    filepath = line.strip()
    tree = ET.parse(filepath)
    root = tree.getroot()
    for node in root.iter('content'):
        if node.attrib.get('contentuid') in [result.attrib.get('contentuid') for result in results]:
            continue

        results.append(node)


with open('_merged.xml', 'w') as f:
    f.write('<?xml version="1.0" encoding="utf-8"?>\n')
    f.write('<contentList>\n')
    for node in results:
        f.write(ET.tostring(node, encoding='utf-8').decode('utf-8'))
    f.write('</contentList>')
