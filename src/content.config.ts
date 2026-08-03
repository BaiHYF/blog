import { kEnableArchive } from "$consts";
import { glob } from "astro/loaders";
import { defineCollection, z } from "astro:content";

const blog = defineCollection({
  // Load Markdown/MDX/Typst files in the `content/article/` directory.
  loader: glob({ base: "./content/article", pattern: "**/*.{md,mdx,typ}" }),
  // Type-check frontmatter using a schema
  schema: z.object({
    title: z.string(),
    author: z.string().optional(),
    description: z.any().optional(),
    date: z.coerce.date(),
    // Transform string to Date object
    updatedDate: z.coerce.date().optional(),
    tags: z.array(z.string()).optional(),
  }),
});

const archive = kEnableArchive
  ? {
      archive: defineCollection({
        // Load Markdown/MDX/Typst files in the `content/archive/` directory.
        loader: glob({ base: "./content/archive", pattern: "**/*.{md,mdx,typ}" }),
        // Type-check frontmatter using a schema
        schema: z.object({
          title: z.string(),
          author: z.string().optional(),
          description: z.any().optional(),
          date: z.coerce.date(),
          indices: z.array(z.string()).optional(),
          // Transform string to Date object
          updatedDate: z.coerce.date().optional(),
          tags: z.array(z.string()).optional(),
        }),
      }),
    }
  : {};

export const collections = { blog, ...archive };
