#!/usr/bin/env bash

remote="gdrive"
migration="To migrate your existent notes add your Boostnote storage folders to /tmp/Boostnote/ while the application is running.\nThen import them from within the application."
foundnothing="Found nothing really."
backup="/home/$USER/.Boostnote.tar.gz.gpg.backup"
encrypted_dir="/home/$USER/.Boostnote-encrypted"
encrypted="$encrypted_dir/Boostnote.tar.gz.gpg"
decrypted="Boostnote.tar.gz"

function pull {
    (
    echo "#Downloading changes..."
    rclone sync $remote:Boostnote $encrypted_dir -u -v --retries 10
    if [ $? != 0 ]; then
        notify-send -i boostnote "Couldn't download copy from $remote."
    else
        notify-send -i boostnote "Changes downloaded from $remote successfully."
    fi
    ) | zenity --progress --pulsate --auto-close 2>/dev/null
}

function push {
    (
    echo "#Uploading changes..."
    rclone sync $encrypted_dir $remote:Boostnote -u -v --retries 10
    if [ ! $? == 0 ]; then
        notify-send -i boostnote "Couldn't upload copy to $remote."
    else
        notify-send -i boostnote "Changes uploaded to $remote successfully."
    fi
    ) | zenity --progress --auto-close 2>/dev/null[
}

function first_time_run {
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
}

cd /tmp/

#Prev Cleanup
if [ -d /tmp/Boostnote ]; then
    rm -r /tmp/Boostnote
fi

#If first time
if [ ! -e $encrypted ]; then

    if [ ! -d $encrypted_dir ]; then
        mkdir $encrypted_dir
    fi

    if [ $remote != "" ]; then
        pull
        #If couldn't find encrypted boostnote file in remote
        if [ ! -e $encrypted ]; then
            zenity --question --title="Encrypted Boostnote" --text="$foundnothing" 2>/dev/null
            if [ $? == 0 ]; then
                first_time_run
            else
                exit 1
            fi
        fi

    else
        first_time_run
    fi
elif [ $remote != "" ]; then
    pull
fi


#Decrypt & Decompress
pass=`zenity --entry --text="Enter your passphrase" --hide-text --title="Encrypted Boostnote"  2>/dev/null`
gpg --lock-multiple --batch --passphrase $pass -d $encrypted | tar xzf - Boostnote

#if succesfully decrypted or first run
if [ -d /tmp/Boostnote ]; then
    #Backup
    cp -u $encrypted $backup

    #Run
    boostnote

    #Compress & Encrypt
    tar czf - Boostnote/ | gpg --batch --passphrase $pass -o $encrypted --symmetric --force-mdc --yes
    rm -r Boostnote/

    #Push
    push

else
    notify-send -i boostnote "Wrong Passphrase!"
fi
