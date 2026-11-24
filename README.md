# Parcial 3: eventos, vista en vivo y esquema estrella

Big Data and Data Engineering, Universidad Sergio Arboleda. Equipo cristancho-urrego, seed 2682.
Harness: **70/70** (`docs/p3/report.md`).

El sistema de reservas (API FastAPI en EC2 + RDS PostgreSQL) publica cada búsqueda, reserva y cancelación
en Kinesis. Un consumidor dentro de la API responde la vista en vivo y Firehose copia los eventos a S3,
desde donde Athena reconstruye el esquema estrella.

## Qué hay en el repositorio
| Ruta | Contenido |
|---|---|
| `backend/app/events.py` | Publicación de eventos (cola + PutRecords para búsquedas, reservas tras el COMMIT) y consumidor de `GET /analytics/live` |
| `backend/app/star.py` | Job de carga: `POST /admin/refresh-star` reconstruye la estrella con Athena CTAS; `GET /admin/refresh-status` |
| `backend/app/main.py` | API (búsqueda, reservas, `POST /reservations/{id}/cancel`, check-in) |
| `frontend/` | Web del cliente, check-in y panel (nginx, puerto 3000) |
| `infra/p3/stream_up.sh` / `stream_down.sh` | Crean y borran el stream (1 shard provisionado, 24 h) y el Firehose a S3 |
| `infra/p3/setup_p3.sh` | Una vez: referencias de la seed, workgroup `airline-p3` (límite 1 GB) y base `airline_star` |
| `infra/p3/deploy_api.sh` | Despliega el backend en la EC2 |
| `config.yaml` | Configuración del harness (sin credenciales) |
| `cost_projection.yaml` | Proyección mensual de costos |
| `docs/p3/report.md` | Reporte final del harness |

## Esquema estrella (Glue `airline_star`, Parquet en `s3://.../star/`)
`dim_date` (2023 a 2027, con festivos y puentes), `dim_route` (tipo 2), `dim_fare_class`,
`fact_search` (partición `month`) y `fact_booking_event`.

## Cómo correrlo
```
bash infra/encender.sh            # RDS y EC2; imprime la IP y los links
bash infra/p3/setup_p3.sh 2682    # solo la primera vez
bash infra/p3/stream_up.sh        # el shard cobra por hora
bash infra/p3/deploy_api.sh
pytest                            # desde la carpeta del harness, con este config.yaml
bash infra/p3/stream_down.sh && bash infra/apagar.sh
```

La EC2 no tiene IP elástica, así que la IP cambia en cada arranque; `encender.sh` la escribe en `config.yaml`.
Links (con la IP que imprime `encender.sh`):
- Web cliente: `http://<IP>:3000`, check-in: `http://<IP>:3000/checkin`, panel: `http://<IP>:3000/manager`
- API: `http://<IP>:8000`, vista en vivo: `http://<IP>:8000/analytics/live?window=5`

Los puertos solo están abiertos a las IPs del equipo; `infra/abrir_calificacion.sh` los abre para la calificación
y `infra/cerrar_calificacion.sh` los cierra.
