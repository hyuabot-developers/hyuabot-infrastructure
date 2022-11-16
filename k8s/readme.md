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

5. k8s namespace 생성
```bash
kubectl create -f ./01.create-k8s-namespace-dev.yml
kubectl create -f ./01.create-k8s-namespace-prod.yml
```

6. k8s secret 생성
```bash
kubectl config set-context --current --namespace=hyuabot-dev # dev namespace로 설정
kubectl apply -f ./02.create-k8s-secret-keys.yml
```

7. PostgreSQL 배포를 위한 PersistentVolume 생성
```bash
kubectl apply -f ./03.create-persistent-volume.yml
kubectl apply -f ./04.claim-persistent-volume.yml
```

8. PostgreSQL 스키마 생성을 위한 ConfigMap 생성
```bash
kubectl create configmap create-database --from-file=../database/create_database.sql
```

9. PostgreSQL 배포
```bash
kubectl apply -f ./05.deployment.yml
```

10. PostgreSQL를 Pod 외부로 노출
```bash
kubectl apply -f ./06.expose-database.yml
```

11. PostgreSQL 데이터베이스 스키마 생성
```bash
kubectl apply -f ./07.migration-database.yml
```

12. PostgreSQL 데이터베이스에 초기 데이터 적재
```bash
# Localhost의 docker daemon을 가르키도록 수정
minikube docker-env
eval $(minikube -p minikube docker-env)
# 초기화를 위한 docker 이미지 빌드
docker build ../database/initializer -t hyuabot-database-initialize
kubectl apply -f ./08.initialize-database.yml
```