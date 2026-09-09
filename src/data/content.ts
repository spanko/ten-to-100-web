/**
 * ============================================================================
 *  TenTo100 — SITE CONTENT  (single source of truth)
 * ============================================================================
 *
 *  Edit this file to change ANY copy on the site. Components only read from
 *  here — you should never need to touch a `.astro` component to revise text,
 *  reorder projects, flip a section on/off, or update tags/stages.
 *
 *  See CONTENT.md in the repo root for a plain-language guide to each field.
 *
 *  Quick reference:
 *    - Toggle whole sections .................. `flags` (below)
 *    - Change projects / stages / tags ........ `portfolio.projects`
 *    - Stage labels are constrained to the
 *      `Stage` union so the colored pills stay
 *      consistent ............................. "Concept" | "Prototype"
 *                                                | "In development" | "Live"
 * ============================================================================
 */

export type Stage = 'Concept' | 'Prototype' | 'In development' | 'Live';

export interface Project {
  /** Short product name shown as the card title. */
  name: string;
  /** One-line pitch shown under the title. */
  pitch: string;
  /** A short paragraph (1–3 sentences). Keep it high-level / outward-facing. */
  blurb: string;
  /** Current maturity. Drives the stage marker on the card. */
  stage: Stage;
  /** Small tag set (3–5 works best visually). */
  tags: string[];
  /** Optional public site for the product. Omit for anything not yet public. */
  link?: { label: string; href: string };
}

export interface NavLink {
  label: string;
  href: string;
}

/* ------------------------------------------------------------------ *
 *  SECTION TOGGLES
 *  Flip these booleans to show/hide whole sections. No code changes
 *  needed elsewhere — the page reads these flags directly.
 * ------------------------------------------------------------------ */
export const flags = {
  /** Enterprise AI Architecture practice section. */
  showEnterprise: false,
  /** "Labs" experiments strip. Ships OFF until you populate real entries. */
  showLabs: false,
} as const;

/* ------------------------------------------------------------------ *
 *  BRAND / GLOBAL
 * ------------------------------------------------------------------ */
export const site = {
  name: 'TenTo100',
  /** Used in <title>, OG tags, and the browser tab. */
  title: 'TenTo100 — AI-native venture studio',
  /** Meta description + OG description (~150–160 chars is ideal for SEO). */
  description:
    'TenTo100 is a founder-led venture studio building AI-native products — taking ideas from 10 to 100. Built on Microsoft Azure.',
  url: 'https://www.tento100.com',
  /** Primary contact inbox used by every "Get in touch" action. */
  email: 'founders@tento100.com',
  /** Social / OG locale + handle (leave handle empty if none yet). */
  twitterHandle: '',
};

/* ------------------------------------------------------------------ *
 *  HEADER / NAV
 *  hrefs are in-page anchors. Remove a link to hide it from the nav.
 * ------------------------------------------------------------------ */
export const nav: NavLink[] = [
  { label: 'What we do', href: '#what-we-do' },
  { label: 'Portfolio', href: '#portfolio' },
  { label: 'Built on Azure', href: '#azure' },
  { label: 'Team', href: '#team' },
  { label: 'Contact', href: '#contact' },
];

/* ------------------------------------------------------------------ *
 *  HERO
 * ------------------------------------------------------------------ */
export const hero = {
  eyebrow: 'Founder-led venture studio',
  /** The headline. The word pair in `emphasis` is rendered in the accent color. */
  headlinePre: 'We take AI-native ideas from',
  emphasis: '10 to 100',
  headlinePost: '.',
  subhead:
    'TenTo100 is a venture studio that builds AI-native products grounded in real domains — from first principle to shipped software. Technical from day one, opinionated about what to build, and unromantic about what works.',
  primaryCta: { label: 'Get in touch', href: '#contact' },
  secondaryCta: { label: 'See what we’re building', href: '#portfolio' },
};

/* ------------------------------------------------------------------ *
 *  WHAT WE DO
 * ------------------------------------------------------------------ */
export const whatWeDo = {
  eyebrow: 'The studio model',
  heading: 'A studio, not a single bet.',
  body: [
    'We start companies the way good engineers ship software: pick a real problem in a real domain, build the smallest thing that proves it, and compound from there. Every product we back is AI-native at the core — not a chatbot bolted onto a legacy workflow.',
    'The through-line across the portfolio is the same: durable products where machine intelligence does something genuinely hard, grounded in a domain we understand. We build the IP, run it on Azure, and take ideas from a working 10 to a credible 100.',
  ],
  /** Three short "how we work" pillars. */
  pillars: [
    {
      title: 'AI-native, not AI-flavored',
      body: 'Intelligence sits at the center of the product, not in a marketing banner. If a model doesn’t make the experience meaningfully better, we don’t ship it.',
    },
    {
      title: 'Grounded in real domains',
      body: 'Golf instruction, animal behavior, the home environment, early learning — we build where domain truth matters and generic tools fall short.',
    },
    {
      title: 'Built to ship',
      body: 'Production software on Azure from the first prototype. We optimize for things people can use, not demos that photograph well.',
    },
  ],
};

/* ------------------------------------------------------------------ *
 *  PORTFOLIO  ("What we're building")
 *  Reorder, add, or remove entries freely. Stage must be one of the
 *  `Stage` values so the colored pills render correctly.
 * ------------------------------------------------------------------ */
export const portfolio = {
  eyebrow: 'What we’re building',
  heading: 'The portfolio',
  intro:
    'Four products in active development, each AI-native and grounded in a domain we know. High-level by design — deeper detail under NDA.',
  projects: [
    {
      name: 'Birdie Pro',
      pitch: 'An AI lesson concierge for golf teaching professionals.',
      blurb:
        'Birdie Pro gives teaching pros a smart assistant for running their lesson business and deepening every student relationship. The roadmap extends into a swing-capture flywheel that pairs computer vision with voice to close the gap between what a golfer feels and what actually happens.',
      stage: 'In development' as Stage,
      tags: ['SaaS', 'Computer vision', 'Voice', 'Sports tech'],
    },
    {
      name: 'OneCollar',
      pitch: 'An AI-powered animal behavior wearable.',
      blurb:
        'OneCollar combines hardware with on-device machine learning to read and respond to animal behavior in real time. We’re iterating through a hardware revision while sharpening the on-device models that make it work without the cloud in the loop.',
      stage: 'In development' as Stage,
      tags: ['Hardware', 'On-device ML', 'Wearable', 'IoT'],
      link: { label: 'onecollar.ai', href: 'https://onecollar.ai' },
    },
    {
      name: 'Clear the Room',
      pitch: 'Smart, refillable whole-home scent.',
      blurb:
        'The Clearing is a five-bay diffuser that knows what is loaded and how much is left. Cartridges identify themselves, the companion app names each bay and fires a burst on demand, and the refill model replaces the throwaway cartridge economics the category runs on today.',
      stage: 'In development' as Stage,
      tags: ['Hardware', 'Consumer', 'Sensing', 'Companion app'],
      link: { label: 'cleartheroom.ai', href: 'https://cleartheroom.ai' },
    },
    {
      name: 'Runcible',
      pitch: 'A storytelling companion that helps children learn — safely.',
      blurb:
        'Runcible teaches through story, in a persistent world that picks up where last night left off. Every sentence clears an independent safety judge before a child ever hears it, and the morning digest shows a parent exactly what was said and what was held back. An homage to Neal Stephenson’s The Diamond Age, which has stuck with the founder since first imagining a world with books that could think.',
      stage: 'Prototype' as Stage,
      tags: ['EdTech', 'Storytelling', 'Child safety', 'Adaptive learning'],
    },
  ] satisfies Project[],
};

/* ------------------------------------------------------------------ *
 *  ENTERPRISE PRACTICE  (toggle via flags.showEnterprise)
 *  No client names. High-level capability statement only.
 * ------------------------------------------------------------------ */
export const enterprise = {
  eyebrow: 'Enterprise practice',
  heading: 'We ship production AI for others, too.',
  body: 'Alongside our own products, we design and deliver production multi-agent systems for organizations building on Azure. It keeps our hands on real workloads, real scale, and real revenue — and it’s where a lot of our platform IP gets hardened.',
  capabilities: [
    'Multi-agent system design on Azure AI Foundry',
    'Scalable services on Azure Container Apps',
    'Operational data on Azure Cosmos DB',
    'Production .NET engineering end to end',
  ],
};

/* ------------------------------------------------------------------ *
 *  LABS  (toggle via flags.showLabs)
 *  PLACEHOLDERS ONLY — replace with real experiments before enabling.
 * ------------------------------------------------------------------ */
export const labs = {
  eyebrow: 'Labs',
  heading: 'Smaller experiments & side quests',
  intro:
    'A lighter strip for prototypes and weekend bets. Populate these before turning the section on.',
  entries: [
    {
      name: 'Placeholder experiment one',
      blurb:
        'Replace this with a real Labs entry. Keep it short — Labs is for things that are still finding their shape.',
      tags: ['Placeholder'],
    },
    {
      name: 'Placeholder experiment two',
      blurb:
        'Replace this with a real Labs entry. These cards are intentionally light-weight and easy to add or remove.',
      tags: ['Placeholder'],
    },
  ],
};

/* ------------------------------------------------------------------ *
 *  BUILT ON AZURE
 * ------------------------------------------------------------------ */
export const azure = {
  eyebrow: 'The stack',
  heading: 'Built on Microsoft Azure',
  body: 'Our products run on Microsoft Azure end to end. We build IP on managed services so the team can spend its time on the hard, domain-specific problems instead of undifferentiated infrastructure.',
  items: [
    {
      name: 'Azure AI Foundry',
      blurb: 'Where we design, evaluate, and operate the AI systems behind our products.',
    },
    {
      name: 'Azure Container Apps',
      blurb: 'Serverless containers for services that scale with demand and stay simple to run.',
    },
    {
      name: 'Azure Cosmos DB',
      blurb: 'Globally distributed, low-latency data for products that need to be fast everywhere.',
    },
    {
      name: '.NET',
      blurb: 'A fast, modern, type-safe foundation for the software we ship to production.',
    },
  ],
};

/* ------------------------------------------------------------------ *
 *  TEAM / FOUNDER
 * ------------------------------------------------------------------ */
export const team = {
  eyebrow: 'Who’s building this',
  heading: 'Founder-led, builder-first.',
  /**
   * The founder statement, deliberately unattributed. No founder name, photo,
   * or initials is published anywhere on this site — the work is the byline.
   * Do not reintroduce one without asking.
   */
  statement:
    'Founded by a lifelong technologist focused on solving big and small problems to make our lives a little bit easier.',
  collaboratorsNote:
    'TenTo100 works with a small bench of trusted engineers, designers, and domain experts who plug in per product. Interested in collaborating? We’d love to hear from you.',
};

/* ------------------------------------------------------------------ *
 *  CONTACT
 * ------------------------------------------------------------------ */
export const contact = {
  eyebrow: 'Get in touch',
  heading: 'Let’s talk.',
  body: 'Investors, partners, collaborators, or just curious — the fastest way to reach us is email. We read everything.',
  emailLabel: 'founders@tento100.com',
  emailSubject: 'Hello from tento100.com',
  /**
   * Optional contact form. The form is hidden unless `formEnabled` is true.
   * Set `formEndpoint` to your Formspree/SWA-Functions URL before enabling.
   * See README → "Contact form options".
   */
  formEnabled: false,
  formEndpoint: 'https://formspree.io/f/your-form-id',
};

/* ------------------------------------------------------------------ *
 *  FOOTER
 * ------------------------------------------------------------------ */
export const footer = {
  tagline: 'AI-native venture studio. From 10 to 100.',
  /** Inception year used for the copyright range. */
  startYear: 2025,
  links: [
    { label: 'Contact', href: '#contact' },
    { label: 'Portfolio', href: '#portfolio' },
  ] as NavLink[],
};
