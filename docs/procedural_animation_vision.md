# Proyecto: Animación Procedimental Humana (Godot 4.6 IK)

## 🎯 Visión del Proyecto
Crear un sistema de animación humana 100% programático y dinámico, eliminando la dependencia de MoCap o animaciones pre-grabadas. El sistema utiliza el motor de **Cinemática Inversa (IK)** de Godot 4.6 para generar movimientos orgánicos, reactivos y adaptables en tiempo real.

## 🏗️ Arquitectura de "Pose por Nodos" (Helper-Centric)
La filosofía de diseño se basa en delegar el "Acting" (la intención del movimiento) a la jerarquía visual de Godot, simplificando el código al máximo.

### 1. Nodos de Pose (Fantasmas)
En lugar de calcular posiciones matemáticas en el script, se utilizan grupos de `Marker3D` en el editor para definir los "Keyframes" del sistema:
- **Pose_Guardia**: 4 Marcadores (Manos y Codos) que definen la postura base.
- **Pose_Bloqueo**: Marcadores que definen la defensa cerrada.
- **Pose_Impacto**: Marcadores que definen el punto máximo de extensión de un golpe.

### 2. El Cerebro de Mezcla (Blending Engine)
El script de Godot actúa como una mesa de mezclas:
- Interpola (`lerp`) entre los diferentes grupos de Helpers según el estado del bot (Idle, Atacando, Defendiendo).
- Aplica **Inercia y Masa**: Los targets no llegan instantáneamente; tienen una aceleración y frenado que simula el peso de las extremidades.

## 🛠️ Estado Actual
- [x] Implementación base de IK (TwoBoneIK3D) para brazos y piernas.
- [x] Sistema de detección de esqueleto dinámico para modelos FBX.
- [x] Control de Input para Ataque (BIR) y Bloqueo (Shift).
- [x] Inyección de Helpers visuales (`Pose_Guardia`, `Pose_Bloqueo`, `Pose_Punch`).
- [x] Locomoción Procedimental: Sistema de pasos automáticos con compensación de velocidad.
- [x] Braceo Procedimental: Balanceo de brazos sincronizado con la marcha.
- [x] Motor de suavizado dinámico (`lerp`) y equilibrio de torso operativos.

## 🚀 Próximos Hitos
1. **Consolidación de Poses**: Sustituir los cálculos de "Guardia" actuales por un contenedor de nodos `Pose_Guardia` que el usuario pueda editar visualmente.
2. **Coordinación de Peso (Full Body)**: Hacer que la cadera y el torso reaccionen a la extensión de los brazos para dar sensación de potencia.
3. **Física Activa**: Integrar colisiones para que el puñetazo se detenga físicamente al impactar, en lugar de atravesar objetos.
4. **Arcos de Movimiento**: Implementar trayectorias curvas para los golpes (Hooks y Uppercuts) mediante puntos intermedios (Bézier procedimental).

---
*Este documento actúa como guía técnica para el desarrollo del prototipo de animación procedimental.*
