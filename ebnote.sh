backup="/home/$USER/Documents/.Boostnote.tar.gz.gpg.backup"
encrypted="/home/$USER/Documents/.Boostnote.tar.gz.gpg"
decrypted="Boostnote.tar.gz"

#Prev Cleanup
if [ -d /tmp/Boostnote ]; then
    rm -r /tmp/Boostnote
fi

#Decrypt & Decompress
cd /tmp/
pass=`zenity --entry --text="Enter your passphrase" --hide-text --title="Encrypted Boostnote"`
gpg --lock-multiple --batch --passphrase $pass -d $encrypted | tar xzf - Boostnote

#if succesfully decrypted
if [ -d /tmp/Boostnote ]; then
    #Backup
    cp -u $encrypted $backup

    #Run
    boostnote

    #Compress & Encrypt
    tar czf - Boostnote/ | gpg --batch --passphrase $pass -o $encrypted --symmetric --force-mdc --yes
    rm -r Boostnote/
else
    notify-send "Wrong Passphrase!"
fi
