FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

COPY pom.xml ./pom.xml

COPY inventory-service/pom.xml ./inventory-service/pom.xml
COPY inventory-service/src ./inventory-service/src

WORKDIR /build/inventory-service
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

COPY --from=build /build/inventory-service/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java -jar app.jar"]
