# 📱 QR Scanner App - Gestión de Inventario

Una aplicación Flutter multiplataforma para escanear códigos QR y gestionar inventario de productos de forma rápida y eficiente.

---

## ✨ Características Principales

✅ **Escáner QR en tiempo real**
- Captura rápida de códigos QR con la cámara del dispositivo
- Procesamiento instantáneo de datos
- Linterna integrada para ambientes oscuros

✅ **Gestión Completa de Productos (CRUD)**
- Crear nuevos productos
- Editar información de productos existentes
- Eliminar productos del inventario
- Visualizar listado de todos los productos

✅ **Variantes de Productos**
- Configurar talla, color y precio por variante
- Múltiples variantes por producto
- Precios personalizados por variante

✅ **Generación de Códigos QR Dinámicos**
- Generar QR con información del producto
- Formateo inteligente: `productId|variantId|talla|color`
- Permite validar y vincular productos

✅ **Actualización de Cantidades**
- Aumentar/disminuir cantidad de inventario
- Cambios en tiempo real
- Persistencia automática de datos

✅ **Persistencia de Datos**
- Almacenamiento local con SharedPreferences
- Los datos se guardan automáticamente
- Sincronización entre pantallas

---

## 🛠️ Tecnologías Utilizadas

- **Framework:** Flutter
- **Lenguaje:** Dart
- **Escaneo QR:** `mobile_scanner` v3.5.7
- **Generación QR:** `qr` v3.0.1
- **Persistencia:** `shared_preferences` v2.2.3
- **State Management:** Provider
- **Serialización:** `json_serializable`

---

## 📋 Requisitos del Sistema

- Flutter 3.0+
- Dart 3.0+
- Android 5.0+ (API level 21+) para dispositivos móviles
- Windows 10+ para versión de escritorio

---

## 🚀 Instalación y Ejecución

### En Dispositivo Físico Android

1. **Conecta tu dispositivo Android por USB**
   ```bash
   flutter devices
   ```

2. **Ejecuta la aplicación**
   ```bash
   flutter run
   ```

### En Windows

```bash
flutter run -d windows
```

### En Navegador (Edge/Chrome)

```bash
flutter run -d edge
```

---

## 📦 Instalación de APK

Para instalar la aplicación compilada:

1. **Compila la APK release**
   ```bash
   flutter build apk --release
   ```

2. **Copia el APK**
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk app-release.apk
   ```

3. **Instala en tu dispositivo**
   - Descarga el archivo desde Google Drive o WhatsApp
   - Abre el APK desde tu gestor de archivos
   - Acepta los permisos de instalación

---

## 📱 Funcionalidades de Uso

### 1. **Crear Producto**
- Ve a "Agregar Producto"
- Ingresa nombre y descripción
- Agrega variantes (talla, color, precio)
- Guarda el producto

### 2. **Generar Código QR**
- Ve a "Código QR"
- Selecciona el producto y variante
- Se genera automáticamente un código QR
- Captura o descarga para imprimir

### 3. **Escanear Código QR**
- Ve a "Escanear QR"
- Apunta la cámara al código QR
- El sistema busca el producto automáticamente
- Se abre la pantalla de actualización de cantidad

### 4. **Actualizar Inventario**
- Usa + y - para ajustar cantidad
- Toca "Guardar" para persistir cambios
- Los cambios se guardan localmente

### 5. **Ver Inventario**
- Accede a "Inventario"
- Visualiza todos los productos
- Edita o elimina según sea necesario

---

## 🔐 Permisos Requeridos

### Android
- `CAMERA` - para acceder a la cámara y escanear QR
- `INTERNET` - para sincronización futura
- `WRITE_EXTERNAL_STORAGE` - para guardar archivos (opcional)

---

## 📊 Estructura del Proyecto

```
lib/
├── main.dart                      # Punto de entrada
├── models/
│   ├── product.dart              # Modelo de Producto
│   ├── product.g.dart            # Generado por json_serializable
│   └── variant.dart              # Modelo de Variante
├── screens/
│   ├── add_product_screen.dart
│   ├── inventory_screen.dart
│   ├── qr_generator_screen.dart
│   ├── qr_scanner_screen.dart
│   └── update_quantity_screen.dart
└── services/
    └── product_service.dart       # Lógica de negocio

android/                           # Configuración Android
ios/                               # Configuración iOS
web/                               # Versión web
```

---

## 🔄 Próximas Mejoras Planeadas

- [ ] Sincronización con backend (Firebase/Supabase)
- [ ] Reportes y estadísticas de inventario
- [ ] Historial de cambios
- [ ] Exportar datos a Excel/PDF
- [ ] Interfaz para iOS
- [ ] Multi-usuario con autenticación
- [ ] Búsqueda avanzada de productos

---

## � Autores

- **Jorge Ivan Jaramillo** - [GitHub](https://github.com/jorge-222)
- **Juan Esteban Vergara**
