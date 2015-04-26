import requests
from io import open

pages = "Dialogue_1 Dialogue_2 Dialogue_3 Battles Snippets".split()

print("Getting pages from Medapedia...")

for i, page in enumerate(pages):
    rq = requests.get("http://medarot.meowcorp.us/wiki/User:Kimbles/Medarot_1_Hacking_Notes/Text/{}?action=raw".format(page))
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


