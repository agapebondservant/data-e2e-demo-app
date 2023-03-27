# vmware-explore-demo-app



## Getting started

Make sure following softwares are running before setting this up:
- [ ] Java Jdk 11+
- [ ] npm 8.5.5+
- [ ] Angular 13.3+

## RabbitMQ

- Make sure RabbitMQ is running (container or application) and required queue is created (Queue name is mentioned in the app.properties file of Java project)

## Gemfire

- Use this [link](https://docs.vmware.com/en/VMware-GemFire/9.15/gf/getting_started-installation-install_standalone.html) to download and setup gemfire
- To setup Gemfire, run below commands:
  - Open terminal and run `gfsh`
  - Run `start locator --name=mds-locator`
  - Run `start server --name=mds-server  --start-rest-api=true --http-service-bind-address=localhost --J=-Dgemfire.http-service-port=8099`
  - Run `create region --name=mds-region --type=REPLICATE --enable-statistics --entry-idle-time-expiration=300`
- The above commands need to be run for the first time. For subsequent runs, execute `gfsh` from terminal and then execute `connect`

## Running Java project

- Import the project onto Intellij and setup configuration by adding the `main` file and start the application

## Running Angular application

- Navigate to demo-ui folder from terminal and run `ng serve --port 55625`
- Application will be opened in a browser and UI is ready to serve requests