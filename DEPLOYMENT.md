# IPL Fan Battle – Deployment Guide

## Architecture

```
Flutter App → FastAPI (Railway) → PostgreSQL (Supabase) + Redis (Railway)
                    ↕ WebSocket
```

---

## 1. Supabase (Database)

1. Go to [supabase.com](https://supabase.com) → Create a new project
2. Go to **SQL Editor** → Paste contents of `backend/schema.sql` → Run
3. Go to **Settings → Database** → Copy the connection string
4. **Critical for Railway**: Use the **Connection Pooler** string but in **Session** mode for asyncpg compatibility.
   - Go to **Settings -> Database -> Connection Pooling**.
   - Copy the connection string for **Session** mode.
   - It should use port **5432** but with a host like `aws-0-[REGION].pooler.supabase.com`.
   - **IMPORTANT**: If your password contains special characters like `@`, you MUST URL-encode them. (e.g., `@` becomes `%40`). So `MyP@ssword` becomes `MyP%40ssword`.
5. Format: `postgresql+asyncpg://postgres.[REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres`
6. **Why Session Mode on the Pooler?**: Direct connection (db.supabase.co) uses IPv6, which Railway does not support, causing "Network Unreachable". The pooler domain supports IPv4. However, the default pooler port (6543, Transaction mode) breaks FastAPI's `asyncpg` driver. Port 5432 on the pooler domain gives us both IPv4 and asyncpg compatibility!

---

## 2. Railway (Backend + Redis)

### Redis
1. Go to [railway.app](https://railway.app) → New Project → **Add Redis**
2. Copy the `REDIS_URL` from the Redis service variables

### Backend
1. In the same project → **Add Service → Deploy from GitHub Repo**
2. Point to your repo's `backend/` directory (set Root Directory = `/backend`)
3. Set environment variables:
   ```
   DATABASE_URL=postgresql+asyncpg://postgres:PASSWORD@db.REF.supabase.co:5432/postgres
   REDIS_URL=redis://default:PASSWORD@HOST.railway.app:PORT
   ADMIN_KEY=your-secret-admin-key
   PORT=8000
   ```
4. Railway will auto-detect the `Procfile` and deploy

### Seed the database
After deployment, use Railway CLI or run locally:
```bash
cd backend
pip install -r requirements.txt
# Set DATABASE_URL in .env
python seed.py
```

---

## 3. Flutter App

### Update API URL
In `frontend/lib/core/api_service.dart`, update:
```dart
static const String baseUrl = 'https://your-backend.railway.app';
```

### Build for Android
```bash
cd frontend
flutter build apk --release
```
APK will be at `build/app/outputs/flutter-apk/app-release.apk`

### Build for iOS
```bash
cd frontend
flutter build ios --release
```

### Build for Web
```bash
cd frontend
flutter build web
```

---

## 4. Admin Panel

Access at: `https://your-backend.railway.app/admin`

Enter your `ADMIN_KEY` to connect.

---

## Environment Variables Summary

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Supabase PostgreSQL connection string |
| `REDIS_URL` | Railway Redis connection string |
| `ADMIN_KEY` | Secret key for admin panel access |
| `PORT` | Port for the server (Railway sets this automatically) |
