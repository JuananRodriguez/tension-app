# Tensión App - Configuración de Variables de Entorno

## Archivos de entorno

### 1. Copiar el archivo de ejemplo
```bash
cp .env.example .env
```

### 2. Configurar las variables
Edita el archivo `.env` con tu configuración:

```env
# API Configuration
API_BASE_URL=https://your-api-url.up.railway.app

# Environment
ENV=production
```

### 3. Variables disponibles

| Variable       | Descripción          | Ejemplo                     |
| -------------- | -------------------- | --------------------------- |
| `API_BASE_URL` | URL base de la API   | `https://your-api.app`      |
| `ENV`          | Entorno de ejecución | `development`, `production` |

### 4. Entornos

#### Desarrollo
```env
API_BASE_URL=http://192.168.68.65:3000
ENV=development
```

#### Producción
```env
API_BASE_URL=https://tension-monitor-production.up.railway.app
ENV=production
```

### 5. Notas importantes

- El archivo `.env` está incluido en `.gitignore` para no subir credenciales
- Usa `.env.example` como plantilla para nuevas configuraciones
- La aplicación tiene un fallback a `http://192.168.68.65:3000` si no se define `API_BASE_URL`

### 6. Instalación

Asegúrate de tener las dependencias instaladas:
```bash
flutter pub get
```
