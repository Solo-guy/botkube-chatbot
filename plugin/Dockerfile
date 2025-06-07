FROM golang:1.20-alpine
WORKDIR /app
COPY flutter-executor .
RUN cd flutter-executor && go build -o flutter-executor
COPY ai-manager .
RUN cd ai-manager && go build -o ai-manager
EXPOSE 8080 8081
CMD ["sh", "-c", "./flutter-executor & ./ai-manager"]
