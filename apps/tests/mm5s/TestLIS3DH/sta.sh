# copy 'dot_mspdebug' to .mspdebug in the home directory, then  start mspdebug 
#    on USB0
#
# careful:  gdb will not work unless the build directory contains a .gdbinit, e.g.
#                      cd build/mm5s
#                      ln -s ../../.gdbinit
#           See the README in tos/chips/msp430/99_gdb for more details.
cp ./dot_mspdebug ~/.mspdebug
mspdebug uif -qjd /dev/ttyUSB0
