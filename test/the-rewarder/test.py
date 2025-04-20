import json

f = open('dvt-distribution.json')
c = f.read()
f.close()

tokenList = json.loads(c)
print(tokenList[188])