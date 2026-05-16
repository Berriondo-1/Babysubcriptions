# BabySubscription

Avance pequeno de una app Flutter para registrar informacion basica del bebe.

## Que incluye este avance pequeno

- Estructura simple por carpetas: `models`, `services`, `providers`, `screens` y `widgets`
- Persistencia local con SQLite usando `sqflite`
- Formulario de registro del bebe
- Manejo de estado simple con `Provider`

## Funcionalidad actual

Permite guardar localmente:

- nombre
- fecha de nacimiento
- etapa

## Que queda pendiente

- Inventario
- Firebase o sincronizacion remota
- Notificaciones
- Historial de pedidos
- Calculo avanzado de consumo
- Dashboard o reportes mas completos

## Dependencias principales

- `provider`
- `sqflite`
- `path`
- `intl`

## Ejecucion

```bash
flutter pub get
flutter run
```
