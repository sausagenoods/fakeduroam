# Fakeduroam
A tool for pentesting careless universities' networks.

## Usage
### Install
You will need to have `macchanger` and `make` installed.
Simply run:
```sh
$ sudo ./fakeduroam init
```
Configure your network interface, log directory and SSID in the script (default is `eduroam`).

### Run
```sh
$ sudo ./fakeduroam run
```

### Parse
Parse the captured hashes:
```sh
$ sudo ./fakeduroam parse jtr # or hashcat
```
The resulting hashes will be saved in `hashes.txt` inside of your specified log directory.

## Cracking
Example John The Ripper command:
```sh
$ john hashes.txt --wordlist=rockyou.txt
```
