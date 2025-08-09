# ZeffRecon

ZeffRecon is an automated **bug bounty reconnaissance** toolchain that integrates multiple popular tools for subdomain enumeration, URL collection, vulnerability scanning, and more .
---

## ✨ Features

- **Domain & List Scanning**
- **Subdomain Enumeration**
- **Live Host Detection**
- **URL Gathering**
- **Vulnerability Detection**:
  - SQLi
  - XSS
  - Nuclei template scanning
- **Port Scanning**: `nmap` with live screen output
- **Rate Limiting** to avoid blocking

---

## 📦 Installation

Clone this repository:

```bash
git clone https://github.com/93883udnw330/zeff-recon.git
cd zeffrecon
chmod +x zeffrecon.sh
./zeffrecon.sh
```
## 🚀 Usage

### Scan a single domain:
```bash
./zeffrecon.sh -d example.com
```

### Scan from a list:
```bash
./zeffrecon.sh -l domains.txt
```

### Set output directory:
```bash
./zeffrecon.sh -d example.com -o results
```

### Apply rate limit:
```bash
./zeffrecon.sh -d example.com -rl 2
```

### Skip modules:
```bash
./zeffrecon.sh -d example.com --skip sqli xss
```

## 📂 Output Structure

```
zeff-example.com/
├── sub-example.com.txt      # Discovered subdomains
├── alive-example.com.txt    # Alive hosts
├── urls-example.com.txt     # Collected URLs
├── nuclei.txt               # Nuclei results (optional)
├── nmap-example.com.txt     # Nmap results
├── sqli-example.com.txt     # SQLi candidates
├── xss-example.com.txt      # XSS candidates
```

---

## 🛠 Tools Used

- [subfinder](https://github.com/projectdiscovery/subfinder)
- [sublist3r](https://github.com/aboul3la/Sublist3r)
- [assetfinder](https://github.com/tomnomnom/assetfinder)
- [httpx](https://github.com/projectdiscovery/httpx)
- [gau](https://github.com/lc/gau)
- [waybackurls](https://github.com/tomnomnom/waybackurls)
- [katana](https://github.com/projectdiscovery/katana)
- [nuclei](https://github.com/projectdiscovery/nuclei)
- [gf](https://github.com/tomnomnom/gf)
- [sqlmap](https://github.com/sqlmapproject/sqlmap)
- [dalfox](https://github.com/hahwul/dalfox)
- [nmap](https://nmap.org/)
- brokenlinkchecker
---

## 📜 License

This project is licensed under the MIT License — feel free to modify and share with credit.

---

## 🤝 Author

**iqzeff**  
For questions, suggestions, or contributions, open an issue or submit a pull request.
