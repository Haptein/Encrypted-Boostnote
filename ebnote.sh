#!/usr/bin/env bash

remote="gdrive"

#Messages
migration="To migrate your existent notes add your Boostnote storage folders to /tmp/Boostnote/ while the application is running.\nThen import them from within the application."
start_new="Couldn't find $encrypted. Would you like to create an new encrypted notes file?"

#Directories
encrypted_dir="/home/$USER/.Boostnote-encrypted"
settings_dir="/home/$USER/.config/Boostnote/Local Storage"
pull_dir="/tmp/Ebnote_pull"

#Recurrent Files
backup="/home/$USER/.Boostnote.tar.gz.gpg.backup"
encrypted="$encrypted_dir/Boostnote.tar.gz.gpg"
encrypted_settings="$encrypted_dir/BoostnoteLS.tar.gz.gpg"
decrypted="Boostnote.tar.gz"


function pull {
    pulled="0"
    cd /tmp/
    (
    echo "#Downloading changes..."
    rclone sync $remote:Boostnote "$pull_dir/" -u -v --retries 10
    if [ $? != 0 ]; then
        notify-send -i boostnote "Couldn't download copy from $remote."
    else
        notify-send -i boostnote "Changes downloaded from $remote successfully."
        pulled="1"
    fi
    ) | zenity --progress --pulsate --auto-close 2>/dev/null
    
    #If established conection with remote and downloaded files
    if [ $pulled=="1" ]; then

        #Get passphrase, decrypt and decompress local notes.
        pass=`zenity --entry --text="Enter your passphrase" --hide-text --title="Encrypted Boostnote"  2>/dev/null`
        gpg --lock-multiple --batch --passphrase $pass -d $encrypted | tar xzf - Boostnote

        #If found encrypted notes in remote
        if [ -e "$pull_dir/Boostnote.tar.gz.gpg" ]; then
            #Decrypt & Decompress remote files
            cd $pull_dir
            gpg --lock-multiple --batch --passphrase $pass -d "$pull_dir/Boostnote.tar.gz.gpg" | tar xzf - Boostnote

            #Pull changes from remote copy
            cd /tmp/Boostnote
            git pull origin master --allow-unrelated-histories -s recursive -X ours

            #Delete remote copy
            rm -rf $pull_dir

        else
            #Found nothing in remote
            notify-send -i boostnote "Couldn't find encrypted notes in $remote."
        fi

        cd /tmp/
    fi
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
    ) | zenity --progress --pulsate --auto-close 2>/dev/null
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
    rm -rf /tmp/Boostnote
fi

if [ -d $pull_dir ]; then
    rm -rf $pull_dir
fi

#If first time
if [ ! -e $encrypted ]; then

    if [ ! -d $encrypted_dir ]; then
        mkdir $encrypted_dir
    fi

    if [ $remote != "" ]; then
        #No local encrypted notes, remote enabled.
        pull
        #If still no encrypted local notes
        if [ ! -e $encrypted ]; then
            zenity --question --title="Encrypted Boostnote" --text="$start_new" 2>/dev/null
            if [ $? == 0 ]; then
                first_time_run
            else
                exit 1
            fi
        fi
    else
        #No local encrypted-notes, remote disabled.
        first_time_run
    fi
elif [ $remote != "" ]; then
    #Local found, remote enabled.
    pull
else
    #Local found, remote disabled.
    pass=`zenity --entry --text="Enter your passphrase" --hide-text --title="Encrypted Boostnote"  2>/dev/null`
    gpg --lock-multiple --batch --passphrase $pass -d $encrypted | tar xzf - Boostnote
fi


#if succesfully decrypted or first run
if [ -d /tmp/Boostnote ]; then
    #Backup
    cp -u $encrypted $backup

    #Make sure git is initialized
    cd /tmp/Boostnote
    git status 2>/dev/null
    if [ $? == 128 ]; then
        git init
    fi
    cd /tmp/

    #Run
    boostnote

    #commit changes
    cd /tmp/Boostnote
    git add . && git commit -m "[`hostname`]: `date`"
    cd /tmp/

    #Compress & Encrypt
    tar czf - Boostnote | gpg --batch --passphrase $pass -o $encrypted --symmetric --force-mdc --yes
    tar czf - "$settings_dir" | gpg --batch --passphrase $pass -o $encrypted_settings --symmetric --force-mdc --yes
    rm -rf Boostnote/
    rm -rf $pull_dir/

    #Push
    if [ $remote != "" ]; then
        push
    fi

else
    notify-send -i boostnote "Wrong Passphrase!"
fi