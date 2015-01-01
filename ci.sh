#!/bin/bash
echo hello world
echo good bye
copy_files() {
    local new_copy="$1"
    local old_copy="$2"
    local versioned=`git rev-parse --short HEAD`"_$1"
    if diff "$new_copy" "$old_copy" 2>/dev/null ; then
	echo Same file nothing to do
    else
	echo File changed make copies.
	cp "$1" "$2"
	cp "$1" "/home/gitlab_ci_runner/artifacts/bluemoon/build/"`git rev-parse --short HEAD`_"$1"
    fi    
}

git submodule update --init
ls -la
cd hardware
make clean
make CUSTOMPCB="/usr/src/pcb/src/pcb" \
     CUSTOMPCB_ARGS="--photo-mask-colour red \
     --photo-silk-colour white --photo-plating  tinned"
make CUSTOMPCB="/usr/src/pcb/src/pcb" \
     CUSTOMPCB_ARGS="--photo-mask-colour red \
     --photo-silk-colour white  --photo-plating  tinned" photos
ls black_board.png board.png bom order xy schematic.png schematic.pdf gerbers/bluemoon_make.bottom.gbr > /dev/null 2>&1
if [ "$?" != "0" ]; then
    echo "I failed to create all the files I should have. build failed"
    exit 1
fi
New_bluemoon=`git diff HEAD^ HEAD -- bluemoon.pcb|wc -l`
New_schematic=`git diff HEAD^ HEAD -- bluemoon.sch|wc -l`

if [ "$New_bluemoon" == "0" ]; then
    echo "No changes to bluemoon don't bother saving image."
else
    copy_files board.png ~/artifacts/bluemoon/board.png
    zip -r gerbers.zip gerbers/
    copy_files gerbers.zip ~/artifacts/bluemoon/gerbers.zip
fi

if [ "$New_schematic" == "0" ]; then
    echo "No changes to schematic don't bother saving the image."
else
    copy_files schematic.png ~/artifacts/bluemoon/schematic.png
fi
cd ..

cd firmware
make clean
cp ~/blah/bluemoon.txt ~/.arduino15/preferences.txt
make ARDUINO_DIR=/usr/src/arduino-1.5.6-r2/
ls bin/application.hex
if [ "$?" != "0" ]; then
    echo "I failed to create all the files I should have. build failed"
    exit 1
fi
cd bin

copy_files application.hex ~/artifacts/bluemoon/application.hex

cd ..

cd ..
cd android/RFDuinoTest
JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/  ANDROID_HOME=/opt/adt-bundle-linux-x86_64-20140702/sdk/ gradle clean
JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/  ANDROID_HOME=/opt/adt-bundle-linux-x86_64-20140702/sdk/ gradle build
cd build/apk/
copy_files RFDuinoTest-debug-unaligned.apk ~/artifacts/bluemoon/bluemoon.apk
ls RFDuinoTest-debug-unaligned.apk
if [ "$?" != "0" ]; then
    echo "I failed to create all the files I should have. build failed"
    exit 1
fi

cd ../..
cd ../..

