<!-- translated-from: README.md sha256:464e1d4e418e -->
<p align="right"><a href="README.md"><img src="docs/assets/lang-en.svg" alt="English" width="46" height="28"></a><a href="README.ru.md"><img src="docs/assets/lang-ru.svg" alt="Русский" width="46" height="28"></a><a href="README.es.md"><img src="docs/assets/lang-es-on.svg" alt="Español" width="46" height="28"></a></p>

# Release Conveyor Kit

Comandos slash y comprobaciones que hacen que un agente de IA muestre su
trabajo en lugar de limitarse a decir "listo".

[![CI](https://github.com/sagittMZ/release-conveyor-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sagittMZ/release-conveyor-kit/actions/workflows/ci.yml)

<p>
  <a href="#añádelo-a-tu-proyecto"><img src="docs/assets/btn-add.svg" alt="Añádelo a tu proyecto" width="196"></a>
  <a href="#empieza-un-proyecto-nuevo"><img src="docs/assets/btn-new.svg" alt="Empieza un proyecto nuevo" width="196"></a>
  <a href="#publica-tu-mvp"><img src="docs/assets/btn-ship.svg" alt="Publica tu MVP" width="196"></a>
  <a href="#los-comandos-que-usarás-primero"><img src="docs/assets/btn-commands.svg" alt="Ver los comandos" width="196"></a>
</p>

Programas con un agente de IA, y el agente:

- dice "probado" y "verificado" sin nada que lo demuestre
- lo olvida todo en cuanto termina la sesión
- hace el mismo trabajo de forma distinta cada vez que se lo pides
- te da la razón en lugar de llevarte la contraria

El kit es un conjunto de carpetas que tu agente copia en tu repositorio. No es
un paquete ni una CLI, y no hay nada que instalar.

Esta es una traducción de [README.md](README.md). El resto de la
documentación, los comandos y los prompts están en inglés.

![/precommit encuentra tres defectos plantados en un repositorio generado](docs/demo/precommit.gif)

Una ejecución real de `/precommit` en un repositorio generado con tres
defectos plantados. Cómo se grabó y cómo repetirla:
[docs/demo/](docs/demo/README.md).

## Añádelo a tu proyecto

Para un repositorio que ya tienes, en cualquier lenguaje. Necesitas git y
[Claude Code](https://claude.com/claude-code).

1. Clona el kit junto a tu proyecto:

   ```bash
   git clone https://github.com/sagittMZ/release-conveyor-kit.git
   ```

2. Abre una sesión del agente en **tu** proyecto y pega el prompt de
   instalación de
   [modules/09-prompt-library/ROLLOUT.md](modules/09-prompt-library/ROLLOUT.md),
   con la ruta a tu clon.
3. El agente copia los comandos, te muestra el diff y espera tu visto bueno
   antes de hacer commit. No toca el código de tu aplicación.
4. Escribe `/precommit` antes de tu próximo commit.

Los comandos son prompts en Markdown, así que cualquier agente puede leerlos.
El kit en sí se creó y se ejecutó con Claude Code.

## Empieza un proyecto nuevo

El kit no genera una aplicación. Lo que le da a un proyecto nuevo es el arnés
desde el primer commit, que es el momento más barato para adoptarlo.

1. Crea el repositorio y haz un primer commit:

   ```bash
   mkdir my-project && cd my-project
   git init && git commit --allow-empty -m "Initial commit"
   ```

2. Sigue [Añádelo a tu proyecto](#añádelo-a-tu-proyecto) desde el paso 1.
3. Empieza la primera funcionalidad con `/spec`, planifícala con `/impl-plan`
   y cierra la sesión con `/session-wrap`.

Este camino se ha recorrido una vez en un repositorio vacío: 82 archivos
preparados para el commit, las evaluaciones de estructura en 62 de 62 y cada
archivo copiado con el sello de su origen.

## Publica tu MVP

Para una aplicación en React + Vite + Capacitor + Supabase + Vercel que ya
funciona y ahora tiene que llegar a los usuarios. El pipeline de publicación
añade CI, builds de Android e iOS, guías para las tiendas, staging,
monitoreo, higiene de secretos y una suite de pruebas de humo.

1. Primero añade el arnés, como se explica arriba.
2. Abre una sesión del agente en tu proyecto y dale el prompt de
   [modules/08-agent-layer/](modules/08-agent-layer/). Te hace una entrevista,
   detecta tu stack, aplica los módulos en orden y verifica cada uno.
3. Haz los pasos manuales de su informe final: cuentas, pagos, secretos y los
   botones de las consolas de las tiendas. Los módulos dan una instrucción
   numerada para cada uno, y el repositorio nunca guarda un secreto real:
   [modules/06-secrets/](modules/06-secrets/README.md).

En cualquier otro stack esta parte no aplica; las dos primeras sí.

## Los comandos que usarás primero

| Comando | Qué hace |
|---|---|
| `/spec` | Te entrevista sobre una funcionalidad y luego escribe la especificación |
| `/impl-plan` | Un plan por fases hecho por un equipo de roles, antes de escribir código |
| `/edge-cases` | Estados de error, estados vacíos y casos límite de una funcionalidad |
| `/precommit` | Revisa los cambios sin commit: bugs, secretos filtrados, ediciones olvidadas |
| `/security-scan` | Revisión de seguridad de una ruta, hecha por un agente aparte |
| `/release-notes` | Notas de versión entre dos tags o commits, agrupadas por tipo |
| `/session-wrap` | Cierra la sesión con un resumen breve desde el que empieza la siguiente |
| `/handoff` | Escribe el prompt de arranque para la siguiente sesión |

Hay seis más (`/audit`, `/backlog`, `/scope-triage`, `/eval-command`,
`/consolidate-memory`, `/arch-viz`) y un menú de 21 prompts listos por fase
del proyecto en [modules/09-prompt-library/](modules/09-prompt-library/).
Ejemplos comentados: [docs/prompt-kit-guide.md](docs/prompt-kit-guide.md).

## Qué más hay en la caja

| Parte | Qué obtienes | Estado |
|---|---|---|
| Comandos y prompts (módulo 09) | Los comandos slash de arriba y el menú de prompts | Funciona en el propio kit |
| Evaluación de comandos (módulo 11) | Una puntuación para cada comando, para detectar un prompt que ha empeorado antes de que haga daño | Funciona en el propio kit |
| Memoria (módulo 12) | El historial de sesiones destilado en notas que tú revisas | Funciona en el propio kit |
| Página de arquitectura (módulo 13) | Un archivo HTML con la arquitectura de tu proyecto, que CI mantiene al día. [Ejemplo](docs/arch/index.html) | Funciona en el propio kit |
| Pipeline de publicación (módulos 01-08) | CI, builds de Android e iOS, guías para las tiendas, staging, monitoreo, higiene de secretos, pruebas de humo. Un solo stack | En parte extraído de un pipeline en producción, en parte no verificado |
| Recuperación de sesiones (módulo 14) | Las sesiones de los agentes y sus temas de chat vuelven después de un reinicio | Probado en parte: un arranque en frío real recuperó todas las sesiones; la última corrección aún no se ha ejecutado en frío |

## Qué no está verificado

El kit nunca presenta como probada una plantilla que no se ha ejecutado. El
README de cada módulo separa su contenido en *extraído de un proyecto en
funcionamiento* y *añadido por el kit, no verificado*. La lista completa de
esta versión: [docs/NOT-VERIFIED.md](docs/NOT-VERIFIED.md).

## Para profundizar

- Por qué existe el kit y qué se rompió por el camino:
  [docs/WHY.md](docs/WHY.md)
- La misma idea en cuatro niveles, de un niño de diez años a un ingeniero:
  [docs/EXPLAIN.md](docs/EXPLAIN.md)
- Decisiones de diseño, numeradas, con alternativas y costes:
  [ARCHITECTURE.md](ARCHITECTURE.md)
- Todos los módulos: [modules/](modules/)
- Reglas para trabajar en este repositorio: [AGENTS.md](AGENTS.md)

## Licencia

MIT - ver [LICENSE](LICENSE).
