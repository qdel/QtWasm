:: Uncomment to ease debugging of failed builds
::set DOCKER_BUILDKIT=false

:: Build container
docker build --file Dockerfile --tag=forderud/qtwasm:debug .

IF %ERRORLEVEL% EQU 0 (
  :: Push to dockerhub
  docker push forderud/qtwasm:debug
)
