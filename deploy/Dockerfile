# Sirve el export web de Godot (carpeta web/) con nginx.
# El juego corre completo en el navegador de cada jugador; el servidor solo
# entrega archivos estáticos y no guarda nada.
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY web/ /usr/share/nginx/html/
