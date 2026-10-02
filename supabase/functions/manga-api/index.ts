import * as cheerio from "npm:cheerio@1.0.0";

// api.komiku.org returns HTMX fragments with .bge elements (same HTML as before)
// komiku.org main site now loads content dynamically via HTMX from api.komiku.org
const API_BASE = "https://api.komiku.org";
const KOMIKU_BASE = "https://komiku.org";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const REQUEST_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept":
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
  "Accept-Language": "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7",
  "Referer": "https://komiku.org/",
};

async function fetchApi(path: string): Promise<string> {
  const url = path.startsWith("http") ? path : `${API_BASE}${path}`;
  const resp = await fetch(url, { headers: REQUEST_HEADERS });
  if (!resp.ok) {
    throw new Error(`Failed to fetch ${url} - HTTP ${resp.status}`);
  }
  return await resp.text();
}

async function fetchKomiku(path: string): Promise<string> {
  const url = path.startsWith("http") ? path : `${KOMIKU_BASE}${path}`;
  const resp = await fetch(url, { headers: REQUEST_HEADERS });
  if (!resp.ok) {
    throw new Error(`Failed to fetch ${url} - HTTP ${resp.status}`);
  }
  return await resp.text();
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=180",
    },
  });
}

function parseMangaList($: cheerio.CheerioAPI, fallbackType?: string): any[] {
  const manga_list: any[] = [];
  $(".bge").each((_i, el) => {
    const title = $(el).find(".kan > a > h3").text().trim() ||
      $(el).find(".kan h3").text().trim() ||
      $(el).find("h3").text().trim();

    const rawHref = $(el).find(".bgei > a").attr("href") ||
      $(el).find("a").attr("href") || "";

    // Extract endpoint from href — handles both absolute and relative URLs
    const endpoint = rawHref
      .replace("https://komiku.org/manga/", "")
      .replace("https://komiku.org/", "")
      .replace("/manga/", "")
      .replace(/^\//, "")
      .replace(/\/$/, "");

    // Extract type from HTML badge (.tpe1_inf b)
    const scrapedBadge = $(el).find(".bgei > a .tpe1_inf > b").text().trim() ||
      $(el).find(".tpe1_inf b").text().trim() ||
      $(el).find(".tpe1_inf").text().trim();

    let detectedType = scrapedBadge;
    if (!detectedType && fallbackType) {
      detectedType = fallbackType;
    }
    if (!detectedType) {
      detectedType = "Manga";
    }

    // Normalize type string
    const lower = detectedType.toLowerCase();
    if (lower.includes("manhwa")) {
      detectedType = "Manhwa";
    } else if (lower.includes("manhua")) {
      detectedType = "Manhua";
    } else {
      detectedType = "Manga";
    }

    const updated_on = $(el).find(".kan > .judul2").text().split("|")[0]?.trim() ||
      $(el).find(".kan span.judul2").text().trim();

    const thumb = $(el).find(".bgei img").attr("src") ||
      $(el).find(".bgei img").attr("data-src") ||
      $(el).find("img").attr("src") || "";

    // Latest chapter link
    const chapterLinks = $(el).find(".new1 a");
    let chapter = "";
    chapterLinks.each((_j, link) => {
      const label = $(link).find("span:first-child").text().trim();
      if (label.toLowerCase().includes("terbaru") || label.toLowerCase().includes("ch")) {
        chapter = $(link).find("span:last-child").text().trim();
      }
    });
    if (!chapter && chapterLinks.length > 0) {
      chapter = $(chapterLinks[chapterLinks.length - 1]).text().trim();
    }

    if (title && endpoint) {
      manga_list.push({ title, thumb, type: detectedType, updated_on, endpoint, chapter });
    }
  });
  return manga_list;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname
      .replace(/^\/manga-api/, "")
      .replace(/^\/functions\/v1\/manga-api/, "");
    const q = url.searchParams.get("q") || url.searchParams.get("query") || "";

    // ── 0. Image Proxy ───────────────────────────────────────
    // GET /img-proxy?url=<encoded-image-url>
    // Bypasses CORS for thumbnail.komiku.org images on web
    if (path.includes("/img-proxy")) {
      const imageUrl = url.searchParams.get("url");
      if (!imageUrl) {
        return new Response("Missing url param", { status: 400, headers: corsHeaders });
      }
      const imgResp = await fetch(imageUrl, {
        headers: {
          "Referer": "https://komiku.org/",
          "User-Agent": REQUEST_HEADERS["User-Agent"],
        },
      });
      if (!imgResp.ok) {
        return new Response("Image fetch failed", { status: imgResp.status, headers: corsHeaders });
      }
      const contentType = imgResp.headers.get("content-type") || "image/jpeg";
      return new Response(imgResp.body, {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": contentType,
          "Cache-Control": "public, max-age=86400", // cache 24 jam
        },
      });
    }

    // ── 2. Popular Manga (with optional tipe filter) ──────────
    // GET /manga/popular/:page?tipe=manhwa|manga|manhua
    const popularMatch = path.match(/\/manga\/popular(?:\/page)?\/?(\d+)?/);
    if (popularMatch || path === "/manga/popular") {
      const page = popularMatch?.[1] || url.searchParams.get("page") || "1";
      const rawTipe = url.searchParams.get("tipe") || url.searchParams.get("type") || "";
      const tipe = rawTipe.toLowerCase();
      const tipeParam = (tipe === "manhwa" || tipe === "manhua" || tipe === "manga") ? `&tipe=${tipe}` : "";
      const apiPath = page === "1"
        ? `/manga/?orderby=popular${tipeParam}`
        : `/manga/page/${page}/?orderby=popular${tipeParam}`;
      const html = await fetchApi(apiPath);
      const $ = cheerio.load(html);
      const manga_list = parseMangaList($, tipe ? (tipe === "manhwa" ? "Manhwa" : tipe === "manhua" ? "Manhua" : "Manga") : undefined);

      return jsonResponse({ status: true, message: "success", total: manga_list.length, manga_list });
    }

    // ── 3. Recommended / Hot ─────────────────────────────────
    // GET /recommended/:page
    const recMatch = path.match(/\/recommended\/?(\d+)?/);
    if (recMatch) {
      const page = recMatch[1] || "1";
      const apiPath = page === "1" ? "/other/hot/" : `/other/hot/page/${page}/`;
      const html = await fetchApi(apiPath);
      const $ = cheerio.load(html);
      const manga_list = parseMangaList($);

      return jsonResponse({ status: true, message: "success", manga_list });
    }

    // ── 4. Manhwa (Korea Only) ───────────────────────────────
    // GET /manhwa/page/:page  OR  GET /manhwa
    const manhwaMatch = path.match(/\/manhwa(?:\/page)?\/(\d+)/) || (path === "/manhwa" ? ["", "1"] : null);
    if (manhwaMatch) {
      const page = manhwaMatch[1] || url.searchParams.get("page") || "1";
      const apiPath = page === "1"
        ? "/manga/?tipe=manhwa"
        : `/manga/page/${page}/?tipe=manhwa`;
      const html = await fetchApi(apiPath);
      const $ = cheerio.load(html);
      const manga_list = parseMangaList($, "Manhwa");

      return jsonResponse({ status: true, message: "success", total: manga_list.length, manga_list });
    }

    // ── 5. Manhua (China Only) ───────────────────────────────
    // GET /manhua/page/:page  OR  GET /manhua
    const manhuaMatch = path.match(/\/manhua(?:\/page)?\/(\d+)/) || (path === "/manhua" ? ["", "1"] : null);
    if (manhuaMatch) {
      const page = manhuaMatch[1] || url.searchParams.get("page") || "1";
      const apiPath = page === "1"
        ? "/manga/?tipe=manhua"
        : `/manga/page/${page}/?tipe=manhua`;
      const html = await fetchApi(apiPath);
      const $ = cheerio.load(html);
      const manga_list = parseMangaList($, "Manhua");

      return jsonResponse({ status: true, message: "success", total: manga_list.length, manga_list });
    }

    // ── 6. Manga (Jepang Only) ───────────────────────────────
    // GET /manga/japan/page/:page  OR  GET /manga/japan
    const japanMatch = path.match(/\/manga\/japan(?:\/page)?\/(\d+)/) || (path === "/manga/japan" ? ["", "1"] : null);
    if (japanMatch) {
      const page = japanMatch[1] || url.searchParams.get("page") || "1";
      const apiPath = page === "1"
        ? "/manga/?tipe=manga"
        : `/manga/page/${page}/?tipe=manga`;
      const html = await fetchApi(apiPath);
      const $ = cheerio.load(html);
      const manga_list = parseMangaList($, "Manga");

      return jsonResponse({ status: true, message: "success", total: manga_list.length, manga_list });
    }

    // ── 1. Latest Manga (All / filtered by ?tipe=) ────────────
    // GET /manga/page/:page  OR  GET /  OR  GET /manga
    const latestMatch = path.match(/\/manga(?:\/page)?\/(\d+)/);
    if (latestMatch || path === "/manga" || path === "/" || path === "") {
      const page = latestMatch ? latestMatch[1] : (url.searchParams.get("page") || "1");
      const rawTipe = url.searchParams.get("tipe") || url.searchParams.get("type") || "";
      const tipe = rawTipe.toLowerCase();
      const tipeParam = (tipe === "manhwa" || tipe === "manhua" || tipe === "manga") ? `?tipe=${tipe}` : "";
      const apiPath = page === "1"
        ? (tipeParam ? `/manga/${tipeParam}` : "/manga/")
        : (tipeParam ? `/manga/page/${page}/${tipeParam}` : `/manga/page/${page}/`);
      const html = await fetchApi(apiPath);
      const $ = cheerio.load(html);
      const manga_list = parseMangaList($, tipe ? (tipe === "manhwa" ? "Manhwa" : tipe === "manhua" ? "Manhua" : "Manga") : undefined);

      return jsonResponse({
        status: true,
        message: "success",
        total: manga_list.length,
        manga_list,
      });
    }

    // ── 7. Search ────────────────────────────────────────────
    // GET /search?q=...
    if (path.includes("/search") || q) {
      const query = q;
      const rawTipe = url.searchParams.get("tipe") || url.searchParams.get("type") || "";
      let apiPath = `/?s=${encodeURIComponent(query)}`;
      if (rawTipe) {
        apiPath += `&tipe=${encodeURIComponent(rawTipe)}`;
      }
      const html = await fetchApi(apiPath);
      const $ = cheerio.load(html);
      const manga_list = parseMangaList($);

      return jsonResponse({ status: true, message: "success", manga_list });
    }

    // ── 7. Manga Detail & Chapters ───────────────────────────
    // GET /manga/detail/:endpoint
    const detailMatch = path.match(/\/manga\/detail\/(.+)/);
    if (detailMatch) {
      const slug = detailMatch[1].replace(/^\//, "").replace(/\/$/, "");
      const html = await fetchKomiku(`/manga/${slug}/`);
      const $ = cheerio.load(html);

      const title = $("#Judul > h1").text().trim() ||
        $(".jdl h1").text().trim() ||
        $("h1").first().text().trim();

      const type = $(".inftable tr:nth-child(2) td:nth-child(2)").text().trim() ||
        $("tr:nth-child(2) > td:nth-child(2)").find("b").text().trim() || "Manga";

      const author = $("#Informasi table tbody tr:nth-child(4) td:nth-child(2)").text().trim() ||
        $(".inftable tr:nth-child(4) td:nth-child(2)").text().trim() || "Unknown";

      const status = $(".inftable tr:nth-child(5) td:nth-child(2)").text().trim() ||
        $(".inftable tr:nth-child(3) td:nth-child(2)").text().trim() || "Ongoing";

      const thumb = $(".ims > img").attr("src") ||
        $(".ims > img").attr("data-src") ||
        $(".perapih .ims img").attr("src") || "";

      const synopsis = $("#Sinopsis p").text().trim() ||
        $(".desc").text().trim() ||
        $(".sinopsis p").text().trim();

      const genre_list: any[] = [];
      $(".genre > li").each((_i, el) => {
        const genre_name = $(el).find("a").text().trim();
        if (genre_name) genre_list.push({ genre_name });
      });

      const chapter: any[] = [];
      $("#Daftar_Chapter tbody tr").each((_i, el) => {
        const chapter_title = $(el).find("a").text().trim();
        const rawHref = $(el).find("a").attr("href") || "";
        const released_at = $(el).find(".tanggalseries").text().trim() ||
          $(el).find("td").eq(2).text().trim();
        const chapter_endpoint = rawHref
          .replace("https://komiku.org/", "")
          .replace(/^\//, "")
          .replace(/\/$/, "");
        if (chapter_title && chapter_endpoint) {
          chapter.push({ chapter_title, chapter_endpoint, released_at });
        }
      });

      return jsonResponse({
        title,
        type,
        author,
        status,
        manga_endpoint: slug,
        thumb,
        genre_list,
        synopsis,
        chapter,
      });
    }

    // ── 8. Chapter Pages ─────────────────────────────────────
    // GET /chapter/:endpoint
    const chapterMatch = path.match(/\/chapter\/(.+)/);
    if (chapterMatch) {
      const slug = chapterMatch[1].replace(/^\//, "").replace(/\/$/, "");
      const html = await fetchKomiku(`/${slug}/`);
      const $ = cheerio.load(html);

      const title = $("#Judul header p a b").text().trim() ||
        $("header .judulseries a").text().trim() ||
        $("h1").first().text().replace("Komik ", "").trim();

      const chapter_image: any[] = [];
      $("#Baca_Komik img").each((i, el) => {
        const rawSrc = $(el).attr("src") || $(el).attr("data-src") || "";
        const chapter_image_link = rawSrc.replace("i0.wp.com/", "");
        if (chapter_image_link) {
          chapter_image.push({
            chapter_image_link,
            image_number: i + 1,
          });
        }
      });

      return jsonResponse({
        chapter_endpoint: `${slug}/`,
        chapter_name: slug.split("-").join(" ").trim(),
        title,
        chapter_pages: chapter_image.length,
        chapter_image,
      });
    }

    // ── 9. Genres List ───────────────────────────────────────
    if (path.includes("/genres")) {
      const list_genre = [
        { genre_name: "Action", endpoint: "action" },
        { genre_name: "Adventure", endpoint: "adventure" },
        { genre_name: "Comedy", endpoint: "comedy" },
        { genre_name: "Drama", endpoint: "drama" },
        { genre_name: "Fantasy", endpoint: "fantasy" },
        { genre_name: "Horror", endpoint: "horror" },
        { genre_name: "Isekai", endpoint: "isekai" },
        { genre_name: "Martial Arts", endpoint: "martial-arts" },
        { genre_name: "Mystery", endpoint: "mystery" },
        { genre_name: "Romance", endpoint: "romance" },
        { genre_name: "Sci-Fi", endpoint: "sci-fi" },
        { genre_name: "Slice of Life", endpoint: "slice-of-life" },
        { genre_name: "Supernatural", endpoint: "supernatural" },
      ];
      return jsonResponse({ status: true, message: "success", list_genre });
    }

    return jsonResponse({ error: "Endpoint not found", path }, 404);
  } catch (err: any) {
    return jsonResponse({ status: false, message: err.message || String(err) }, 500);
  }
});
