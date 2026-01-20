# Staging Environment Konfiguration für Railway

Diese Datei dokumentiert, welche Environment-Variablen für das Staging-Environment angepasst werden müssen.

## Staging URL
**Staging URL:** `https://twenty-staging-8d82.up.railway.app`

## Zu ändernde Environment-Variablen

### 1. SERVER_URL (ERFORDERLICH)
**Aktueller Wert:** (Production URL)
**Neuer Wert für Staging:**
```
SERVER_URL=https://twenty-staging-8d82.up.railway.app
```

**Warum wichtig:**
- Wird für Frontend-Konfiguration verwendet (`REACT_APP_SERVER_BASE_URL`)
- Wird für OAuth/SSO Callback-URLs verwendet
- Wird für Workspace-Einladungs-URLs verwendet
- Wird für Serverless-Funktionen verwendet
- Wird für Datei-URLs verwendet

### 2. PUBLIC_DOMAIN_URL (Optional)
**Neuer Wert für Staging (falls gesetzt):**
```
PUBLIC_DOMAIN_URL=https://twenty-staging-8d82.up.railway.app
```

### 3. OAuth Callback URLs (Falls OAuth aktiviert)

#### Google OAuth (falls verwendet):
```
AUTH_GOOGLE_CALLBACK_URL=https://twenty-staging-8d82.up.railway.app/auth/google/redirect
AUTH_GOOGLE_APIS_CALLBACK_URL=https://twenty-staging-8d82.up.railway.app/auth/google-apis/get-access-token
```

**Wichtig:** Diese URLs müssen auch in den Google Cloud Console OAuth-Credentials als autorisierte Redirect-URIs hinzugefügt werden!

#### Microsoft OAuth (falls verwendet):
Ähnliche Callback-URLs müssen für Microsoft konfiguriert werden, falls Microsoft OAuth aktiviert ist.

## Weitere zu prüfende Variablen

### Database-URL
- **Prüfen:** Sollte auf eine separate Staging-Datenbank zeigen (nicht die Production-DB!)
- **Variable:** `PG_DATABASE_URL`

### Redis-URL
- **Prüfen:** Sollte auf eine separate Staging-Redis-Instanz zeigen (optional)
- **Variable:** `REDIS_QUEUE_URL`

### Secrets
- **APP_SECRET:** Sollte ein eindeutiger Wert für Staging sein (nicht Production-Key wiederverwenden!)
- Weitere Secrets sollten ebenfalls eindeutig für Staging sein

## Schritte in Railway

1. Öffne das **Staging-Environment** in Railway
2. Gehe zu **Variables** Tab
3. Passe die oben genannten Variablen an
4. **Wichtig:** Stelle sicher, dass `SERVER_URL` auf die Staging-URL zeigt
5. Falls OAuth verwendet wird, passe die Callback-URLs an
6. Stelle sicher, dass separate Datenbank/Redis für Staging verwendet werden

## Nach dem Anpassen

1. Service neu deployen, damit die neuen Environment-Variablen geladen werden
2. Überprüfen, ob die Anwendung unter `https://twenty-staging-8d82.up.railway.app` erreichbar ist
3. Teste OAuth-Login (falls aktiviert), um sicherzustellen, dass Callbacks funktionieren
