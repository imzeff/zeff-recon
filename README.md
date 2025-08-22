# ZeffRecon

ZeffRecon is an automated **bug bounty reconnaissance** toolchain that integrates multiple popular tools for subdomain enumeration, URL collection, vulnerability scanning, directory brute-forcing, and more.

---

## ✨ Features

* **Domain & List Scanning**
* **Subdomain Enumeration** (Subfinder, Sublist3r, Assetfinder)
* **Live Host Detection** (`httpx`)
* **URL Gathering** (parallelized: gau, katana, waybackurls)
* **Vulnerability Detection**:

  * SQLi (via GF + SQLmap)
  * XSS (via GF + Dalfox)
  * Nuclei template scanning
* **Port Scanning**: `nmap` with live screen output
* **Broken Link Detection** (results saved as `broken-*.txt`)
* **Directory Brute-Forcing** (via FFUF using SecLists)
* **Rate Limiting** to avoid blocking
* **Skip Flags** to selectively skip modules (sqli, xss, nmap, brokenlink, ffuf)

---

## 📦 Installation

Clone this repository:

```bash
git clone https://github.com/93883udnw330/zeff-recon.git
cd zeffrecon
chmod +x zeffrecon.sh
./zeffrecon.sh
```

---

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
./zeffrecon.sh -d example.com --skip sqli xss ffuf brokenlink
```

---

## 📂 Output Structure

```
zeff-example.com/
├── sub-example.com.txt           # Discovered subdomains
├── alive-example.com.txt         # Alive hosts
├── urls-example.com.txt          # Collected URLs
├── broken-urls-example.com.txt   # Broken link results
├── nuclei.txt                    # Nuclei results (optional)
├── nmap-example.com.txt          # Nmap results
├── sqli-example.com.txt          # SQLi candidates
├── xss-example.com.txt           # XSS candidates
├── ffuf-example.com.json         # Directory brute-force results
```

---

## 🛠 Tools Used

* [subfinder](https://github.com/projectdiscovery/subfinder)
* [sublist3r](https://github.com/aboul3la/Sublist3r)
* [assetfinder](https://github.com/tomnomnom/assetfinder)
* [httpx](https://github.com/projectdiscovery/httpx)
* [gau](https://github.com/lc/gau)
* [waybackurls](https://github.com/tomnomnom/waybackurls)
* [katana](https://github.com/projectdiscovery/katana)
* [nuclei](https://github.com/projectdiscovery/nuclei)
* [gf](https://github.com/tomnomnom/gf)
* [sqlmap](https://github.com/sqlmapproject/sqlmap)
* [dalfox](https://github.com/hahwul/dalfox)
* [nmap](https://nmap.org/)
* [ffuf](https://github.com/ffuf/ffuf)
* brokenlinkchecker

---

## 📜 License

This project is licensed under the MIT License — feel free to modify and share with credit.

---

## 🤝 Author

**iqzeff**
For questions, suggestions, or contributions, open an issue or submit a pull request.
