[← backend docs](../index.md) · api [uploads](../../../docs/technical/api/index.md) · [§6 messages](../../../docs/technical/api/06-messages.md)

# Module: `media` (chat media uploads)

**Scope:** Accepts chat media files (voice / image / video) and stores them on disk in the project `uploads/` folder, served statically. MVP storage choice (local folder) per the project lead; the contract is storage-agnostic so it can move to object storage (e.g. DigitalOcean Spaces) later without client changes.
**Layers:** `media.controller` (multer `FileInterceptor` + `diskStorage`) · `media.constants` (paths, size cap, mime→kind) · `media.module`. Static serving wired in `main.ts` via `app.useStaticAssets(UPLOADS_DIR, { prefix: '/uploads/' })`.

**Route**
| Method · Path | Notes |
|---|---|
| `POST /v1/media` | session; multipart `file` → `{ data:{ url, kind, size } }`. `kind` from mimetype (audio→voice, image→image, video→video). Max **25 MB**. Rejects other types with `400`. |

**Storage layout:** files land in `uploads/media/<uuid><ext>`; served at `GET /uploads/media/<file>` (outside the `/v1` global prefix — static assets bypass it). `uploads/` is **gitignored** (`.gitkeep` keeps the folder).
**URL:** the returned `url` is absolute — `PUBLIC_BASE_URL` if set, else `<req.protocol>://<req.host>` (LAN IP in dev, public host behind the proxy in prod; `trust proxy` is enabled). The client passes it back as `media_url` on `POST /v1/messages`.
**Security:** behind the global `AuthGuard` (session required). `helmet` is configured with `crossOriginResourcePolicy: cross-origin` so the mobile app can load media from a different origin.
**Deps:** `@nestjs/platform-express` (multer), `@types/multer` (dev).
**Sync status:** ✅ implemented — upload → static serve → send as message wired end-to-end.
**Not yet:** image resize / video transcode / thumbnails, object-storage backend, unused-file cleanup (future `media-process` worker — see `api/index.md` “File uploads”).
