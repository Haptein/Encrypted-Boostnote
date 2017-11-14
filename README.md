# Encrypted-Boostnote 
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://github.com/Haptein/Encrypted-Boostnote/blob/master/LICENSE)

Keep your [Boostnote](https://boostnote.io/) encrypted and synced!

# Installation
```bash
sudo ./INSTALL
```

# Usage
You can just select Ebnote from your app launcher or type _ebnote_ in a terminal.

# Syncing
Encripted-Boostnote integrates Boostnote with rclone in order to keep your notes synced between different machines.

To enable syncing edit the variable "remote" at the beginning of /usr/bin/ebnote (or ebnote.sh and run the install script) to the name of the rclone remote you with to use.

To add a remote to rclone follow [these instructions](https://rclone.org/docs/#configure) according to the cloud storage provider you want to use.

# Requirements
- Boostnote
- zenity (UI)
- GPG (encryption)

#### Optional:
- rclone (syncing)
- git (conflict management)