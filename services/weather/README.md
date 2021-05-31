# Template vibe.d with docker

# Usage

__docker build__

```
docker build -t app:dev .
```

__docker run__

```
docker run -it -p 8080:80 app:dev
```

# Routes

| path                    |
|:------------------------|
| `GET /health`           |
| `GET /weather?city=xxx` |

# Configurable Environment Variables

| Name               | Desc                                         |
|:-------------------|:---------------------------------------------|
| HOST               | Host address                                 |
| PORT               | Port                                         |
| OPENWEATHER_APIKEY | See https://home.openweathermap.org/api_keys |
