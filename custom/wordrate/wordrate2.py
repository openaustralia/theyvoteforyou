import sys
import os.path
import re
import string


countries = """
Afghanistan
Albania
Algeria
Andorra
Angola
Antigua and Barbuda|Antigua
Argentina
Armenia
Australia
Austria
Azerbaijan
Bahamas
Bahrain
Bangladesh
Barbados
Belarus|Byelorussia
Belgium
Belize
Benin
Bhutan
Bolivia
Bosnia and Herzegovina|Bosnia
Botswana
Brazil
Brunei 
Bulgaria
Burkina Faso
Burundi
Cambodia
Cameroon
Canada
Cape Verde
Central African Republic
Chad
Chile
China
Colombia
Comoros
Congo-Brazzaville|Congo Brazzaville|Republic of Congo
Costa Rica
Cote d'Ivoire|Ivory Coast
Croatia
Cuba
Cyprus
Czech Republic
Democratic People's Republic of Korea|North Korea
Democratic Republic of the Congo|DRC|Zaire|Democratic Republic of Congo
Denmark
Djibouti
Dominica
Dominican Republic
Ecuador
Egypt
El Salvador
Equatorial Guinea
Eritrea
Estonia
Ethiopia
Fiji
Finland
France
Gabon
Gambia
Georgia
Germany
Ghana
Greece
Grenada
Guatemala
Guinea
Guinea-Bissau
Guyana
Haiti
Honduras
Hungary
Iceland
India
Indonesia
Iran
Iraq
Ireland
Israel
Italy
Jamaica
Japan
Jordan
Kazakhstan
Kenya
Kiribati
Kuwait
Kyrgyzstan
Lao People's Democratic Republic|Laos
Latvia
Lebanon
Lesotho
Liberia
Libyan Arab Jamahiriya|Libya
Liechtenstein
Lithuania
Luxembourg
Macedonia|FYROM
Madagascar
Malawi
Malaysia
Maldives
Mali
Malta
Marshall Islands
Mauritania
Mauritius
Mexico
Micronesia
Monaco
Mongolia
Morocco
Mozambique
Myanmar|Burma
Namibia
Nauru
Nepal
Netherlands
New Zealand
Nicaragua
Niger
Nigeria
Norway
Oman
Pakistan
Palau
Panama
Papua New Guinea
Paraguay
Peru
Philippines
Poland
Portugal
Qatar
Republic of Korea|South Korea
Moldova
Romania
Russian Federation|Russia
Rwanda 
Saint Lucia
Saint Vincent and the Grenadines
Samoa
San Marino
Sao Tome and Principe
Saudi Arabia
Senegal
Serbia|Montenegro
Seychelles
Sierra Leone
Singapore
Slovakia
Slovenia
Solomon Islands
Somalia
South Africa
Spain
Sri Lanka
Sudan
Suriname
Swaziland
Sweden
Switzerland
Syrian Arab Republic|Syria
Tajikistan
Thailand
Timor-Leste|East Timor
Togo
Tonga
Trinidad and Tobago
Tunisia
Turkey
Turkmenistan
Tuvalu
Uganda
Ukraine
United Arab Emirates|UAE
United Kingdom|UK
England
Wales
Scotland
Northern Ireland
United Republic of Tanzania|Tanzania
United States of America|US|USA
Uruguay
Uzbekistan
Vanuatu
Venezuela 
Viet Nam|Vietnam
Yemen
Zambia
Zimbabwe
Anguilla
Ascension
Bermuda
British Antarctic Territory
British Indian Overseas Territory|BIOT|Diego Garcia|Chagos Islands
Cayman Islands
Falkland Islands
Gibraltar
Montserrat
Pitcairn|Henderson|Ducie|Oeno
Saint Christopher and Nevis|Saint Kitts and Nevis
South Georgia and South Sandwich Islands
St Helena|Tristan De Cunha
Turks and Caicos Islands
Holy See|Vatican
Tibet
Hong Kong
Macau|Macao
Western Sahara
Kashmir
Kosovo
North Cyprus
Palestine
Taiwan|Formosa
Chechnya




"""

class cstats:
	def __init__(self, lname):
		self.name = lname
		self.reg = re.compile(lname)
		self.paracount = 0

	def CountForPara(self, lin):
		if self.reg.search(lin):
			self.paracount += 1


def MakeMatchList():
	res = []
	for c in re.split("\n", countries):
		lc = string.strip(c)
		if lc:
			res.append(cstats(lc))
	return res

def AddUpForDate(cstatlist, fname):
	numparas = 0
	fin = open(fname)
	for lin in fin.readlines():
		if re.match("\s*<p>", lin):
			numparas += 1
			for c in cstatlist:
				c.CountForPara(lin)
	fin.close()
	return numparas

def WriteResult(cstatlist, totalnumparas, totaldays):
	print "total number of paragraphs", totalnumparas, "in", totaldays, "days"
	for c in cstatlist:
		print '"%s"\t%d' % (c.name, c.paracount)


# main loop call
cstatlist = MakeMatchList()
debatesxmldir = "/home/fawkes/pwdata/scrapedxml/debates"
debfiles = os.listdir(debatesxmldir)
totalnumparas = 0
totaldays = 0
for fil in debfiles:
	if re.search("\.xml$", fil):
		totaldays += 1
		if not re.match("debates2005-01", fil):
			continue
		print fil
		totalnumparas += AddUpForDate(cstatlist, os.path.join(debatesxmldir, fil))
WriteResult(cstatlist, totalnumparas, totaldays)

