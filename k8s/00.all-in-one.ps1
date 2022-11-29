# change context to point k8s cluster
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# build required images
docker build ../containers/database -t hyuabot-database-initialize
docker build ../containers/bus/timetable/ -t hyuabot-bus-timetable-job-image
docker build ../containers/bus/realtime -t hyuabot-bus-cron-job-image
docker build ../containers/subway/timetable/ -t hyuabot-subway-timetable-job-image
docker build ../containers/subway/realtime/ -t hyuabot-subway-cron-job-image
docker build ../containers/library/ -t hyuabot-reading-room-cron-job-image
docker build ../containers/cafeteria/ -t hyuabot-cafeteria-cron-job-image

# delete existing k8s resources
kubectl delete -f ./02.create-k8s-secret-keys.yml
kubectl delete -f ./03.create-persistent-volume.yml
kubectl delete -f ./04.claim-persistent-volume.yml
kubectl delete configmap create-database
kubectl delete -f ./05.deployment.yml
kubectl delete -f ./06.expose-container.yml
kubectl delete -f ./07.migration-database.yml
kubectl delete -f ./08.initialize-database.yml
kubectl delete -f ./09.start-bus-timetable-job.yml
kubectl delete -f ./10.start-bus-realtime-cron-job.yml
kubectl delete -f ./11.start-subway-timetable-job.yml
kubectl delete -f ./12.start-subway-realtime-cron-job.yml
kubectl delete -f ./13.start-reading-room-cron-job.yml
kubectl delete -f ./14.start-cafeteria-cron-job.yml

# apply k8s resources
kubectl create -f ./01.create-k8s-namespace-dev.yml
kubectl config set-context --current --namespace=hyuabot-dev
kubectl apply -f ./02.create-k8s-secret-keys.yml
kubectl apply -f ./03.create-persistent-volume.yml
kubectl apply -f ./04.claim-persistent-volume.yml
kubectl create configmap create-database --from-file=../database/create_database.sql
kubectl apply -f ./05.deployment.yml
kubectl apply -f ./06.expose-container.yml
kubectl apply -f ./07.migration-database.yml
kubectl apply -f ./08.initialize-database.yml
kubectl apply -f ./09.start-bus-timetable-job.yml
kubectl apply -f ./10.start-bus-realtime-cron-job.yml
kubectl apply -f ./11.start-subway-timetable-job.yml
kubectl apply -f ./12.start-subway-realtime-cron-job.yml
kubectl apply -f ./13.start-reading-room-cron-job.yml
kubectl apply -f ./14.start-cafeteria-cron-job.yml

# remove unused images
docker image prune -a -f