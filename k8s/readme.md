# 휴아봇 k8s 설정

## 설치 환경
* 1개의 master 노드 + 1개의 worker 노드
* Minikube 기반으로 설정

## 설치
1. minikube 다운로드 (amd64 기준)
```bash
curl -LO minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
```

2. minikube 설치
```bash
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

3. minikube 버전
```bash
minikube version
```

4. minikube 시작
```bash
minikube start --driver=docker
```

5. 필요한 Docker 이미지 빌드
```bash
docker build ../containers/database -t hyuabot-database-initialize
docker build ../containers/shuttle/ -t hyuabot-shuttle-timetable-job-image
docker build ../containers/bus/timetable/ -t hyuabot-bus-timetable-job-image
docker build ../containers/bus/realtime -t hyuabot-bus-cron-job-image
docker build ../containers/subway/timetable/ -t hyuabot-subway-timetable-job-image
docker build ../containers/subway/realtime/ -t hyuabot-subway-cron-job-image
docker build ../containers/library/ -t hyuabot-reading-room-cron-job-image
docker build ../containers/cafeteria/ -t hyuabot-cafeteria-cron-job-image
docker build ../containers/api -t hyuabot-api-server
```

6. k8s namespace 생성
```bash
kubectl create -f ./01.create-k8s-namespace-dev.yml
kubectl create -f ./01.create-k8s-namespace-prod.yml
```

7. k8s secret 생성
```bash
kubectl config set-context --current --namespace=hyuabot-dev # dev namespace로 설정
kubectl apply -f ./02.create-k8s-secret-keys.yml
```

8. Dev 환경 배포
```bash
kubectl apply -f ./dev-enviornment.yaml
```