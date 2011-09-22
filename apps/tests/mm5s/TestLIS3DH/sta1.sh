# same as sta.sh, but for USB1
cp ./dot_mspdebug ~/.mspdebug
mspdebug uif -qjd /dev/ttyUSB1
