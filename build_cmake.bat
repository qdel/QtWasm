mkdir build

:: Input sources must be found in "sample" subfolder
:: Output binaries will be written to "build" subfolder
docker run --rm -v %cd%\sample:/project/source -v %cd%\build:/project/build forderud/qtwasm:qt5
