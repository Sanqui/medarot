import requests
from io import open

pages = "Dialogue_1 Dialogue_2 Dialogue_3 Battles Snippets".split()

lists = "Attributes Skills Items Medals Medarotters Medarots Attacks Part".split()

print("Getting pages from Medapedia...")

for i, page in enumerate(pages):
    rq = requests.get("http://medarot.meowcorp.us/wiki/Medapedia:Medarot_1_Translation_Project/Text/{}?action=raw".format(page))
    assert rq.status_code == 200
    if page != "Snippets":
        open("text/{}.mediawiki".format(page), 'w', encoding='utf-8').write(rq.text)
    else:
        snippet_text = ""
        cursnippet = 0
        for line in rq.text.split('\n'):
            if line.startswith('== Snippet '):
                if cursnippet:
                    open("text/Snippet_{}.mediawiki".format(cursnippet), 'w', encoding='utf-8').write(snippet_text)
                cursnippet += 1
                snippet_text = ""
            snippet_text += line+'\n'
        open("text/Snippet_{}.mediawiki".format(cursnippet), 'w', encoding='utf-8').write(snippet_text)
        
    print("Getting pages... {}/{} ({:.4}%) done".format(i+1, len(pages), (float(i+1)/len(pages))*100))

print("Getting list data from Medapedia...")

rq = requests.get("http://medarot.meowcorp.us/wiki/Medapedia:Medarot_1_Translation_Project/Text/Lists?action=raw")
assert rq.status_code == 200

#== Name ==
#comments
#comments
#{| class=wikitable width=300
# - 
# Japanese
# English
# -

#We actually don't care about the japanese, we just want the english text in a line
t = rq.text.split('\n==')

for section in t:
	#Get the file name
	lines = section.split("\n")
	filename = lines[0].replace("==","").replace(" ","").lower() + ".txt"
	print("Writing to "+ filename)
	f = open("text/"+filename, 'wb')
	f.write(str(int(lines[1],16)) + "\n")
	data = section.split("|-")
	for item in data:
		i = item.replace("\n","")
		if i[0] != "|":
			continue
		j = i.split("|")
		idx = j[1]
		if idx[0] != '}':
			eng = j[3]
			jp = j[2]
			if len(eng) == 0:
				f.write(idx+"\n")
				#f.write(jp+"\n")
			else:
				f.write(eng+"\n")
	f.close()		
	
