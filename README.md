# TenTo100 — marketing site

The public marketing/portfolio site for **TenTo100**, a founder-led venture
studio building AI-native products. Static site built with **Astro** +
**Tailwind CSS v4**, deployed to **Azure Static Web Apps** at
**www.tento100.com**.

- ⚡ Static output (no server) — fast and cheap to host
- ♿ Accessible (WCAG AA target): semantic HTML, skip link, visible focus,
  reduced-motion support, AA color contrast
- 🔎 SEO ready: per-page meta, Open Graph + Twitter cards, JSON-LD
  Organization schema, `sitemap-index.xml`, `robots.txt`
- ✍️ All copy in one editable file — see **[CONTENT.md](CONTENT.md)**

---

## Quick start

Requires **Node 18.20+ / 20+ / 22+** (Node 24 works) and npm.

```bash
npm install      # install dependencies
npm run dev      # start dev server at http://localhost:4321
npm run build    # production build → ./dist
npm run preview  # serve the production build locally
```

---

## Project structure

```
.
├─ public/                     # static assets served as-is
│  ├─ favicon.svg              # tab icon (10→100 mark)
│  ├─ og-image.svg             # social share image (1200×630)
│  └─ robots.txt
├─ src/
│  ├─ data/content.ts          # ← ALL editable copy + section toggles
│  ├─ layouts/Layout.astro     # <head>, SEO/OG meta, JSON-LD, skip link
│  ├─ components/              # one component per section
│  └─ pages/
│     ├─ index.astro           # the single landing page
│     └─ 404.astro             # custom not-found page
├─ infra/                      # provisioning + DNS automation (PowerShell + Bicep)
│  ├─ main.bicep               # the Static Web App resource
│  ├─ Deploy-Azure.ps1         # provision SWA + set GitHub deploy-token secret
│  ├─ Configure-CloudflareDns.ps1  # www CNAME + apex→www redirect
│  └─ Add-CustomDomain.ps1     # register www.tento100.com on the SWA
├─ staticwebapp.config.json    # Azure SWA routing + security headers
├─ .github/workflows/azure-static-web-apps.yml
├─ astro.config.mjs            # site URL + sitemap + Tailwind
├─ CONTENT.md                  # how to edit copy without touching components
└─ README.md
```

## Editing content

Open **[CONTENT.md](CONTENT.md)**. Short version: edit
[`src/data/content.ts`](src/data/content.ts) — it holds every string, the
portfolio cards, the founder bio, the contact email, and the section toggles
(`flags.showEnterprise`, `flags.showLabs`). You should not need to touch any
`.astro` component to change wording.

---

## Deploying to Azure Static Web Apps

This repo is wired for SWA via GitHub Actions
([`.github/workflows/azure-static-web-apps.yml`](.github/workflows/azure-static-web-apps.yml)).
The build config the workflow uses:

| Setting | Value |
| --- | --- |
| App location | `/` |
| API location | _(empty — no API)_ |
| Output location | `dist` |

> **Scripted setup (recommended).** Everything below — provisioning the SWA,
> wiring the GitHub deploy-token secret, and configuring the
> `www.tento100.com` DNS + apex→www redirect in Cloudflare — is automated by the
> PowerShell scripts in **[`infra/`](infra/)**. See
> [`infra/README.md`](infra/README.md) for the run order and the Cloudflare
> token scopes. The manual portal steps below are kept as a fallback / reference.

### One-time setup (manual portal alternative)

1. **Create the Static Web App** in the [Azure Portal](https://portal.azure.com):
   _Create a resource → Static Web App_.
   - Plan: **Free** is fine for a marketing site (custom domains + SSL included).
   - Region: pick the closest.
   - Deployment source: **GitHub** (authorize and select this repo + the `main`
     branch), **or** choose **Other** if you'd rather wire the token manually.
   - Build presets: **Custom** → App location `/`, Api location _(blank)_,
     Output location `dist`.

2. **Deployment token → GitHub secret.**
   - If you connected GitHub in step 1, Azure commits a workflow automatically.
     This repo already includes one, so either let Azure's replace it or keep
     this one and add the secret manually (below).
   - In the Azure Portal: **Static Web App → Overview → Manage deployment token**,
     copy the token.
   - In GitHub: **Repo → Settings → Secrets and variables → Actions → New
     repository secret**:
     - Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
     - Value: _(paste the deployment token)_

   The workflow references it as
   `${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}` — **no token is stored in
   the repo.**

3. **Push to `main`** (or open a PR). On push, the site builds and deploys; on
   PRs, SWA spins up a temporary preview environment and comments the URL, then
   tears it down when the PR closes.

### Manual deploy (optional)

You can deploy without GitHub using the SWA CLI:

```bash
npm run build
npx @azure/static-web-apps-cli deploy ./dist \
  --deployment-token <YOUR_DEPLOYMENT_TOKEN>
```

---

## Custom domain — www.tento100.com

SWA gives you a default URL like `https://<name>.azurestaticapps.net`. To serve
the site at **www.tento100.com** (and redirect the apex `tento100.com` to it):

### 1. Add the `www` subdomain (CNAME)

1. Azure Portal → your Static Web App → **Custom domains → + Add**.
2. Choose **Custom domain on other DNS**, enter `www.tento100.com`,
   domain type **CNAME**.
3. Azure shows a target host like `<name>.azurestaticapps.net`. At your DNS
   provider, create:

   | Type  | Host / Name | Value                          | TTL  |
   | ----- | ----------- | ------------------------------ | ---- |
   | CNAME | `www`       | `<name>.azurestaticapps.net`   | 3600 |

4. Back in Azure, click **Validate**. Once DNS propagates, Azure provisions a
   free managed TLS certificate automatically. `www` is the canonical host the
   whole site already points at (see `site:` in `astro.config.mjs`).

### 2. Point the apex `tento100.com` at `www`

The apex (`tento100.com`, no `www`) can't be a CNAME at most registrars. Two
options:

- **Recommended — apex redirect to `www`.** If your DNS provider supports it,
  add an **ALIAS/ANAME** or **URL redirect** record sending `tento100.com` →
  `https://www.tento100.com`. Then in Azure add `tento100.com` as a second
  custom domain (type **TXT** validation) so the cert covers it.
- **Azure-native apex.** Azure supports apex via a **TXT** validation record
  plus an **A/ALIAS** record pointing at the SWA. Add `tento100.com` as a custom
  domain (domain type **TXT**) and follow the exact records Azure shows for your
  resource.

> Exact record values are shown per-resource in the Azure portal during the
> "Add custom domain" flow — always copy them from there rather than guessing.

### 3. Validate

- DNS propagation can take minutes to a few hours. Check with
  `nslookup www.tento100.com` (or `dig www.tento100.com`).
- In Azure, the custom domain shows **Ready** once validated and the cert is
  issued. Visit `https://www.tento100.com` and confirm the padlock.

---

## Security headers & routing

[`staticwebapp.config.json`](staticwebapp.config.json) sets:

- A custom **404** page (`/404.html`) via `responseOverrides` + navigation
  fallback.
- Sensible **security headers**: `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Strict-Transport-Security` (HSTS), and a restrictive
  `Permissions-Policy`.

---

## Contact form options

The Contact section ships as an **email button + mailto** (zero backend). To add
a real submit form, set `contact.formEnabled = true` in
[`src/data/content.ts`](src/data/content.ts) and provide an endpoint:

- **Formspree** (fastest): create a form, paste its `https://formspree.io/f/...`
  URL into `contact.formEndpoint`. No backend code.
- **Azure Functions on SWA** (keeps it all in Azure): add an `api/` folder with
  an HTTP-triggered Function, set `api_location: "api"` in the workflow, and
  point `formEndpoint` at `/api/contact`. This upgrades the SWA to use the
  managed Functions backend.

---

## Notes / nice-to-haves

- **OG image format.** `public/og-image.svg` is used for social previews. Most
  scrapers render SVG, but a few prefer raster — for maximum compatibility,
  export a **1200×630 PNG** as `public/og-image.png` and update the
  `/og-image.svg` references in `src/layouts/Layout.astro`.
- **Favicon fallback.** A modern SVG favicon is used. To support very old
  browsers, drop a `favicon.ico` and `apple-touch-icon.png` into `public/` and
  re-add their `<link>` tags in `Layout.astro`.
- **Analytics.** None included. Azure SWA can enable Application Insights, or
  add a privacy-friendly script (e.g. Plausible) in `Layout.astro`.

---

## Tech

[Astro](https://astro.build) · [Tailwind CSS v4](https://tailwindcss.com) ·
[@astrojs/sitemap](https://docs.astro.build/en/guides/integrations-guide/sitemap/) ·
[Azure Static Web Apps](https://learn.microsoft.com/azure/static-web-apps/)
