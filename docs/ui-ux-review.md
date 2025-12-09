# Auditoría UI/UX del panel administrativo

## Resumen del estado actual
- **Navegación:** `TabView` lineal con cuatro secciones (Users, Activities, Feed, Territories) sin realce de pestaña activa ni accesos rápidos entre contextos relacionados.
- **Patrón de listas:** Todas las secciones usan `ScrollView` + `LazyVGrid` con tarjetas de fondo neutro y sombras ligeras; las acciones se concentran en toolbars superiores.
- **Cargas y vacíos:** Los `ProgressView` y `ContentUnavailableView` ocupan la capa central, ocultando el contenido previo durante la carga.
- **Filtros:** Los filtros son menús en la barra de navegación (tipo/usuario/búsqueda) y no quedan visibles en el lienzo de contenido.
- **Acciones peligrosas:** En Users y Feed/Territories los botones de borrado masivo y wipe están en la barra principal junto a acciones neutrales, lo que aumenta riesgo de toques accidentales.

## Observaciones visuales y funcionales por sección
- **Users**
  - Tarjetas muestran avatar, nivel y métricas, pero el botón de reset individual se ve como acción primaria (color naranja prominente) en cada celda.【F:adm-app/Views/Users/UsersListView.swift†L36-L75】
  - Las acciones "Delete All" y "Borrado maestro" están en la izquierda de la navegación, al mismo nivel visual que el alta de usuarios y cierre de ranking.【F:adm-app/Views/Users/UsersListView.swift†L92-L134】
- **Activities**
  - Métricas resumidas y breakdown de territorios están presentes, pero los filtros y el total de XP quedan separados (toolbar y una banda superior).【F:adm-app/Views/Activities/ActivitiesListView.swift†L50-L108】【F:adm-app/Views/Activities/ActivitiesListView.swift†L120-L199】
- **Feed**
  - Se mezclan chips de rareza, tipo y XP con estilos diferentes (capsula azul para tipo, fondo azul para bloque de usuario, chip de rareza con color variable).【F:adm-app/Views/Feed/FeedListView.swift†L62-L160】【F:adm-app/Views/Feed/FeedListView.swift†L193-L275】
  - Los filtros de tipo/usuario y el borrado masivo viven en la toolbar, sin indicar qué filtros están activos en la vista.【F:adm-app/Views/Feed/FeedListView.swift†L104-L146】
- **Territories**
  - Tarjetas resaltan estado activo/expirado, pero carecen de mapa/miniatura y usan la misma retícula básica.【F:adm-app/Views/Territories/TerritoriesListView.swift†L50-L138】【F:adm-app/Views/Territories/TerritoriesListView.swift†L170-L235】

## Reestructuración de flujo propuesta (basada en funcionalidad)
1. **Panel de filtros persistentes por sección**: mover filtros de toolbar a chips/segmentos fijados sobre la grilla, mostrando selección activa (p. ej., "Tipo: Challenge", "Usuario: Ana"). Esto reduce toques y hace visibles los estados de filtrado.
2. **Separación clara de acciones masivas**: agrupar "Delete All"/"Borrado maestro" en un menú de peligro (More/⚠️) o en un banner fijo al pie para evitar confusión con acciones de creación.
3. **Estado de carga no intrusivo**: usar overlays translúcidos con spinner en esquina en lugar de reemplazar todo el contenido, manteniendo contexto cuando llegan datos.
4. **Jerarquía por densidad**: permitir conmutar entre vista de grilla y lista compacta en Users y Feed para equipos que priorizan densidad de datos.
5. **Profundidad y conexión contextual**: enlazar métricas cruzadas; por ejemplo, desde una actividad permitir saltar al feed relacionado o a territorios afectados mediante chips accionables.

## Propuestas de mejora visual y UX
- **Navegación y consistencia**
  - Añadir un `tabBar` con fondo borroso y pastilla activa; incluir accesos rápidos a filtros globales (p. ej., búsqueda universal) desde la barra de pestañas.【F:adm-app/Views/MainAdminView.swift†L13-L38】
  - Unificar estilos de chips (capsulas con borde y color temático) para tipo, rareza, XP y nivel en todas las tarjetas.

- **Usuarios**
  - Convertir el botón de reset individual en un menú contextual o swipe action para bajar su jerarquía visual y evitar taps accidentales.【F:adm-app/Views/Users/UsersListView.swift†L36-L75】
  - Mover "Borrado maestro" y "Delete All" a un menú de overflow con icono de advertencia; dejar visibles solo acciones constructivas (Add, Close ranking).【F:adm-app/Views/Users/UsersListView.swift†L92-L134】
  - Mostrar chips de estado (XP, nivel, fecha de alta) en una misma línea con color neutro y un badge destacado si el usuario tiene alertas.

- **Actividades**
  - Integrar los filtros de usuario/búsqueda en un header pegajoso con contador de resultados y total de XP, de modo que el usuario vea el impacto inmediato de los filtros.【F:adm-app/Views/Activities/ActivitiesListView.swift†L50-L108】
  - Dar mayor peso visual a los impactos de territorio (chips verdes/azules/morados alineados) y añadir icono de mapa para distinguir actividades con efecto territorial.【F:adm-app/Views/Activities/ActivitiesListView.swift†L120-L187】

- **Feed**
  - Simplificar la cabecera de la tarjeta: usar una única barra de chips (rareza, tipo, XP) con el mismo fondo y tipografía; mover el bloque de usuario a la cabecera junto al título para dar contexto inmediato.【F:adm-app/Views/Feed/FeedListView.swift†L193-L275】
  - Sustituir menús de filtro por chips seleccionables y mostrar un banner de filtros activos ("Tipo: Challenge", "Usuario: Todos").【F:adm-app/Views/Feed/FeedListView.swift†L104-L146】

- **Territorios**
  - Incorporar una miniatura de mapa o placeholder con gradiente para comunicar ubicación; usar badges para estado activo/expirado y proximidad a vencimiento.【F:adm-app/Views/Territories/TerritoriesListView.swift†L170-L235】
  - Añadir un atajo directo a actividades recientes del territorio (chip "Ver actividad" que navegue a Activities filtrado por usuario/territorio).

- **Estados y comunicación**
  - Reemplazar `ProgressView` central por overlay con blur ligero y spinner discreto; acompañar `ContentUnavailableView` con CTA de creación ("Agregar feed", "Crear actividad").【F:adm-app/Views/Users/UsersListView.swift†L79-L91】【F:adm-app/Views/Feed/FeedListView.swift†L93-L104】【F:adm-app/Views/Activities/ActivitiesListView.swift†L79-L89】
  - Introducir toasts/banners de éxito y error para acciones masivas (borrados, cierres de ranking) en lugar de solo alerts.
