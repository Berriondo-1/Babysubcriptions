🍼 BabySubscription - Primer Avance
📌 Descripción

BabySubscription es una aplicación móvil desarrollada en Flutter que tiene como objetivo ayudar a los usuarios a gestionar el consumo de pañales de un bebé y controlar su inventario.

Este repositorio corresponde al primer avance del proyecto, donde se implementa la base de la aplicación, incluyendo estructura inicial, navegación y persistencia local de datos.

🎯 Objetivo del avance

En esta primera entrega se busca:

Definir la estructura del proyecto
Implementar navegación básica
Crear módulos iniciales funcionales
Guardar datos localmente
⚙️ Tecnologías utilizadas
Flutter
Dart
Provider (gestión de estado)
SQLite (sqflite)
📱 Funcionalidades implementadas
👶 Registro del bebé
Formulario para ingresar:
Nombre
Fecha de nacimiento
Etapa
Almacenamiento local de los datos
Visualización de la información guardada
📦 Inventario de pañales
Registro de:
Tipo de pañal
Talla
Cantidad disponible
Stock mínimo
Almacenamiento en base de datos local
Listado de productos registrados
🏠 Pantalla principal (Home)
Navegación hacia:
Registro del bebé
Inventario
🗂️ Estructura del proyecto
lib/
├── models/
├── services/
├── providers/
├── screens/
├── widgets/
└── main.dart
🧠 Estado actual del proyecto

Este proyecto se encuentra en una fase inicial.
Se ha priorizado la base funcional antes de implementar características más complejas.

🚧 Funcionalidades pendientes

Las siguientes funcionalidades serán desarrolladas en próximas entregas:

Registro de consumo diario
Cálculo de consumo promedio
Estimación de días restantes de stock
Alertas de stock bajo
Sistema de suscripción
Simulación de pagos
Historial de pedidos
Sincronización con Firebase
▶️ Cómo ejecutar el proyecto
Clonar el repositorio:
git clone <tu-repo>
Entrar al proyecto:
cd babysubscription
Instalar dependencias:
flutter pub get
Ejecutar la app:
flutter run
📌 Notas
Este proyecto es parte de una entrega académica.
La aplicación aún no incluye todas las funcionalidades planeadas.
El enfoque de este avance es la estructura y persistencia local.
👨‍💻 Autor
Kevin Libreros
Kevin Restrepo
