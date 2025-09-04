#!/bin/bash

# Colors
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
  echo -e "                                                                "
  echo -e "                                                                "
  echo -e "${RESET}"
  echo -e "${YELLOW}ZeffRecon v1.2 - Author: iqzeff"
  echo -e "Educational use only | Bug bounty use only${RESET}\n"
}

usage() {
  banner
  echo -e "${CYAN}Usage:${RESET}"
  echo -e "  ./zeffrecon.sh -d example.com [-o outdir] [-rl ratelimit] [--skip sqli|xss|nmap|brokenlink]"
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
    )

    for tool in subfinder sublist3r assetfinder httpx gau katana waybackurls nuclei nmap gf sqlmap dalfox; do
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

SKIP_SQLI=false; SKIP_XSS=false; SKIP_NMAP=false; SKIP_BROKENLINK=false
OUTPUT_DIR=""
RATE_LIMIT=0

parse_skip(){
  while [[ "$1" ]]; do
    case $1 in
      sqli) SKIP_SQLI=true ;;
      xss) SKIP_XSS=true ;;
      nmap) SKIP_NMAP=true ;;
      brokenlink) SKIP_BROKENLINK=true ;;
      *) echo -e "${RED}Unknown skip: $1${RESET}"; usage ;;
    esac
    shift
  done
}

domain_is_up(){
  local domain=$1
  if ping -c 1 -W 1 "$domain" &>/dev/null; then
    return 0
  fi
  if curl -Is --connect-timeout 3 "http://$domain" &>/dev/null; then
    return 0
  fi
  return 1
}

check_broken_links() {
  local urls_file="$1"
  echo -e "${YELLOW}[*] Checking for broken links...${RESET}"
  httpx -silent -status-code -mc 400,401,403,404,500,502,503 < "$urls_file" | while read -r line; do
    echo -e "${RED}[Broken] $line${RESET}"
  done
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

  echo "[*] Scanning $domain..."

  subfinder -d "$domain" -silent >> "$subs"; [[ $RATE_LIMIT -gt 0 ]] && sleep "$(echo "scale=3;1/$RATE_LIMIT" | bc)"
  sublist3r -d "$domain" -o - >> "$subs"; [[ $RATE_LIMIT -gt 0 ]] && sleep "$(echo "scale=3;1/$RATE_LIMIT" | bc)"
  assetfinder --subs-only "$domain" >> "$subs"
  sort -u "$subs" -o "$subs"

  httpx -silent < "$subs" > "$alive"
  gau < "$alive" >> "$urls"
  katana -silent -jc < "$alive" >> "$urls"
  waybackurls < "$alive" >> "$urls"
  sort -u "$urls" -o "$urls"

  if ! $SKIP_BROKENLINK; then
    check_broken_links "$urls"
  fi

  read -p "Nuclei scan URLs? (Y/N): " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    nuclei -l "$urls" -o "$odir/nuclei.txt"
  fi

  if ! $SKIP_NMAP; then
    nmap -Pn -p- "$domain" -oN "$odir/nmap-$domain.txt"
  fi

  if ! $SKIP_SQLI; then
    gf sqli < "$urls" > "$sqli"
    if [[ -s "$sqli" ]]; then
      while read -r u; do
        sqlmap -u "$u" --batch --level=2 --risk=1 --crawl=1 --output-dir=/tmp/sqlmap-trash >/dev/null 2>&1
      done < "$sqli"
    fi
  fi

  if ! $SKIP_XSS; then
    gf xss < "$urls" > "$odir/xss-$domain.txt"
    if [[ -s "$odir/xss-$domain.txt" ]]; then
      while read -r u; do dalfox url "$u" >/dev/null 2>&1; done < "$odir/xss-$domain.txt"
    fi
  fi

  echo -e "${GREEN}[+] Completed: results in $odir${RESET}"
}

[[ $# -eq 0 ]] && usage
check_tools

TARGET=""
LIST=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -d)
      if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo -e "${RED}Error: -d requires a valid domain argument.${RESET}"
        exit 1
      fi
      TARGET="$2"
      shift 2
      ;;
    -l)
      if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo -e "${RED}Error: -l requires a valid file argument.${RESET}"
        exit 1
      fi
      if [[ ! -f "$2" ]]; then
        echo -e "${RED}Error: File $2 not found.${RESET}"
        exit 1
      fi
      LIST="$2"
      shift 2
      ;;
    -o)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -rl)
      RATE_LIMIT="$2"
      shift 2
      ;;
    --skip)
      shift
      parse_skip "$@"
      while [[ "$1" && ! "$1" =~ ^- ]]; do shift; done
      ;;
    -update)
      echo "Update feature coming soon…"
      exit 0
      ;;
    -h)
      usage
      ;;
    *)
      echo -e "${RED}Unknown option: $1${RESET}"
      usage
      ;;
  esac
done

banner

if [[ -n "$TARGET" ]]; then
  if ! domain_is_up "$TARGET"; then
    echo -e "${RED}Error: Domain $TARGET is not reachable. Aborting.${RESET}"
    exit 1
  fi
  scan_domain "$TARGET" "$OUTPUT_DIR"
elif [[ -n "$LIST" ]]; then
  while IFS= read -r line; do
    line=$(echo "$line" | tr -d '[:space:]')
    if [[ -z "$line" ]]; then continue; fi
    if ! domain_is_up "$line"; then
      echo -e "${RED}Warning: Domain $line is not reachable. Skipping.${RESET}"
      continue
    fi
    scan_domain "$line" "$OUTPUT_DIR"
  done < "$LIST"
else
  usage
fi
