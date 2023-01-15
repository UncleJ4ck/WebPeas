import argparse
import re
import requests
import json

def find_graphql_queries(urls):
    pattern = r'(query|mutation|fragment)\s+[a-zA-Z]+(\s+[a-zA-Z0-9_]+)?(\([^(\(|\))]*\))*(\s+[a-zA-Z0-9_]+\s*:\s*[^,\s]+)*(\s*{\s*[^{}]+})*'
    for url in urls:
        response = requests.get(url)
        if response.status_code == 200:
            text = response.text
            queries = re.findall(pattern, text)
            print("\e[32m[+] Queries: \e[0m")
            print(json.dumps(queries, indent=2))
        else:
            print(f"Error: Failed to retrieve URL {url}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("file", help="File containing a list of URLs")
    args = parser.parse_args()
    with open(args.file, "r") as f:
        urls = f.readlines()
    f.close()
    find_graphql_queries(urls)
