:: Build container
docker build --file Dockerfile --tag=forderud/qtwasm:qt5 .

IF %ERRORLEVEL% EQU 0 (
  :: Push to dockerhub
  docker push forderud/qtwasm:qt5
)
