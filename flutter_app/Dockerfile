FROM nginx:alpine

# Copy các file Flutter web đã build
COPY build/web /usr/share/nginx/html

# Copy file cấu hình Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Mở cổng 80
EXPOSE 80

# Chạy Nginx
CMD ["nginx", "-g", "daemon off;"]