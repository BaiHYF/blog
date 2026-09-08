// Generate a lightweight post index (id, title, date) so list pages and slugs
// don't need the expensive Typst compile that astro-typst does in `getCollection`.
// Reads .md frontmatter and .typ `#show` params directly off disk.
import { readdirSync, readFileSync, writeFileSync, statSync } from "node:fs";
import { join, basename } from "node:path";

const dir = "content/article";
const out = "content/snapshot/posts.json";

function frontmatter(text) {
  const m = text.match(/^---\s*\n([\s\S]*?)\n---/);
  return m ? m[1] : "";
}

function yamlKey(fm, key) {
  for (const line of fm.split(/\r?\n/)) {
    const m = line.match(new RegExp("^" + key + "\\s*:\\s*(.+)$"));
    if (m) return m[1].trim().replace(/^['"]|['"]$/g, "");
  }
  return "";
}

function readDate(text) {
  const m = text.match(/date\s*:\s*["']?(\d{4}-\d{2}-\d{2})["']?/);
  return m ? m[1] : "";
}

const posts = [];
for (const f of readdirSync(dir)) {
  const full = join(dir, f);
  if (!statSync(full).isFile()) continue;
  const ext = full.slice(full.lastIndexOf("."));
  const id = basename(f, ext);
  const text = readFileSync(full, "utf8");
  let title = "";
  let date = "";
  if (ext === ".md") {
    const fm = frontmatter(text);
    title = yamlKey(fm, "title");
    date = readDate(fm);
  } else if (ext === ".typ") {
    title = (text.match(/title\s*:\s*"([^"]+)"/) || [])[1] || "";
    date = readDate(text);
  } else {
    continue;
  }
  posts.push({ id, title: title || id, date });
}

posts.sort((a, b) => (b.date || "").localeCompare(a.date || ""));

writeFileSync(out, JSON.stringify(posts, null, 2) + "\n");
console.log(`wrote ${out} (${posts.length} posts)`);
