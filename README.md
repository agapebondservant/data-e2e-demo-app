# vmware-explore-demo-app



## Getting started

Make sure following softwares are running before setting this up:
- [ ] Java Jdk 11+
- [ ] npm 8.5.5+
- [ ] Angular 13.3+

## RabbitMQ

- Make sure RabbitMQ is running (container or application) and required queue is created (Queue name is mentioned in the app.properties file of Java project)

## Gemfire

- Gemfire Shell is running with mentioned region from app.properties file of Java project

## Running Java project

- Import the project onto Intellij and setup configuration by adding the `main` file and start the application

## Running Angular application

- Navigate to demo-ui folder from terminal and run `ng serve --port 55625`
- Application will be opened in a browser and UI is ready to serve requests