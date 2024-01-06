#!/bin/bash

LOGIN=$1
HOST=$2

# remove .deb package
rm -f bac_0.1-1_*

# generate .deb packets
cd bac-0.1/debian && debuild -b
cd ../../

read -p "Upload packages to the server? [y/n]: " UPLOAD

case "$UPLOAD" in
    y)

        if [ -z $LOGIN ]; then
            echo -e "\033[31m"
            read -p "Error - enter login remote host: " LOGIN
            echo -e "\033[0m"
        fi

        if [ -z $HOST ]; then
            echo -e "\033[31m"
            read -p "Error - enter IP or domain remote host: " HOST
            echo -e "\033[0m"
        fi

        if [ -z $LOGIN ]; then
            echo -e "\033[31m Error - empty login remote host -break! \033[0m"
            exit 1
        fi

        if [ -z $HOST ]; then
            echo -e "\033[31m Error - empty IP or domain remote host -break! \033[0m"
            exit 1
        fi

        # push new deb packets to remote server
        scp bac_0.1-1_all.deb ${LOGIN}@${HOST}:/home/${LOGIN}

        read -p "Install package to the server? [y/n]: " INSTALL

        case "$INSTALL" in
            y)
                # connet to remote server
                ssh ${LOGIN}@${HOST} -t "sudo apt update; sudo apt remove bac gpg s3cmd; sudo apt autoremove; sudo apt install ./bac_0.1-1_all.deb; exit"
            ;;
            
            *)
                echo "Exited!"
                exit 0
            ;;
        esac
    ;;

    *)
        echo "Exited!"
        exit 0
    ;;
esac