# Editing site content

**All site copy lives in one file:** [`src/data/content.ts`](src/data/content.ts).

You never need to open a component (`.astro` file) to change wording, reorder
projects, swap stages/tags, or turn whole sections on and off. This file is a
plain, typed data object — edit the strings between the quotes, save, and the
dev server reloads instantly.

> Why a `.ts` file and not a Markdown file? The portfolio is structured data
> (each project has a name, pitch, paragraph, a constrained *stage*, and a tag
> list). A typed file keeps those fields consistent and prevents typos like an
> invalid stage from silently breaking the colored pills. It is still just text
> you edit by hand — this guide maps every editable field.

---

## Turn sections on/off

At the top of `content.ts`:

```ts
export const flags = {
  showEnterprise: false, // Enterprise AI Architecture practice section
  showLabs: false,       // "Labs" experiments strip (ships OFF, placeholders only)
};
```

Set either to `true` to show that section. They are wired into the page in
[`src/pages/index.astro`](src/pages/index.astro) — no other change needed.

---

## What each block controls

| Block in `content.ts` | Controls |
| --- | --- |
| `site` | Brand name, browser/tab title, SEO meta description, canonical URL, **contact email**, optional Twitter/X handle |
| `nav` | The header navigation links (in-page anchors) |
| `hero` | Headline, the gradient `emphasis` phrase ("10 to 100"), sub-headline, both call-to-action buttons |
| `whatWeDo` | "The studio model" heading, body paragraphs, and the three pillars |
| `portfolio` | Section heading/intro and the **project cards** (see below) |
| `enterprise` | Enterprise practice copy + capability bullets *(shown only if `flags.showEnterprise`)* |
| `labs` | Labs heading/intro + placeholder cards *(shown only if `flags.showLabs`)* |
| `azure` | "Built on Microsoft Azure" heading, body, and the four stack items |
| `team` | Section heading + founder name/role/bio/initials + collaborators note |
| `contact` | Heading, body, email label/subject, and the optional contact form |
| `footer` | Tagline, copyright start year, footer links |

---

## Editing a project card

Each entry in `portfolio.projects` looks like this:

```ts
{
  name: 'Birdie Pro',
  pitch: 'An AI lesson concierge for golf teaching professionals.',
  blurb: 'A short paragraph — keep it high-level and outward-facing.',
  stage: 'In development' as Stage,
  tags: ['SaaS', 'Computer vision', 'Voice', 'Sports tech'],
},
```

- **`stage`** must be one of exactly: `'Concept'`, `'Prototype'`,
  `'In development'`, or `'Live'`. Each gets its own colored pill. Keep the
  `as Stage` suffix.
- **`tags`** — 3–5 reads best. They render as monospace chips.
- To **add** a project, copy a `{ ... }` block (including the trailing comma).
  To **remove** one, delete its block. To **reorder**, move the blocks.

---

## The founder bio is a placeholder

`team.founder.bio` currently contains placeholder text. Replace it with your
real bio. You can also change `initials` (shown in the avatar circle).

---

## Enabling the contact form (optional)

By default Contact shows an email button + mailto link only (no backend
needed). To add a posting form, in `contact`:

```ts
formEnabled: true,
formEndpoint: 'https://formspree.io/f/your-form-id',
```

See the README ("Contact form options") for endpoint choices.

---

## Where copy appears but is NOT in this file

A few SEO/asset strings live outside `content.ts` because they aren't page copy:

- **`public/robots.txt`** — crawler rules + sitemap URL.
- **`public/og-image.svg`** — the social share image (has "TenTo100" baked in).
- **`public/favicon.svg`** — the browser-tab icon.
- **Sitemap** — generated automatically from `site` in `astro.config.mjs`.

If you rename the company or change the domain, update `site` in `content.ts`,
`site:` in `astro.config.mjs`, `public/robots.txt`, and re-export the OG image.
