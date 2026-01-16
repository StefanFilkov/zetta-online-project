FROM maven:3.9-eclipse-temurin-17-alpine AS build

WORKDIR /build

COPY pom.xml ./pom.xml

COPY order-service/pom.xml ./order-service/pom.xml
COPY order-service/src ./order-service/src

WORKDIR /build/order-service
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

COPY --from=build /build/order-service/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java -jar app.jar"]
