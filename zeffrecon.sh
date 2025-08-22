#!/bin/bash

RED="\033[1;31m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"
CYAN="\033[1;36m"; RESET="\033[0m"

banner() {
  echo -e "${CYAN}"
  echo -e "  ____________ ______ ______   _____  ______ _____ ____  _   _  "
  echo -e " |___  /  ____|  ____|  ____| |  __ \|  ____/ ____/ __ \| \ | | "
  echo -e "    / /| |__  | |__  | |__    | |__) | |__ | |   | |  | |  \| | "
  echo -e "   / / |  __| |  __| |  __|   |  _  /|  __|| |   | |  | | . \ | "
  echo -e "  / /__| |____| |    | |      | | \ \| |___| |___| |__| | |\  | "
  echo -e " /_____|______|_|    |_|      |_|  \_\______\_____\____/|_| \_| "
  echo -e "${RESET}"
  echo -e "${YELLOW}ZeffRecon v1.2 - Author: iqzeff"
  echo -e "Educational use only | Bug bounty use only${RESET}\n"
}

usage() {
  banner
  echo -e "${CYAN}Usage:${RESET}"
  echo -e "  ./zeffrecon.sh -d example.com [-o outdir] [-rl ratelimit] [--skip sqli|xss|nmap|brokenlink|ffuf|nuclei]"
  echo -e "  ./zeffrecon.sh -l file.txt      # scan list"
  echo -e "  ./zeffrecon.sh -update         # placeholder update feature"
  echo -e "  ./zeffrecon.sh -h              # help message"
  exit 1
}

check_tools() {
    declare -A go_tools=(
        [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        [httpx]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
        [katana]="github.com/projectdiscovery/katana/cmd/katana@latest"
        [nuclei]="github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
        [gau]="github.com/lc/gau@latest"
        [waybackurls]="github.com/tomnomnom/waybackurls@latest"
        [assetfinder]="github.com/tomnomnom/assetfinder@latest"
        [gf]="github.com/tomnomnom/gf@latest"
        [dalfox]="github.com/hahwul/dalfox/v2@latest"
    )

    declare -A apt_tools=(
        [nmap]="nmap"
        [sqlmap]="sqlmap"
        [ffuf]="ffuf"
    )

    for tool in subfinder sublist3r assetfinder httpx gau katana waybackurls nuclei nmap gf sqlmap dalfox ffuf; do
        if ! command -v $tool &>/dev/null; then
            echo -e "${YELLOW}[!] $tool is not installed.${RESET}"
            read -p "Install $tool now? (Y/n): " answer
            answer=${answer:-Y}
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                if [[ ${apt_tools[$tool]+_} ]]; then
                    sudo apt update && sudo apt install -y ${apt_tools[$tool]}
                    continue
                fi
                if [[ ${go_tools[$tool]+_} ]]; then
                    if ! command -v go &>/dev/null; then
                        echo -e "${RED}[!] Go is not installed. Please install Go first.${RESET}"
                        exit 1
                    fi
                    echo -e "${CYAN}[*] Installing $tool via Go...${RESET}"
                    go install "${go_tools[$tool]}"
                    export PATH="$PATH:$(go env GOPATH)/bin"
                    continue
                fi
                if [[ "$tool" == "sublist3r" ]]; then
                    echo -e "${CYAN}[*] Cloning Sublist3r...${RESET}"
                    git clone https://github.com/aboul3la/Sublist3r.git ~/tools/Sublist3r
                    pip install -r ~/tools/Sublist3r/requirements.txt
                    ln -s ~/tools/Sublist3r/sublist3r.py /usr/local/bin/sublist3r
                    chmod +x /usr/local/bin/sublist3r
                    continue
                fi
                echo -e "${RED}[!] Cannot auto-install $tool. Please install manually.${RESET}"
                exit 1
            else
                echo -e "${RED}[-] $tool is required. Exiting.${RESET}"
                exit 1
            fi
        fi
    done
}
#skips
SKIP_SQLI=false; SKIP_XSS=false; SKIP_NMAP=false; SKIP_BROKENLINK=false; SKIP_FFUF=false; SKIP_NUCLEI=false
OUTPUT_DIR=""; RATE_LIMIT=0

parse_skip(){
  while [[ "$1" ]]; do
    case $1 in
      sqli) SKIP_SQLI=true ;;
      xss) SKIP_XSS=true ;;
      nmap) SKIP_NMAP=true ;;
      brokenlink) SKIP_BROKENLINK=true ;;
      ffuf) SKIP_FFUF=true ;;
      nuclei) SKIP_NUCLEI=true ;;
      *) echo -e "${RED}Unknown skip: $1${RESET}"; usage ;;
    esac
    shift
  done
}

domain_is_up(){
  local domain=$1
  if ping -c 1 -W 1 "$domain" &>/dev/null; then return 0; fi
  if curl -Is --connect-timeout 3 "http://$domain" &>/dev/null; then return 0; fi
  return 1
}

run_sublist3r(){
  sublist3r -d "$1" -o - 2>/dev/null | \
  sed -r 's/\x1B\[[0-9;]*[JKmsu]//g' | \
  grep -E "^[a-zA-Z0-9.-]+$" | \
  grep -v "Coded By" | grep -v "Searching now" | grep -v "Saving results" | \
  grep -v "Unique Subdomains" | grep -v "Enumerating" | grep -v "Error"
}

check_broken_links() {
  local urls_file="$1"; local odir="$2"
  echo -e "${YELLOW}[*] Checking for broken links...${RESET}"
  httpx -silent -status-code -mc 400,401,403,404,500,502,503 < "$urls_file" | tee "$odir/broken-$(basename $urls_file)"
  echo -e "${YELLOW}[*] Broken link check completed.${RESET}"
}

scan_domain(){
  local domain="$1"; local odir="$2"
  [[ -z "$odir" ]] && odir="zeff-$domain"
  mkdir -p "$odir"
  local subs="$odir/sub-$domain.txt"
  local alive="$odir/alive-$domain.txt"
  local urls="$odir/urls-$domain.txt"
  local sqli="$odir/sqli-$domain.txt"

  echo -e "${CYAN}[*] Looking for subdomains...${RESET}"
  subfinder -d "$domain" -silent >> "$subs"
  run_sublist3r "$domain" >> "$subs"
  assetfinder --subs-only "$domain" >> "$subs"
  sort -u "$subs" -o "$subs"

  echo -e "${CYAN}[*] Finding alive subdomains...${RESET}"
  httpx -silent < "$subs" > "$alive"

  echo -e "${CYAN}[*] Gathering URLs...${RESET}"
  gau < "$alive" >> "$urls" &
  katana -silent -jc < "$alive" >> "$urls" &
  waybackurls < "$alive" >> "$urls" &
  wait
  sort -u "$urls" -o "$urls"

  if ! $SKIP_BROKENLINK; then
    check_broken_links "$urls" "$odir"
  fi

  if ! $SKIP_NUCLEI; then
    read -p "Nuclei scan URLs? (Y/N): " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
      nuclei -l "$urls" -o "$odir/nuclei.txt"
    fi
  fi

  if ! $SKIP_NMAP; then
    nmap -Pn -p- "$domain" -oN "$odir/nmap-$domain.txt"
  fi

  if ! $SKIP_SQLI; then
    gf sqli < "$urls" > "$sqli"
    if [[ -s "$sqli" ]]; then
      while read -r u; do
        sqlmap -u "$u" --batch --level=2 --risk=1 --crawl=1 --output-dir=/tmp/sqlmap-trash >/dev
