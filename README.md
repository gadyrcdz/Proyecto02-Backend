# Proyecto 2 - API REST Sistema Bancario
**IC8057 - Introducción al Desarrollo de Páginas Web**

API REST para sistema bancario con autenticación JWT y manejo de cuentas, tarjetas y transferencias.

## 🚀 Tecnologías

- Node.js
- Express.js
- PostgreSQL
- JWT (JSON Web Tokens)
- bcrypt

## 📋 Requisitos previos

- Node.js v18 o superior
- PostgreSQL 14 o superior
- npm o yarn

## ⚙️ Instalación

1. Clonar el repositorio
```bash
git clone <tu-repositorio>
cd proyecto2-api
```

2. Instalar dependencias
```bash
npm install
```

3. Configurar variables de entorno
```bash
cp .env.example .env
# Editar .env con tus credenciales
```

4. Iniciar el servidor
```bash
# Desarrollo (con auto-reload)
npm run dev

# Producción
npm start
```

## 🔗 Endpoints

### Autenticación (protegidos con API Key)
- `POST /api/v1/auth/login` - Iniciar sesión
- `POST /api/v1/auth/forgot-password` - Solicitar recuperación
- `POST /api/v1/auth/verify-otp` - Verificar código OTP
- `POST /api/v1/auth/reset-password` - Resetear contraseña

### Usuarios (protegidos con JWT)
- `POST /api/v1/users` - Crear usuario
- `GET /api/v1/users/:identification` - Obtener usuario
- `PUT /api/v1/users/:id` - Actualizar usuario
- `DELETE /api/v1/users/:id` - Eliminar usuario

*(Documentación completa en Postman)*

## 🔐 Autenticación

### API Key
Agregar header en peticiones públicas:
```
x-api-key: tu_api_key_aqui
```

### JWT
Agregar header en peticiones protegidas:
```
Authorization: Bearer tu_token_jwt_aqui
```

## 📝 Variables de entorno

Ver archivo `.env.example` para las variables requeridas.

## 👥 Autores

- Tu Nombre - [GitHub](https://github.com/tu-usuario)

## 📄 Licencia

Este proyecto es parte del curso IC8057 del TEC.