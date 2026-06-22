import re

data = """
**Dhaka Division**
• **Dhaka Metropolitan Police (DMP):** Ramna, Dhanmondi, Shahbag, New Market, Lalbagh, Kotwali, Hazaribagh, Kamrangirchar, Sutrapur, Demra, Shampur, Jatrabari, Motijheel, Sabujbagh, Khilgaon, Paltan, Adabor, Badda, Banani, Gulshan, Cantonment, Mirpur, Mohammadpur, and Pallabi.
• **Dhaka District & Others:** Savar, Ashulia, Dhamrai, and Keranigonj.

**Chattogram Division**
• **Chattogram Metropolitan Police (CMP):** Kotwali, Double Mooring, Halishahar, Khulshi, Pahartali, Panchlaish, Bakalia, Bayezid Bostami, Chandgaon, Karnaphuli, Bandar, and EPZ.
• **Chattogram District & Others:** Fatikchari, Bhujpur, Patiya, Boalkhali, Mirsharai, Sitakunda, Sandwip, Raozan, Rangunia, and Hathazari. 

**Sylhet Division**
• **Sylhet Metropolitan Police (SMP):** Kotwali, Airport, Dakshin Surma, Jalalabad, Moglabazar, and Shah Poran.
• **Sylhet District & Others:** Sylhet Sadar, Beanibazar, Bishwanath, Companiganj, Fenchuganj, Golapganj, Gowainghat, Jaintiapur, Kanaighat, Zakiganj, Balaganj, and South Surma.

**Rajshahi Division**
• **Rajshahi Metropolitan Police (RMP):** Boalia, Rajpara, Motihar, Shah Makhdum, Katakhali, Kasiadanga, Airport, and Belpukur.
• **Rajshahi District & Others:** Godagari, Tanor, Mohanpur, Bagmara, Charghat, Durgapur, Puthia, and Bagha. 

**Khulna Division**
• **Khulna Metropolitan Police (KMP):** Khulna Sadar, Sonadanga, Khalishpur, Daulatpur, Khan Jahan Ali, Harintana, Labanchora, and Aranghata.
• **Khulna District & Others:** Batiaghata, Dacope, Dumuria, Dighalia, Koyra, Paikgachha, Phultala, Rupsha, and Terokhada. 

**Barishal Division**
• **Barishal Metropolitan Police (BMP):** Kotwali, Kaunia, Kawnia, Airport, Bandar, and C.R.F.
• **Barishal District & Others:** Muladi, Babuganj, Bakerganj, Banaripara, Agailjhara, Gournadi, Hizla, Mehendiganj, and Wazirpur. 

**Rangpur Division**
• **Rangpur Metropolitan Police (RpMP):** Kotwali, Parshuram, Tajhat, Haragach, Mahiganj, and Hazirhat.
• **Rangpur District & Others:** Rangpur Sadar, Badarganj, Mithapukur, Pirgachha, Pirganj, Taraganj, and Kaunia. [1]

**Mymensingh Division**
• **Mymensingh District & Others:** Mymensingh Sadar, Kotwali, Muktagachha, Phulbaria, Trishal, Bhaluka, Gouripur, Haluaghat, Iswarganj, Nandail, and Phulpur.
"""

div_map = {
    'Dhaka Division': 'divisionDhaka',
    'Chattogram Division': 'divisionChattogram',
    'Sylhet Division': 'divisionSylhet',
    'Rajshahi Division': 'divisionRajshahi',
    'Khulna Division': 'divisionKhulna',
    'Barishal Division': 'divisionBarishal',
    'Rangpur Division': 'divisionRangpur',
    'Mymensingh Division': 'divisionMymensingh',
}

out = []
current_div_name = ""
current_div_var = ""

lines = data.split('\n')
for line in lines:
    line = line.strip()
    if line.startswith('**') and line.endswith('**') and not ':' in line:
        div = line.strip('*')
        if div in div_map:
            current_div_name = div
            current_div_var = div_map[div]
    elif ':' in line and current_div_var:
        parts = line.split(':')
        stations_str = parts[1].strip()
        stations_str = stations_str.replace(' and ', ', ')
        stations_str = stations_str.replace('.', '')
        stations_str = stations_str.replace('[1]', '')
        stations = [s.strip() for s in stations_str.split(',') if s.strip()]
        
        for s in stations:
            s_clean = s.replace("'", "")
            if s_clean == 'Kotwali' or s_clean == 'Airport':
                s_name = f"{s_clean} Police Station ({current_div_name.split(' ')[0]})"
            else:
                s_name = f"{s_clean} Police Station"
            
            id_str = f"{current_div_name.split(' ')[0].lower()}_{s_clean.lower().replace(' ', '_')}"
            
            out.append(f"""  const PoliceStation(
    id: '{id_str}', name: '{s_name}',
    address: '{s_clean}, {current_div_name.split(' ')[0]}, Bangladesh', phone: '01320-000000',
    location: LatLng(23.7, 90.4), division: {current_div_var}, thana: '{s_clean}',
    details: '''Address: {s_clean}, {current_div_name.split(' ')[0]}, Bangladesh
Hours: Open 24 Hours''',
    jurisdiction: '{s_clean}',
  ),""")

with open('f:/Shieldx/scratch/stations.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
