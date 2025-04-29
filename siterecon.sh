#!/bin/bash

# Check if the correct number of arguments is provided
if [ $# -ne 1 ]; then 
    echo "Usage: ./script.sh <domain>"
    echo "Example: ./script.sh example.com"
    exit 1
fi

# Set up directories for output
mkdir -p thirdlevels scans eyewitness

# Store the current working directory
pwd=$(pwd)

# Gather subdomains with Sublist3r
echo "Gathering subdomains with Sublist3r..."
sublist3r -d "$1" -o final.txt

# Compile third-level domains
echo "Compiling third-level domains..."
grep -Po "(\w+\.\w+\.\w+)$" final.txt | sort -u > third-level-domains.txt

# Gather full third-level domains with Sublist3r
echo "Gathering full third-level domains with Sublist3r..."
while read -r domain; do 
    sublist3r -d "$domain" -o thirdlevels/"$domain".txt
done < third-level-domains.txt

# Probe for alive third-level domains
echo "Probing for alive third-level domains..."
cat thirdlevels/*.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" > probed.txt

# Scan alive domains with nmap
echo "Running nmap scans..."
nmap -iL probed.txt -T3 -oA scans/scanned

# Run EyeWitness for alive domains
echo "Running EyeWitness..."
eyewitness -f "$pwd"/probed.txt -d "$1" --all-protocols

echo "Process completed!"