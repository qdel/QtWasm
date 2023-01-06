:: Uncomment to ease debugging of failed builds
::set DOCKER_BUILDKIT=false

:: Build container
docker build --file Dockerfile --tag=forderud/qtwasm:qt6.5 .

IF %ERRORLEVEL% EQU 0 (
  :: Push to dockerhub
  docker push forderud/qtwasm:qt6.5
)
