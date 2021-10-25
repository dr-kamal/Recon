#!/bin/bash

while getopts ":d:" input;do
        case "$input" in
                d) domain=${OPTARG}
                        ;;
                esac
        done
if [ -z "$domain" ]
        then
                echo "Please give a domain like \"-d domain.com\""
                exit 1
fi



echo -e "######Starting sublist3r ######\n"
sublist3r -d $domain -o sublister.txt

echo -e "######Starting subfinder ######\n"
subfinder -d $domain -o subfinder.txt

echo -e "######Starting assetfinder ######\n"
assetfinder --subs-only $domain > assetfinder.txt

echo -e "######Starting github subdomains enumeration ######\n"
python3 ~/tools/github-subdomains.py -t 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 -d $domain > github.txt

cat sublister.txt subfinder.txt assetfinder.txt github.txt > passive1.txt
rm sublister.txt subfinder.txt assetfinder.txt github.txt

echo -e "######Starting amass passive ######\n"
amass enum -passive -d $doamin | tee -a passive1.txt
cat passive1.txt | sort -u > passive.txt
echo
echo "###########Checking for alive subdomains################"
cat passive.txt | httprobe | tee -a alive2.txt
cat alive2.txt | sort -u | tee -a alive-passive.txt
rm alive2.txt passive1.txt
echo

read -p "Passive enumeration finished , Start Active Enumeration? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
exit 1
fi

echo -e "######Starting amass active ######\n"
amass enum -active -d $domain -ip | tee -a amass_ips.txt
cat amass_ips.txt | awk '{print $1}' | tee -a passive.txt
cat passive.txt | sort -u | tee -a all.txt

echo -e "######Starting Bruteforce######\n"
altdns -i all.txt -o data_output -w ~/tools/recon/words.txt -r -s dns_op.txt
cat dns_op.txt | sort -u | tee -a all.txt

echo "###########Checking for alive subdomains################"
cat all.txt | httprobe | tee -a alive2.txt
cat alive2.txt | sort -u | tee -a all-alive.txt
rm alive2.txt passive.txt alive-passive.txt amass_ips.txt dns_op.txt
