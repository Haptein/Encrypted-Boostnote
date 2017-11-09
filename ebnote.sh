#!/usr/bin/env bash

migration="To migrate your existent notes add your Boostnote storage folders to /tmp/Boostnote/ while the application is running.\nThen import them from within the application."
backup="/home/$USER/.Boostnote.tar.gz.gpg.backup"
encrypted="/home/$USER/.Boostnote-encrypted/Boostnote.tar.gz.gpg"
decrypted="Boostnote.tar.gz"

cd /tmp/

#Prev Cleanup
if [ -d /tmp/Boostnote ]; then
    rm -r /tmp/Boostnote
fi

#If first time
if [ ! -e $encrypted ]; then

    if [ ! -d "/home/$USER/.Boostnote-encrypted" ]; then
        mkdir "/home/$USER/.Boostnote-encrypted"
    fi

    mkdir /tmp/Boostnote
    zenity --info --title="Encrypted Boostnote" --icon-name=boostnote --text="$migration" --no-wrap 2>/dev/null

    while true; do
        #Create passphrase
        passphrase=`zenity --forms --add-password="Create a passphrase" --add-password="Confirm passphrase" --icon-name=boostnote --text="" --separator="\t" 2>/dev/null`
        
        case $? in
            0)
                pass1=`echo -e $passphrase | cut -f1`
                pass2=`echo -e $passphrase | cut -f2`
                if [[ $pass1 == $pass2 && $pass1 != "" ]]; then
                    pass=$pass1
                    break
                elif [[ $pass1 == $pass2 && $pass1 == "" ]]; then
                    notify-send -i boostnote "Empty passphrase."
                else
                    notify-send -i boostnote "Passphrases don't match."
                fi
                ;;
            1)
                exit 1
                ;;
            -1)
                zenity --error --title="Encrypted Boostnote" --text="Something went wrong :(" --no-wrap 2>/dev/null
                exit 2
                ;;
        esac
    done
else
    #Decrypt & Decompress
    pass=`zenity --entry --text="Enter your passphrase" --hide-text --title="Encrypted Boostnote"  2>/dev/null`
    gpg --lock-multiple --batch --passphrase $pass -d $encrypted | tar xzf - Boostnote
fi

#if succesfully decrypted or first run
if [ -d /tmp/Boostnote ]; then
    #Backup
    cp -u $encrypted $backup

    #Run
    boostnote

    #Compress & Encrypt
    tar czf - Boostnote/ | gpg --batch --passphrase $pass -o $encrypted --symmetric --force-mdc --yes
    rm -r Boostnote/
else
    notify-send -i boostnote "Wrong Passphrase!"
fi
