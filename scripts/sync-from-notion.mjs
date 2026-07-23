import { Client } from "@notionhq/client";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(__dirname, "..");
const ARTICLE_DIR = path.join(PROJECT_ROOT, "content", "article");
const IMAGE_DIR = path.join(PROJECT_ROOT, "public", "images");

const NOTION_TOKEN = process.env.NOTION_TOKEN;
if (!NOTION_TOKEN) {
  console.error("Error: NOTION_TOKEN environment variable is required.");
  console.error("Usage: $env:NOTION_TOKEN='ntn_xxx'; node scripts/sync-from-notion.mjs");
  process.exit(1);
}

const DATA_SOURCE_ID = "7f2510ae-4bbe-4b12-9c2f-d9c4a71a8582";

const notion = new Client({ auth: NOTION_TOKEN });

const TAG_MAP = {
  "\u788E\u788E\u5FF5": "murmur",
  "Music": "music-theory",
  "Graphic": "gamedev",
  "Andriod": "software",
  "Misc": "misc",
  "Life": "misc",
  "Network": "network",
  "Fun": "misc",
  "Rust": "misc",
};

function slugify(title, pageId) {
  const asciiTitle = title.replace(/[^\x20-\x7E\s]/g, "").trim();
  const hasAscii = asciiTitle.length > 2;
  let slug = (hasAscii ? asciiTitle : title)
    .replace(/[^\w\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .toLowerCase();
  if (!slug || slug.length < 2) {
    slug = pageId ? pageId.replace(/-/g, "").slice(0, 12) : "post";
  }
  if (slug.length > 80) slug = slug.slice(0, 80);
  return slug;
}

function cleanMarkdownLinks(text) {
  return text.replace(/\[([^\]]*)\]\(([^)]*)\)/g, (match, linkText, url) => {
    if (url.startsWith("https://www.notion.so/") || url.startsWith("https://app.notion.com/") || url.startsWith("https://astonishing-icon-0ff.notion.site/")) {
      return linkText;
    }
    if (url.startsWith("http") && linkText) {
      return `#link("${url}")[${linkText}]`;
    }
    return match;
  });
}

function cleanMentions(text) {
  return text.replace(/<mention-page[^>]*>(.*?)<\/mention-page>/g, "$1");
}

function cleanColumns(text) {
  let result = text.replace(/<\/?columns>/g, "");
  result = result.replace(/<\/?column>/g, "");
  return result;
}

function cleanEmptyBlocks(text) {
  return text.replace(/<empty-block\/>/g, "");
}

function cleanUnknownTags(text) {
  return text.replace(/<unknown[^>]*\/>/g, "");
}

function cleanSpecialMath(text) {
  return text.replace(/\$`([^`]*)`\$/g, (match, content) => {
    const cleaned = content
      .replace(/\\color\{[^}]*\}\{([^}]*)\}/g, "$1")
      .replace(/\\utilde\{([^}]*)\}/g, "$1")
      .replace(/\\bm\{([^}]*)\}/g, "$1")
      .replace(/\\textbf\{([^}]*)\}/g, "$1")
      .replace(/\\textit\{([^}]*)\}/g, "$1")
      .replace(/\\text\{([^}]*)\}/g, "$1")
      .replace(/\\large|\\small|\\Huge|\\huge|\\normalsize/g, "")
      .replace(/\\displaystyle/g, "")
      .replace(/\\substack\{[^}]*\}/g, "")
      .replace(/\\\[-?\d*\.?\d*em\]/g, "")
      .replace(/\{[^}]*\}/g, " ")
      .replace(/\\[A-Za-z]+/g, "")
      .replace(/\s+/g, " ").trim();
    return cleaned || "";
  });
}

function cleanLatexMathInBlock(match, content) {
  let cleaned = content
    .replace(/\\color\{[^}]*\}\{([^}]*)\}/g, "$1")
    .replace(/\\utilde\{([^}]*)\}/g, "$1")
    .replace(/\\bm\{([^}]*)\}/g, "$1")
    .replace(/\\textbf\{([^}]*)\}/g, "$1")
    .replace(/\\textit\{([^}]*)\}/g, "$1")
    .replace(/\\text\{([^}]*)\}/g, "$1")
    .replace(/\\mathcal\{([^}]*)\}/g, "$1")
    .replace(/\\large|\\small|\\Huge|\\huge|\\normalsize/g, "")
    .replace(/\\displaystyle/g, "")
    .replace(/\\substack\{[^}]*\}/g, "")
    .replace(/\\\[-?\d*\.?\d*em\]/g, "")
    .replace(/\{[^}]*\}/g, " ")
    .replace(/\\[A-Za-z]+/g, "")
    .replace(/\s+/g, " ").trim();
  if (!cleaned || cleaned.length === 0) return "";
  if (cleaned.match(/^[\w\s\u4e00-\u9fff]+$/)) return cleaned;
  return "$" + cleaned + "$";
}

function cleanLatexMath(text) {
  let result = text;
  result = result.replace(/\$\$([^$]+)\$\$/g, cleanLatexMathInBlock);
  result = result.replace(/\$([^$\n]+)\$/g, cleanLatexMathInBlock);
  return result;
}

function cleanHtmlTags(text) {
  let result = text;
  result = result.replace(/<br\s*\/?>/gi, "\n");
  result = result.replace(/<span[^>]*>/gi, "");
  result = result.replace(/<\/span>/gi, "");
  result = result.replace(/<div[^>]*>/gi, "");
  result = result.replace(/<\/div>/gi, "");
  result = result.replace(/<p[^>]*>/gi, "");
  result = result.replace(/<\/p>/gi, "");
  result = result.replace(/<[^>]+>/g, "");
  return result;
}

function cleanOrphanEmphasis(text) {
  let result = text;
  result = result.replace(/^_\s*$/gm, "");
  result = result.replace(/(?<!\w)_(?!\w)/g, "");
  result = result.replace(/(\*{1,2})\s*\1/g, "");
  return result;
}

function cleanNotionAttributes(text) {
  let result = text;
  result = result.replace(/\{color="[^"]*"\}/g, "");
  result = result.replace(/\{color='[^']*'\}/g, "");
  result = result.replace(/\{\s*color\s*:\s*[^}]+\}/g, "");
  result = result.replace(/<table_of_contents[^>]*\/>/g, "");
  return result;
}

function cleanCurlyBraces(text) {
  let result = text;
  result = result.replace(/\{[^}]*\}/g, " ");
  result = result.replace(/\s+/g, " ").trim();
  return result;
}

function cleanCheckboxes(text) {
  let result = text;
  result = result.replace(/- \[x\] /g, "- ");
  result = result.replace(/- \[ \] /g, "- ");
  result = result.replace(/- \[X\] /g, "- ");
  return result;
}

function removeEmptyMathBlocks(text) {
  return text.replace(/\$\s*\$/g, "");
}

function extractTitle(text) {
  const match = text.match(/^#\s+(.+)$/m);
  return match ? match[1].trim() : null;
}

function extractFirstParagraph(text) {
  const lines = text.split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith("#") && !trimmed.startsWith(">") && !trimmed.startsWith("<") && !trimmed.startsWith("![") && trimmed !== "---" && !trimmed.startsWith("___")) {
      return trimmed.length > 100 ? trimmed.slice(0, 97) + "..." : trimmed;
    }
  }
  return "";
}

async function downloadImage(url, articleSlug, index) {
  const imgDir = path.join(IMAGE_DIR, articleSlug);
  if (!fs.existsSync(imgDir)) {
    fs.mkdirSync(imgDir, { recursive: true });
  }

  const urlObj = new URL(url);
  const ext = path.extname(urlObj.pathname) || ".png";
  const filename = `img-${index}${ext}`;
  const filepath = path.join(imgDir, filename);

  if (fs.existsSync(filepath)) {
    return `/images/${articleSlug}/${filename}`;
  }

  try {
    const response = await fetch(url);
    if (!response.ok) {
      console.warn(`  Warning: Failed to download image ${url}: ${response.status}`);
      return url;
    }
    const buffer = Buffer.from(await response.arrayBuffer());
    fs.writeFileSync(filepath, buffer);
    return `/images/${articleSlug}/${filename}`;
  } catch (err) {
    console.warn(`  Warning: Failed to download image ${url}: ${err.message}`);
    return url;
  }
}

function cleanAllOutsideCodeBlocks(text, cleaners) {
  const lines = text.split("\n");
  let inCodeBlock = false;
  const result = [];
  for (const line of lines) {
    if (line.trimStart().startsWith("```")) {
      inCodeBlock = !inCodeBlock;
      result.push(line);
      continue;
    }
    if (inCodeBlock) {
      result.push(line);
      continue;
    }
    let processed = line;
    for (const cleaner of cleaners) {
      processed = cleaner(processed);
    }
    result.push(processed);
  }
  return result.join("\n");
}

function convertMarkdownToTypst(md, articleSlug) {
  let result = md;

  const preCleaners = [
    l => l.replace(/\{color="[^"]*"\}/g, ""),
    l => l.replace(/\{color='[^']*'\}/g, ""),
    l => l.replace(/\{\s*color\s*:\s*[^}]+\}/g, ""),
    l => l.replace(/<table_of_contents[^>]*\/>/g, ""),
    l => l.replace(/<[^>]+>/g, ""),
    l => l.replace(/<empty-block\/>/g, ""),
    l => l.replace(/^- \[x\] /gm, "- "),
    l => l.replace(/^- \[ \] /gm, "- "),
    l => l.replace(/^- \[X\] /gm, "- "),
    l => l.replace(/\$`([^`]*)`\$/g, (m, c) => {
      return c.replace(/\\color\{[^}]*\}\{([^}]*)\}/g, "$1")
              .replace(/\\[a-zA-Z]+\{[^}]*\}/g, "")
              .replace(/\{[^}]*\}/g, " ")
              .replace(/\\[A-Za-z]+/g, "")
              .replace(/\s+/g, " ").trim();
    }),
    l => l.replace(/\$\$([^$]+)\$\$/g, (m, c) => cleanLatexMathInBlock(m, c)),
    l => l.replace(/\$([^$\n]+)\$/g, (m, c) => cleanLatexMathInBlock(m, c)),
    l => l.replace(/\s*\$\s*\$/g, ""),
    l => l.replace(/\\color\{[^}]*\}\{([^}]*)\}/g, "$1"),
    l => l.replace(/\\utilde\{([^}]*)\}/g, "$1"),
    l => l.replace(/\\bm\{([^}]*)\}/g, "$1"),
    l => l.replace(/\{|\}/g, ""),
    l => l.replace(/^_\s*$/gm, ""),
    l => l.replace(/(?<!\w)_(?!\w)/g, ""),
  ];

  result = cleanAllOutsideCodeBlocks(result, preCleaners);

  result = cleanMarkdownLinks(result);
  result = cleanMentions(result);
  result = cleanColumns(result);

  const lines = result.split("\n");
  const typLines = [];
  let inCodeBlock = false;
  let inTable = false;
  let tableLines = [];
  let imageIndex = 0;
  let imageDownloads = [];

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];

    if (line.trimStart().startsWith("```")) {
      inCodeBlock = !inCodeBlock;
      typLines.push(line);
      continue;
    }

    if (inCodeBlock) {
      typLines.push(line);
      continue;
    }

    if (line.trim().startsWith("<")) {
      continue;
    }

    if (line.trim().match(/^\|.*\|$/)) {
      tableLines.push(line);
      inTable = true;
      continue;
    } else if (inTable) {
      inTable = false;
      typLines.push(convertTableToTypst(tableLines));
      tableLines = [];
    }

    let trimmed = line.trim();

    if (trimmed.startsWith("# ") && !trimmed.startsWith("## ")) {
      continue;
    }

    if (trimmed.startsWith("## ")) {
      typLines.push("== " + trimmed.slice(3));
      continue;
    }

    if (trimmed.startsWith("### ")) {
      typLines.push("=== " + trimmed.slice(4));
      continue;
    }

    if (trimmed.startsWith("#### ")) {
      typLines.push("==== " + trimmed.slice(5));
      continue;
    }

    if (trimmed === "---" || trimmed.startsWith("___")) {
      typLines.push("#line()");
      continue;
    }

    if (trimmed.startsWith("![")) {
      const match = trimmed.match(/!\[([^\]]*)\]\(([^)]+)\)/);
      if (match) {
        const alt = match[1] || "";
        const url = match[2];
        imageIndex++;
        const localPath = `../../public/images/${articleSlug}/img-${imageIndex}${path.extname(new URL(url).pathname) || ".png"}`;
        imageDownloads.push({ url, localPath, articleSlug, index: imageIndex });
        if (alt) {
          typLines.push(`#figure(image("${localPath}"), caption: [${alt}])`);
        } else {
          typLines.push(`#image("${localPath}")`);
        }
        continue;
      }
      typLines.push(line);
      continue;
    }

    if (trimmed.startsWith("> ")) {
      typLines.push(line.replace(/_([^_]+)_/g, "$1"));
      continue;
    }

    if (trimmed.startsWith("- ") || trimmed.startsWith("* ") || trimmed.startsWith("+ ")) {
      typLines.push(line);
      continue;
    }

    if (trimmed.match(/^\d+[.)]\s/)) {
      typLines.push("+ " + trimmed.replace(/^\d+[.)]\s+/, ""));
      continue;
    }

    if (trimmed.startsWith("|") && trimmed.endsWith("|")) {
      continue;
    }

    typLines.push(line);
  }

  if (inTable && tableLines.length > 0) {
    typLines.push(convertTableToTypst(tableLines));
  }

  let typContent = typLines.join("\n");
  typContent = convertInlineFormatting(typContent);

  typContent = escapeHashInContent(typContent);

  typContent = typContent.replace(/\[_([^\]]*)_\]\*\s*\*/g, "[$1]");
  typContent = typContent.replace(/\* \*/g, "");
  typContent = typContent.replace(/_\*/g, "_ ");
  typContent = typContent.replace(/> \*([^*]+)\*([^*]+)\*([^*]+)\*/g, "> *$1$2$3*");

  return { content: typContent, imageDownloads };
}

function escapeHashInContent(text) {
  const typstFunctions = new Set([
    "link", "image", "figure", "line", "table", "show", "import", "set",
    "let", "if", "else", "for", "while", "return", "text", "grid",
    "quote", "align", "block", "highlight", "box", "rect", "circle",
    "arc", "ellipse", "path", "polygon", "stroke", "fill", "metadata",
    "context", "html", "enum", "list", "numbering", "outline", "heading",
    "columns", "column", "grid", "stack", "place", "move", "rotate",
    "scale", "pad", "inset", "outset", "spacing", "v", "h",
  ]);

  let result = text;
  result = result.replace(/#([a-zA-Z]+)/g, (match, name) => {
    if (typstFunctions.has(name)) return match;
    return "\\#" + name;
  });
  result = result.replace(/#(\d)/g, "\\#$1");
  return result;
}

function stripFormattingOutsideCodeBlocks(text) {
  const lines = text.split("\n");
  let inBlock = false;
  const result = [];

  for (const line of lines) {
    if (line.trimStart().startsWith("```")) {
      inBlock = !inBlock;
      result.push(line);
      continue;
    }
    if (inBlock) {
      result.push(line);
      continue;
    }

    let cleaned = line;
    cleaned = cleaned.replace(/\*\*/g, "");
    cleaned = cleaned.replace(/\*/g, "");
    cleaned = cleaned.replace(/_/g, "");
    cleaned = cleaned.replace(/~~([^~]+)~~/g, "$1");
    cleaned = cleaned.replace(/\\times/g, " times ");
    cleaned = cleaned.replace(/\\(?!")/g, "");
    result.push(cleaned);
  }
  return result.join("\n");
}

function convertInlineFormatting(text) {
  return stripFormattingOutsideCodeBlocks(text);
}

function convertTableToTypst(lines) {
  const rows = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("|") || !trimmed.endsWith("|")) continue;
    const cells = trimmed.split("|").slice(1, -1).map(c => c.trim());
    if (cells.every(c => /^[-:]+$/.test(c.replace(/\s/g, "")))) continue;
    rows.push(cells);
  }

  if (rows.length === 0) return "";

  const numCols = Math.max(...rows.map(r => r.length));

  let result = "#table(";
  result += `columns: (${Array(numCols).fill("auto").join(", ")}),`;

  if (rows.length > 0) {
    result += "\n  table.header(";
    result += rows[0].map(c => `[${escapeTypstText(c)}]`).join(", ");
    result += "),";
    for (let r = 1; r < rows.length; r++) {
      result += "\n  " + rows[r].map(c => `[${escapeTypstText(c)}]`).join(", ");
      if (r < rows.length - 1) result += ",";
    }
  }

  result += "\n)";
  return result;
}

function escapeTypstContent(text) {
  return text.replace(/\[/g, "\\[").replace(/\]/g, "\\]").replace(/\(/g, "\\(").replace(/\)/g, "\\)").replace(/#/g, "\\#");
}
function escapeTypstString(text) {
  return text.replace(/"/g, '\\"');
}

function hasChinese(text) {
  return /[\u4e00-\u9fff\u3400-\u4dbf]/.test(text);
}

function generateTemplateHeader(title, date, tags, desc, isChinese) {
  const tagList = tags.length > 0
    ? tags.map(t => `    blog-tags.${t},`).join("\n")
    : "    blog-tags.misc,";

  const showMain = isChinese ? "main-zh" : "main";

  return `#import "/typ/templates/blog.typ": *

#show: ${showMain}.with(
  title: "${escapeTypstString(title)}",
  desc: [${escapeTypstContent(desc || title)}],
  date: "${date}",
  tags: (
${tagList}
  ),
  show-outline: true,
)

`;
}

function getTagFromNotion(notionTags) {
  if (!notionTags || notionTags.length === 0) return ["misc"];
  const result = new Set();
  for (const tag of notionTags) {
    const mapped = TAG_MAP[tag];
    if (mapped) {
      result.add(mapped);
    }
  }
  if (result.size === 0) result.add("misc");
  return [...result];
}

async function syncAll() {
  console.log("Fetching articles from Notion Archive database...\n");

  let allPages = [];
  let cursor;

  do {
    const response = await notion.dataSources.query({
      data_source_id: DATA_SOURCE_ID,
      start_cursor: cursor,
      page_size: 50,
    });
    allPages.push(...response.results);
    cursor = response.next_cursor || undefined;
  } while (cursor);

  allPages.sort((a, b) => {
    const dateA = a.properties.Published?.date?.start || "";
    const dateB = b.properties.Published?.date?.start || "";
    return dateA.localeCompare(dateB);
  });

  console.log(`Found ${allPages.length} articles in Notion.\n`);

  let totalImageDownloads = 0;

  for (const page of allPages) {
    const titleProp = page.properties.Name;
    const title = titleProp?.title?.[0]?.plain_text || "Untitled";
    const date = page.properties.Published?.date?.start || page.created_time.split("T")[0];
    const notionTags = page.properties.Tags?.multi_select?.map(t => t.name) || [];
    const tags = getTagFromNotion(notionTags);

    const slug = slugify(title, page.id);
    const filePath = path.join(ARTICLE_DIR, `${slug}.typ`);

    if (fs.existsSync(filePath)) {
      console.log(`  Skipping (exists): ${title}`);
      continue;
    }

    console.log(`  Syncing: ${title}`);

    let markdown;
    try {
      const mdResponse = await fetch(
        `https://api.notion.com/v1/pages/${page.id}/markdown`,
        {
          headers: {
            "Authorization": `Bearer ${NOTION_TOKEN}`,
            "Notion-Version": "2026-03-11",
          },
        }
      );
      if (!mdResponse.ok) {
        console.warn(`    Warning: Failed to fetch markdown (${mdResponse.status}), creating minimal post`);
        markdown = `# ${title}\n\n`;
      } else {
        const mdData = await mdResponse.json();
        markdown = mdData.markdown || `# ${title}\n\n`;
      }
    } catch (err) {
      console.warn(`    Warning: Error fetching markdown: ${err.message}`);
      markdown = `# ${title}\n\n`;
    }

    const titleFromMd = extractTitle(markdown);
    const { content, imageDownloads } = convertMarkdownToTypst(markdown, slug);
    const desc = extractFirstParagraph(markdown);
    const cleanDesc = desc.replace(/\$`[^`]*`\$/g, "").replace(/\$[^$]*\$/g, "").replace(/<[^>]+>/g, "").trim() || title;
    totalImageDownloads += imageDownloads.length;

    const isChinese = hasChinese(title) || hasChinese(cleanDesc) || hasChinese(content);
const header = generateTemplateHeader(title, date, tags, cleanDesc, isChinese);
    const fullContent = header + content.trim() + "\n";

    fs.writeFileSync(filePath, fullContent, "utf-8");
    console.log(`    Written: content/article/${slug}.typ`);

    for (const img of imageDownloads) {
      console.log(`    Downloading image ${img.index}...`);
      await downloadImage(img.url, img.articleSlug, img.index);
    }
  }

  console.log(`\nDone! All articles synced.`);
  console.log(`Total image downloads scheduled: ${totalImageDownloads}`);
}

syncAll().catch(err => {
  console.error("Error:", err);
  process.exit(1);
});
