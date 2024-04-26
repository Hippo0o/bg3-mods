import sys
import xml.etree.ElementTree as ET


def to_lua_table(py_list):
    lua_table = "return {\n"
    for item in py_list:
        lua_table += "{\n"
        for key, value in item.items():
            lua_table += f'  ["{key}"] = "{value}",\n'
        lua_table += "},\n"
    lua_table += "}"
    return lua_table


results = []

# Read the file paths from stdin
# fd -H _merged.lsx ./**/Characters/*.lsx | python parse.py
for line in sys.stdin:
    filepath = line.strip()
    tree = ET.parse(filepath)
    root = tree.getroot()
    for node in root.iter('node'):
        if node.attrib.get('id') == 'GameObjects':
            attributes = node.findall('attribute')

            attr_dict = {attr.attrib['id']: attr.attrib['value'] for attr in attributes if attr.attrib['id'] in [
                'LevelName', 'TemplateName', 'Name', 'Type',
                'IsBoss', 'AiHint',
                'Icon', 'LevelOverride', 'Equipment', 'Faction',
                'Archetype', 'Stats', 'SpellSet', 'CharacterVisualResourceID'
            ]}

            if attr_dict['Name'].startswith('S_Player_'):
                continue

            if '_Daisy' in attr_dict['Name']:
                continue

            if attr_dict['Name'].startswith('S_CAMP_'):
                continue

            if attr_dict['Name'].startswith('S_TUT_'):
                continue

            if (
                attr_dict['Type'] == 'character'
            ):
                print(attr_dict)
                results.append(attr_dict)

lua_table = to_lua_table(results)
with open('Characters.lua', 'w') as f:
    f.write(lua_table)
