# Visión: Sistema de Animación Procedimental "Pose-by-Node"

Este documento define la arquitectura y el roadmap del sistema de animación procedimental para Godot 4.6, basado en la manipulación visual de poses a través de nodos Marker3D y un motor de interpolación dinámico.

## 🎯 El Concepto Core
Sustituir las animaciones tradicionales "baked" (pre-cocinadas) por un sistema donde el "Acting" reside en la jerarquía de nodos de Godot. El código no define la pose, solo la **interpolación** y la **física** entre poses definidas por el diseñador en el editor.

## ✅ Logros Alcanzados (V1.0 - Core Locomotion & Combat)
- [x] **Arquitectura Helper-Céntrica**: Uso de `Pose_Guardia`, `Pose_Bloqueo` y `Pose_Punch` como fuentes de verdad.
- [x] **Locomoción Inteligente**: Sistema de zancada con compensación de velocidad y umbrales dinámicos (Centrado de pies al parar).
- [x] **Micro-Vida Procedural**: Respiración (breathing) y micro-oscilaciones rítmicas en Idle.
- [x] **Física de Masa**: Rebote vertical (Bounce) y balanceo lateral de cadera (Hip Sway) sincronizados.
- [x] **Braceo en Oposición**: Balanceo de brazos procedimental con estabilización de codos.
- [x] **Equilibrio Dinámico**: Inclinación de torso automática según dirección de marcha y estado de bloqueo.

## 🚀 Próximos Hitos (V2.0 - Intelligence & Physics)

### 1. Adaptación al Terreno (IK Foot Placement)
Implementar `RayCast3D` en cada pierna para que los pies detecten colisiones y ajusten su altura `Y` y rotación para adaptarse a escalones, piedras y rampas.

### 2. Física Activa de Impacto
Integrar detección de colisiones en los puños para que el `Tween` de ataque se detenga físicamente al impactar contra un objeto o enemigo, activando una pose de "Impacto" procedimental.

### 3. Reacciones de Daño (Procedural Hit-Reaction)
Usar el sistema de IK para que el cuerpo del bot reaccione a impactos externos, desplazando el torso o las extremidades según la fuerza y dirección del golpe recibido.

### 4. Arcos de Movimiento (Bézier Striking)
Implementar trayectorias curvas para los ataques (Hooks, Uppercuts) mediante la adición de "Puntos de Paso" (Waypoints) dinámicos entre la guardia y el impacto.

---
*Actualizado: 2026-05-07 - Sistema estable y listo para integración de terreno.*
