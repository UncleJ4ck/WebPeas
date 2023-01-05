#!/bin/sh

# checking for arguments
if [ ! $# -eq 1 ]
then
    echo -e "\e[31m[!] Usage./auto.sh <target>\e[0m"
    exit 1
fi

target=$1

clear
echo -e "\e[32m[+] Checking Dependencies\e[0m"
echo
# Check if ruby is installed
if ! [ -x "$(command -v python)" ]; then
    if [ -f /etc/os-release ]; then
        if grep -q "Arch Linux" /etc/os-release; then
            sudo pacman -S ruby
        elif grep -q -e "Ubuntu" -e "Debian" /etc/os-release; then
            sudo apt-get install ruby
        else
            echo -e '\e31m[!] Your system is not supported yet.'
            exit 1
        fi
        export PATH="~/.local/share/gem/ruby/3.0.0/bin:$PATH"
    fi
fi

# Check if Python is installed
if ! [ -x "$(command -v gem -version)" ]; then
    if [ -f /etc/os-release ]; then
        if grep -q "Arch Linux" /etc/os-release; then
            sudo pacman -S ruby
        elif grep -q -e "Ubuntu" -e "Debian" /etc/os-release; then
            sudo apt-get install ruby
        else
            echo -e '\e31m[!] Your system is not supported yet.'
            exit 1
        fi
    fi
fi

# Check if perl is installed
if ! [ -x "$(command -v perl)" ]; then
    if [ -f /etc/os-release ]; then
        if grep -q "Arch Linux" /etc/os-release; then
            sudo pacman -S perl
        elif grep -q -e "Ubuntu" -e "Debian" /etc/os-release; then
            sudo apt-get install perl
        else
            echo -e '\e31m[!] Your system is not supported yet.'
            exit 1
        fi
    fi
fi

# Check if Golang is installed
if ! [ -x "$(command -v go)" ]; then
    if [ -f /etc/os-release ]; then
        if grep -q "Arch Linux" /etc/os-release; then
            sudo pacman -S go
        elif grep -q -e "Ubuntu" -e "Debian" /etc/os-release; then
            sudo apt-get install go
            export PATH="~/go:$PATH"
        else
            echo -e '\e31m[!] Your system is not supported yet.'
            exit 1
        fi
    fi
fi

# Create a directory where tools will be installed
cd ~
mkdir WebPeas >/dev/null 2>&1
cd WebPeas
mkdir dirsearch >/dev/null 2>&1

# Check if CMSeeK is installed
if ! [ -x "$(command -v cmseek)" ]; then
    git clone https://github.com/Tuhinshubhra/CMSeeK >/dev/null 2>&1
    cd CMSeeK
    pip install -r requirements.txt >/dev/null 2>&1
    cd ~/WebPeas 
fi

# Check if wpscan is installed
if ! [ -x "$(command -v wpscan)" ]; then
    gem install nokogiri wpscan > /dev/null 2>&1
fi

# Checking if dirsearch is installed
if ! [ -x "$(command -v dirsearch)" ]; then
    pip install dirsearch > /dev/null 2>&1
fi

# Checking if dirsearch is installed
if ! [ -x "$(command -v joomscan)" ]; then
    cd ~/WebPeas
    git clone https://github.com/rezasp/joomscan.git > /dev/null 2>&1
fi

# Checking if subfinder is installed
if ! [ -x "$(command -v subfinder)" ]; then
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest > /dev/null 2>&1
fi

# Checking if droopescan is installed
if ! [ -x "$(command -v droopescan)" ]; then
    pip install droopescan > /dev/null 2>&1
fi

# checking if httprobe is installed
if ! [ -x "$(command -v httprobe)" ]; then
    go install github.com/tomnomnom/httprobe@latest > /dev/null 2>&1
fi

# Checking if httpx is installed
if ! [ -x "$(command -v httpx)" ]; then
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest > /dev/null 2>&1
fi

# checking if nuclei is installed
if ! [ -x "$(command -v nuclei)" ]; then
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest > /dev/null 2>&1
fi

# checking if waybackurls is installed
if ! [ -x "$(command -v nuclei)" ]; then
    go install github.com/tomnomnom/waybackurls@latest > /dev/null 2>&1
fi

# installing the s3-bucker-scanner tool
cd ~/WebPeas
git clone https://github.com/GermanAizek/S3-Bucket-Scanner > /dev/null 2>&1
cd S3-Bucket-Scanner
pip install -r requirements.txt > /dev/null 2>&1
echo -e "\e[32m[+] Everything is ready now !\e[0m"
echo -e "\e[32m
 #     #               ######                       
 #  #  # ###### #####  #     # ######   ##    ####  
 #  #  # #      #    # #     # #       #  #  #      
 #  #  # #####  #####  ######  #####  #    #  ####  
 #  #  # #      #    # #       #      ######      # 
 #  #  # #      #    # #       #      #    # #    # 
  ## ##  ###### #####  #       ###### #    #  ####  
\e[0m
"

echo -e "\e[32m[+] Target: $target\e[0m"
echo
echo -e "\e[32m[+] Scanning will begin\e[0m"
if (sleep 1; echo "y") | python3 ~/WebPeas/CMSeeK/cmseek.py -v -u $target --random-agent | grep -q "Detection failed"; then
  echo -e "\e[31m[!] CMS is not detected\e[0m"
else
  cms_name=$((sleep 1; echo "y") | python3 ~/WebPeas/CMSeeK/cmseek.py -v -u "$target" --random-agent | grep "CMS:" | awk '{print $3}')
  echo -e "\e[32m[+] CMS detected: $cms_name\e[0m"
fi
echo
echo -e "\e[32m[+] Endpoint Enumeration\e[0m"
dirsearch  -u "$target" -x 300-302,303-399,400-499,500-509 -q -o ~/WebPeas/dirsearch/list.txt | awk '(NR > 1)'
echo
if cat ~/WebPeas/dirsearch/list.txt | grep -q -e "/node/7" -e "/node" -e "/admin/content/" -e "/admin/content/comment" -e "/user/login" -e "/user/3"; then
    echo -e "\e[32m[+] Drupal Scanning\e[0m"
    droopescan scan drupal -u "$target/node" --random-agent | awk '(NR > 14)' || droopescan scan drupal -u "$target/user/login" --random-agent | awk '(NR > 14)'
elif [ $cms_name == "\033[1m\033[32mDrupal\033[0m" ]; then
    echo -e "\e[32m[+] Drupal Scanning\e[0m"
     droopescan scan drupal -u "$target" --random-agent | awk '(NR > 14)'
fi

if cat ~/WebPeas/dirsearch/list.txt | grep -q -e "/administrator" -e "/Joomla" -e "/joomla"; then
    echo -e "\e[32m[+] joomla Scanning\e[0m"
    perl ~/WebPeas/joomscan/joomscan.pl --url "$target/administrator" --random-agent | awk '(NR > 14)' || perl ~/WebPeas/joomscan/joomscan.pl --url "$target/administrator" --random-agent | awk '(NR > 14)' || perl ~/WebPeas/joomscan/joomscan.pl --url "$target/administrator" --random-agent | awk '(NR > 14)' ||     perl ~/WebPeas/joomscan/joomscan.pl --url "$target/joomla" --random-agent | awk '(NR > 14)'
elif [ "$cms_name" == "\033[1m\033[32mJoomla\033[0m" ]; then
    echo -e "\e[32m[+] joomla Scanning\e[0m"
    perl ~/WebPeas/joomscan/joomscan.pl --url "$target"--random-agent | awk '(NR > 14)'
fi

if cat ~/WebPeas/dirsearch/list.txt | grep -q -e "/wordpress"; then
    echo -e "\e[32m[+] Wordpress Scanning\e[0m"²
    wpscan --url "$target/wordpress" -e vp,vt,u --random-user-agent --no-banner | awk '(NR > 4)' | head -n -10
elif [ "$cms_name" == "\033[1m\033[32mWordpress\033[0m" ]; then
    echo -e "\e[32m[+] Wordpress Scanning\e[0m"
    wpscan --url "$target" -e vp,vt,u --random-user-agent --no-banner | awk '(NR > 4)' | head -n -10
fi
echo
echo -e "\e[32m[+] Subdomain Enumeration\e[0m"
echo $target | subfinder -silent | httpx -silent | httprobe > ~/WebPeas/sub_enum.txt
cat ~/WebPeas/sub_enum.txt
echo
echo -e "\e[32m[+] HTTP Subdomains\e[0m"
cat ~/WebPeas/sub_enum.txt | grep -E "http:" | httprobe | sed 's/^/\e[32m[+]\e[0m /' 
echo
echo -e "\e[32m[+] HTTPS Subdomains: \e[0m"
cat ~/WebPeas/sub_enum.txt | grep -E "https" | httprobe | sed 's/^/\e[32m[+]\e[0m /'
echo
if cat ~/WebPeas/sub_enum.txt | grep -E -e "aws" -e ".cloud" -e "-dev" -e "s3" -e "s2" -e "aws" -e "amazonaws.com" | httprobe -c 50; then
    echo -e "\e[32m[+] S3 Buckets: \e[0m"
    cat ~/WebPeas/sub_enum.txt | grep -E -e "aws" -e ".cloud" -e "-dev" -e "s3" -e "s2" -e "aws" -e "amazonaws.com" | httprobe -c 50 > ~/WebPeas/buckets.txt
    echo
    echo -e "\e[32m[+] S3 Scanning: \e[0m"
    nohup python3 s3scanner.py -d buckets.txt -o dump.txt | awk '(NR > 2)' > /dev/null 2>&1&
    echo -e "\e[31m[!] it will take some time \e[0m"
else
    echo -e "\e[32m[!] There's no S3 Buckets \e[0m"
fi
echo
echo -e "\e[32m[+] Subdomain Endpoint Enumeration \e[0m"
dirsearch -l ~/WebPeas/sub_enum.txt -x 400-499,500-509 -q -o ~/WebPeas/dirsearch/sub-list-enum.txt | awk '(NR > 1)'
echo
cat -s ~/WebPeas/sub_enum.txt ~/WebPeas/dirsearch/sub-list-enum.txt ~/WebPeas/dirsearch/list.txt | httprobe -c 50 > ~/WebPeas/domain.txt
echo -e "\e[32m[+] Vulnearability Scanning \e[0m"
nuclei -l ~/WebPeas/domain.txt
echo 
echo -e "\e[32m[+] GraphQL Discovery \e[0m"
python3 graph.py domain.txt
echo
echo -e "\e[32m[+] Wayback URLs \e[0m"
cat ~/WebPeas/domain.txt | waybackurls > ~/WebPeas/known_urls.txt
echo
echo -e "\e[32m Bye \e[0m"