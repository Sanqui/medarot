import requests
from io import open

pages = "Dialogue_1 Dialogue_2 Dialogue_3 Battles".split()

print("Getting pages from Medapedia...")

for i, page in enumerate(pages):
    rq = requests.get("http://medarot.meowcorp.us/wiki/User:Kimbles/Medarot_1_Hacking_Notes/Text/{}?action=raw".format(page))
    assert rq.status_code == 200
    open("text/{}.mediawiki".format(page), 'w', encoding='utf-8').write(rq.text)
    print("Getting pages... {}/{} ({:.4}%) done".format(i+1, len(pages), (float(i+1)/len(pages))*100))


