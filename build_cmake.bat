:: clean up any previous builds
rmdir build /s /q

mkdir build

:: Input sources must be found in "sample" subfolder
:: Output binaries will be written to "build" subfolder
docker run --rm -v %cd%\sample:/project/source -v %cd%\build:/project/build forderud/qtwasm:qt6.5 || exit /b 1

run_webserver.bat
