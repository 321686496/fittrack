# -*- coding: utf-8 -*-
import re

MOCK = "fittrack_flutter/lib/data/mock_data.dart"
txt = open(MOCK, encoding="utf-8").read()
m = re.search(r"exerciseSteps\s*=\s*\{(.*?)\n\s*\};", txt, re.S)
block = m.group(1)
print("BLOCK_HEAD:", repr(block[:80]))

acts = list(re.finditer(r"'([a-z]+[0-9]+)':\s*\[(.*?)\]\s*", block, re.S))
print("ACTS_MATCHED:", len(acts))
if acts:
    print("FIRST_EID:", acts[0].group(1))
    print("FIRST_BODY_LEN:", len(acts[0].group(2)))

# 试着直接用更宽松的动作正则
acts2 = list(re.finditer(r"'e(\d+)':\s*\[", block, re.S))
print("E-NUM_MATCHED:", len(acts2), [x.group(0)[:12] for x in acts2[:3]])