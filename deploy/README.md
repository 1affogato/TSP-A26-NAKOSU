# Despliegue web de Nakosu (Docker + Cloudflare Tunnel)

El juego es un export web de Godot: solo archivos estáticos. Cada jugador lo
corre en su navegador y su progreso se guarda en ese navegador, así que muchas
personas pueden jugar a la vez sin afectarse. Ojo: dos personas en la misma
computadora y el mismo navegador comparten progreso (usen incógnito).

## 1. Exportar el juego

Requiere las plantillas de exportación de Godot 4.7.2 (Editor > Manage Export Templates).
Desde `softlearning/`:

```
godot --headless --path . --export-release "Web" ../deploy/web/index.html
```

## 2. Levantarlo

Desde `deploy/` (con Docker Desktop abierto):

```
docker compose up -d --build
```

Local: http://localhost:8088 (en esta PC el 8080 lo usa Oracle; otro puerto con `PORT=9000`)

## 3. Link público

```
docker compose --profile publico up -d --build
docker compose logs tunnel
```

El log muestra un link `https://<algo>.trycloudflare.com`: ese se comparte.
Cambia cada vez que se levanta el túnel. Para un link fijo, creen un túnel con
nombre en Cloudflare Zero Trust (Networks > Tunnels), apúntenlo a `http://web:80`
y levántenlo con `TUNNEL_TOKEN=<token> docker compose --profile fijo up -d`.

Para apagar todo: `docker compose --profile publico --profile fijo down`.
