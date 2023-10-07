# HYUabot-Infrasturcture
- This is the repository to set up the infrastructure of HYUabot.

## Development Environment
- OS: Windows 11 Pro for Workstations
- CPU: AMD Ryzen 7 3700X(Allocate 8 cores to Docker)
- RAM: 64GB(Allocate 16GB to Docker)
- Docker for Desktop: 4.14.1 (91661)
- Docker Engine: 20.10.20
- Kubernetes: v1.25.3
- Minikube: v1.28.0

## Production Environment
- OS: Ubuntu 20.04.5 LTS
- CPU: Ampere Altra A1 4 core
- RAM: 24GB
- Docker: 20.10.21
- Kubernetes: v1.25.3
- Minikube: v1.28.0

## How to run
- Check the [README.md](./k8s/readme.md) in the k8s folder.

## Directory Structure
### containers
- This directory contains the Dockerfile and the configuration file for each container.

| Directory | Description | Repository | CI/CD |
| :---: | :---: | :---: | :---: |
| containers/database | load initial data to the database. | [hyuabot-database-initializer](https://github.com/jil8885/hyuabot-database-initializer) | ![CI/CD](https://github.com/jil8885/hyuabot-database-initializer/actions/workflows/default.yml/badge.svg)
| containers/bus/realtime | fetch realtime bus location | [hyuabot-bus-realtime-updater](https://github.com/jil8885/hyuabot-bus-realtime-updater) | ![CI/CD](https://github.com/jil8885/hyuabot-bus-realtime-updater/actions/workflows/default.yml/badge.svg)
| containers/bus/timetable | fetch bus timetable | [hyuabot-bus-timetable-updater](https://github.com/jil8885/hyuabot-bus-timetable-updater) | ![CI/CD](https://github.com/jil8885/hyuabot-bus-timetable-updater/actions/workflows/default.yml/badge.svg)
| containers/cafeteria | fetch cafeteria menu | [hyuabot-cafeteria-updater](https://github.com/jil8885/hyuabot-cafeteria-updater) | ![CI/CD](https://github.com/jil8885/hyuabot-cafeteria-updater/actions/workflows/default.yml/badge.svg)
| containers/library | fetch reading room information | [hyuabot-library-updater](https://github.com/jil8885/hyuabot-library-updater) | ![CI/CD](https://github.com/jil8885/hyuabot-library-updater/actions/workflows/default.yml/badge.svg)
| containers/subway/realtime | fetch realtime subway location | [hyuabot-subway-realtime-updater](https://github.com/jil8885/hyuabot-subway-realtime-updater) | ![CI/CD](https://github.com/jil8885/hyuabot-subway-realtime-updater/actions/workflows/default.yml/badge.svg)
| containers/subway/timetable | fetch subway timetable | [hyuabot-subway-timetable-updater](https://github.com/jil8885/hyuabot-subway-timetable-updater) | ![CI/CD](https://github.com/jil8885/hyuabot-subway-timetable-updater/actions/workflows/default.yml/badge.svg)
| containers/shuttle/timetable | fetch shuttle timetable | [hyuabot-shuttle-timetable-updater](https://github.com/jil8885/hyuabot-shuttle-timetable-updater) | ![CI/CD](https://github.com/jil8885/hyuabot-shuttle-timetable-updater/actions/workflows/default.yml/badge.svg)


### database
- This directory contains the configuration file for the database.
- create_database.sql: SQL script to create the database.

### k8s
- This directory contains the configuration file for the kubernetes.
- readme.md: How to run the kubernetes.