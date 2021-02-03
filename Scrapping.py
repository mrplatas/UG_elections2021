from bs4 import BeautifulSoup as BS
from requests import get
import requests
import os
import sys
import csv
import subprocess
import re

os.chdir('/Users/fredericcochinard/Dropbox/Platas_Cochinard/3_2021 Elections/Results 2021 Uganda/2_PDF/')

# module for scrapping all url

# computing all urls inside every browser date

url= 'https://www.ec.or.ug/2021-presidential-results-tally-sheets-district'

req = requests.get(url)
soup = BS(req.content, 'html.parser')

urls=[]
for link in soup.find_all('a'):
    y = link.get('href')
    if y[:25] == 'ecresults/2021/PRESIDENT_' in y:
            link = 'https://www.ec.or.ug/' + y
            name = re.sub('https://www.ec.or.ug/ecresults/2021/PRESIDENT_', '', link)
            r = requests.get(link, stream=True)
            address_pdf = '/Users/fredericcochinard/Dropbox/Platas_Cochinard/3_2021 Elections/Results 2021 Uganda/2_PDF/' + name
            with open(address_pdf, 'wb') as fd:
                fd.write(r.content)

# all pdfs are saved
