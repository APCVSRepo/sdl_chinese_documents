#!/bin/bash

RECORD_FILE="install_record.txt"

if [ -f $RECORD_FILE ]; then
    cat $RECORD_FILE | while read line
    do
		FILE="/${line}"
        if [ -f $FILE ]; then
            echo "Delete file $FILE"
            rm $FILE
        fi

        if [ -d $FILE ]; then
            if [ -z "`ls -A $FILE`" ]; then
                echo "Delete folder $FILE"
                rm -r $FILE
			else
				echo "Folder not empty. $FILE"
            fi
        fi
    done
else
    echo "Record file dose not exist."
fi
