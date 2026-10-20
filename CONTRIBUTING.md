# Contributing / Flujo de cambios

Este repositorio contiene el metadata de la org `ebanoconsulting` (Developer Edition) y es la fuente de verdad para los despliegues.

## Regla principal

**Ningun cambio se despliega al dev sandbox sin un Pull Request aprobado y mergeado a `main`.**

- No hacer push directo a `main`.
- No ejecutar `sf project deploy start` contra el dev sandbox desde una rama local sin PR aprobado.
- La unica excepcion es `--dry-run` (validacion), que no aplica cambios y se puede usar para verificar antes de pedir aprobacion.

## Ramas

| Rama | Uso |
|---|---|
| `main` | Estado validado. Solo recibe merges via PR. Es la rama que se despliega al dev sandbox. |
| `feature/<JIRA-KEY>-<descripcion>` | Nuevos flows, campos, objetos, etc. |
| `fix/<JIRA-KEY>-<descripcion>` | Correcciones. |
| `chore/<descripcion>` | Mantenimiento (scripts, docs, configuracion). |

## Flujo paso a paso

1. Sincroniza `main`:

   ```powershell
   git checkout main
   git pull origin main
   ```

2. Crea la rama de trabajo:

   ```powershell
   git checkout -b feature/SCRUM-5-followup-flow
   ```

3. Haz los cambios en `force-app/main/default/...`. Si el cambio nace en la org, descarga primero el metadata:

   ```powershell
   sf project retrieve start --metadata Flow:Mi_Flow --target-org ebanoconsulting
   ```

4. Valida el deploy sin aplicar cambios (permitido antes del PR):

   ```powershell
   sf project deploy start --source-dir force-app --target-org ebanoconsulting --dry-run
   ```

5. Commit y push de la rama:

   ```powershell
   git add .
   git commit -m "SCRUM-5: add follow-up flow for Proposal opportunities"
   git push -u origin feature/SCRUM-5-followup-flow
   ```

6. Abre el PR en GitHub contra `main` y completa el template: link al ticket de Jira, metadata afectada y evidencia del dry-run.

7. Revision: minimo 1 aprobacion y checks en verde.

8. Merge a `main` (squash o merge commit; no force-push).

9. Al mergear el PR, GitHub Actions despliega automaticamente al dev sandbox (ver "Deploy automatico" abajo). Si necesitas desplegar manualmente, hazlo **desde `main`**, nunca desde una rama sin mergear:

   ```powershell
   git checkout main
   git pull origin main
   sf project deploy start --source-dir force-app --target-org ebanoconsulting
   ```

10. Verifica en la org y comenta/actualiza el ticket de Jira.

## Checklist del PR

- [ ] Link al ticket de Jira
- [ ] `sf project deploy start ... --dry-run` sin errores
- [ ] Solo metadata intencional (revisar `git status` y el diff)
- [ ] Sin secretos (`Jira.txt`, `.env`, auth URLs, tokens)
- [ ] Evidencia de pruebas (capturas, logs o pasos reproducibles)
- [ ] Destructive changes documentadas y aprobadas (si aplica)

## Deploy automatico (GitHub Actions)

Workflow: `.github/workflows/deploy.yml`.

1. Configura el secreto `SFDX_AUTH_URL` (una sola vez):

   ```powershell
   sf org display --target-org ebanoconsulting --verbose --json
   ```

   Copia el valor de `sfdxAuthUrl` (empieza con `force://`) y agregalo en GitHub: Settings -> Secrets and variables -> Actions -> New repository secret, con el nombre `SFDX_AUTH_URL`.

2. En cada PR, el job `validate` ejecuta un `--dry-run` solo con los componentes modificados.

3. Al mergear a `main` (push), el job `deploy` genera un manifest con los archivos cambiados y los despliega al dev sandbox.

4. Ejecucion manual: Actions -> Salesforce Deploy -> Run workflow. Marca `full` para desplegar todo `force-app`.

5. Limitaciones:

   - Las eliminaciones de metadata no se automatizan (el diff excluye archivos borrados). Usa `destructiveChanges.xml` en un PR y despliega manualmente.
   - Los PRs desde forks no reciben secretos; usa ramas dentro del repo.
   - Para produccion cambia `--test-level NoTestRun` por `RunLocalTests`.

## Proteccion de `main` (configurar en GitHub)

Settings -> Branches -> Add branch protection rule:

- Require a pull request before merging
- Require approvals: 1
- Dismiss stale approvals when new commits are pushed
- Require status checks to pass (cuando exista CI)
- Do not allow bypassing the above settings (incluir admins)
- Restrict force pushes y deletions

## Secretos y credenciales

- Nunca commitear `Jira.txt`, `.env`, `SFDX_AUTH_URL` ni tokens.
- Para CI usar GitHub Secrets, por ejemplo `SFDX_AUTH_URL` (se obtiene con `sf org display --target-org ebanoconsulting --verbose --json`, campo `sfdxAuthUrl`).
- Rotar cualquier credencial que haya estado expuesta en texto plano.

## Notas de deploy

- Validar siempre primero con `--dry-run` y desplegar despues sin el flag.
- Para eliminar metadata usar `destructiveChanges.xml`.
- Los flows activos generan una nueva version al desplegar; revisar el elemento `<status>`.
- Despues del deploy, verificar en la org y registrar la evidencia en el ticket.
