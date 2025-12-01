docker build -t applogs-report-static -f Docker/Dockerfile .
docker run -d -p 8080:80 --name applogs-report-static applogs-report-static
Write-Host "Site running: http://localhost:8080"
