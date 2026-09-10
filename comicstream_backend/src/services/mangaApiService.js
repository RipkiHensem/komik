const cheerio = require('cheerio');

const API_URL = 'https://api.komiku.org';
const WEB_URL = 'https://komiku.org';

const HEADERS = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://komiku.org/',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  'Accept-Language': 'id,en-US;q=0.9,en;q=0.8',
};

const TIMEOUT_MS = 10000;

const SLUG_ALIASES = {
  // Popular Manga with Indonesian / customized slug URLs
  'haikyuu': 'haikyuu-indonesia',
  'haikyu': 'haikyuu-indonesia',
  'one-piece': 'komik-one-piece-indo',
  'komik-one-piece': 'komik-one-piece-indo',
  'solo-leveling': 'solo-leveling-id',
  'chainsaw-man': '123213-chainsaw-man',
  'jujutsu-kaisen': 'jujutsu-kaisen-indo',
  'kimetsu-no-yaiba': 'kimetsu-no-yaiba-indonesia',
  'demon-slayer': 'kimetsu-no-yaiba-indonesia',
  'black-clover': 'black-clover-indonesia',
  'my-hero-academia': 'boku-no-hero-academia-indonesia',
  'boku-no-hero-academia': 'boku-no-hero-academia-indonesia',
  'kaiju-no-8': '8kaijuu',
  'kaiju-8': '8kaijuu',
  '8kaijuu': '8kaijuu',
  'tokyo-revengers': 'tokyo%e5%8d%8drevengers',
  'attack-on-titan': 'shingeki-no-kyojin',
  'shingeki-no-kyojin': 'shingeki-no-kyojin',
  'dr-stone': 'dr-stone-indo',
  'hunter-x-hunter': 'hunter-x-hunter',
  'naruto': 'naruto',
  'boruto': 'boruto',
  'death-note': 'death-note',
  'bleach': 'bleach',
  'blue-lock': 'blue-lock',
  'wind-breaker': 'wind-breaker',
  'spy-x-family': 'spy-x-family',
  'tokyo-ghoul': 'tokyo-ghoul',
  'tower-of-god': 'tower-of-god-side-story-urek-mazino',
  'return-of-the-mount-hua-sect': 'return-of-the-flowery-mountain-sect',
  'the-beginning-after-the-end': 'the-beginning-after-the-end',
  'omniscient-readers-viewpoint': 'omniscient-readers-viewpoint',
  'nano-machine': 'nano-machine',
  'eleceed': 'eleceed',
  'lookism': 'lookism',
};

/**
 * Automatically resolve obscure / customized Komiku slugs by querying Komiku
 * and inspecting chapter breadcrumb links back to the parent manga.
 */
async function resolveMangaSlug(slug) {
  try {
    const clean = slug.replace(/^\//, '').replace(/\/$/, '').toLowerCase();
    if (SLUG_ALIASES[clean]) return SLUG_ALIASES[clean];

    const searchUrl = `${API_URL}/?s=${encodeURIComponent(clean.replace(/-/g, ' '))}`;
    const html = await fetchHtml(searchUrl);
    const $ = cheerio.load(html);

    let firstChapterLink = '';
    $('.bge').each((_, el) => {
      if (!firstChapterLink) {
        const href = $(el).find('.kan a').attr('href') || $(el).find('a').attr('href');
        if (href && (href.includes('-chapter-') || href.includes('/ch/'))) {
          firstChapterLink = href;
        }
      }
    });

    if (!firstChapterLink) return null;

    const chUrl = firstChapterLink.startsWith('http') ? firstChapterLink : `${WEB_URL}${firstChapterLink}`;
    const chHtml = await fetchHtml(chUrl);
    const $ch = cheerio.load(chHtml);

    let foundSlug = null;
    $ch('a[href*="/manga/"]').each((_, el) => {
      if (!foundSlug) {
        const href = $ch(el).attr('href') || '';
        const match = href.match(/\/manga\/([^/]+)/);
        if (match && match[1]) {
          foundSlug = match[1];
        }
      }
    });

    if (foundSlug) {
      SLUG_ALIASES[clean] = foundSlug;
      return foundSlug;
    }
  } catch (_) {}
  return null;
}

/**
 * Fetch HTML with timeout and proper headers
 */
async function fetchHtml(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      headers: HEADERS,
      signal: controller.signal,
    });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status} for ${url}`);
    }
    return await res.text();
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Format string title from slug if title is missing / Untitled
 */
function cleanTitleFromSlug(slug) {
  if (!slug) return 'Komik';
  const clean = slug
    .split('-chapter-')[0]
    .replace(/-(indonesia|indo|id)$/i, '');
  return clean
    .split('-')
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

/**
 * Parse Indonesian relative time or date string (e.g. "8 menit lalu", "1 jam lalu", "2 hari lalu", "18/07/2020")
 * to an ISO timestamp string. Falls back to staggered offset by index to preserve release ordering.
 */
function parseRelativeTime(text, indexFallback = 0) {
  if (text) {
    const clean = text.trim();

    // 1. DD/MM/YYYY or DD-MM-YYYY
    const dmyMatch = clean.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
    if (dmyMatch) {
      const day = parseInt(dmyMatch[1], 10);
      const month = parseInt(dmyMatch[2], 10) - 1;
      const year = parseInt(dmyMatch[3], 10);
      let d = new Date(year, month, day, 0, 0, 0);
      if (d.getTime() > Date.now()) {
        d = new Date();
      }
      if (!isNaN(d.getTime())) return d.toISOString();
    }

    // 2. YYYY-MM-DD
    const ymdMatch = clean.match(/^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})$/);
    if (ymdMatch) {
      const year = parseInt(ymdMatch[1], 10);
      const month = parseInt(ymdMatch[2], 10) - 1;
      const day = parseInt(ymdMatch[3], 10);
      let d = new Date(year, month, day, 0, 0, 0);
      if (d.getTime() > Date.now()) {
        d = new Date();
      }
      if (!isNaN(d.getTime())) return d.toISOString();
    }

    // 3. Relative text (e.g. "8 menit lalu", "2 jam lalu", "5 bulan yang lalu")
    const secMatch = clean.match(/(\d+)\s*(?:detik|sec)/i);
    if (secMatch) return new Date(Date.now() - parseInt(secMatch[1], 10) * 1000).toISOString();

    const minMatch = clean.match(/(\d+)\s*(?:menit|min)/i);
    if (minMatch) return new Date(Date.now() - parseInt(minMatch[1], 10) * 60000).toISOString();

    const hrMatch = clean.match(/(\d+)\s*(?:jam|hour)/i);
    if (hrMatch) return new Date(Date.now() - parseInt(hrMatch[1], 10) * 3600000).toISOString();

    const dayMatch = clean.match(/(\d+)\s*(?:hari|day)/i);
    if (dayMatch) return new Date(Date.now() - parseInt(dayMatch[1], 10) * 86400000).toISOString();

    const weekMatch = clean.match(/(\d+)\s*(?:minggu|week)/i);
    if (weekMatch) return new Date(Date.now() - parseInt(weekMatch[1], 10) * 7 * 86400000).toISOString();

    const monthMatch = clean.match(/(\d+)\s*(?:bulan|month)/i);
    if (monthMatch) return new Date(Date.now() - parseInt(monthMatch[1], 10) * 30 * 86400000).toISOString();

    const yrMatch = clean.match(/(\d+)\s*(?:tahun|year)/i);
    if (yrMatch) return new Date(Date.now() - parseInt(yrMatch[1], 10) * 365 * 86400000).toISOString();
  }

  // Fallback: older chapters are staggered backwards by days so they don't share identical timestamps
  if (indexFallback > 0) {
    return new Date(Date.now() - indexFallback * 3 * 86400000).toISOString();
  }
  return new Date().toISOString();
}

/**
 * Parse view count like "10rb", "227rb", "3jt" to integer
 */
function parseViewCount(text) {
  if (!text) return 0;
  const jtMatch = text.match(/([\d.,]+)\s*jt/i);
  if (jtMatch) return Math.round(parseFloat(jtMatch[1].replace(',', '.')) * 1000000);
  const rbMatch = text.match(/([\d.,]+)\s*rb/i);
  if (rbMatch) return Math.round(parseFloat(rbMatch[1].replace(',', '.')) * 1000);
  const numMatch = text.match(/(\d+)/);
  if (numMatch) return parseInt(numMatch[1], 10);
  return 0;
}

/**
 * Convert raw scraped data to standard ComicModel
 */
function toComicModel(item) {
  const rawType = (item.type || '').toLowerCase();
  const genresCombined = (
    Array.isArray(item.genres)
      ? item.genres.join(' ')
      : (item.genreText || '')
  ).toLowerCase();

  let format = 'Manga';
  if (rawType.includes('manhwa') || genresCombined.includes('manhwa')) {
    format = 'Manhwa';
  } else if (rawType.includes('manhua') || genresCombined.includes('manhua')) {
    format = 'Manhua';
  } else if (rawType.includes('manga') || genresCombined.includes('manga')) {
    format = 'Manga';
  }

  let genres = ['Action'];
  if (Array.isArray(item.genres) && item.genres.length) {
    genres = item.genres;
  } else if (item.genreText) {
    genres = item.genreText.split('•').map((g) => g.trim()).filter(Boolean);
  } else {
    genres = [format, 'Action'];
  }

  let coverUrl = item.thumb || '';
  if (coverUrl.startsWith('http')) {
    coverUrl = `/api/proxy/image?url=${encodeURIComponent(coverUrl)}`;
  }

  const updatedAt = item.updated_at || new Date().toISOString();

  return {
    id: item.slug,
    title: item.title,
    alternative_title: item.alternative_title || null,
    synopsis: item.synopsis || `${item.title} Bahasa Indonesia - Baca komik ${item.title} gratis online di ComicStream.`,
    cover_url: coverUrl,
    genre: genres,
    status: item.status || 'Ongoing',
    author: item.author || 'Komiku Author',
    artist: item.artist || null,
    format: format,
    rating: typeof item.rating === 'number' ? item.rating : 9.0,
    view_count: item.view_count || Math.floor(Math.random() * 500000) + 100000,
    bookmark_count: item.bookmark_count || Math.floor(Math.random() * 20000) + 5000,
    chapter_count: item.chapter_count || 0,
    created_at: new Date().toISOString(),
    updated_at: updatedAt,
    latest_update_at: updatedAt,
  };
}

/**
 * Parse `.bge` manga card elements (used on api.komiku.org)
 */
function parseBgeElements($, defaultType = 'Manga') {
  const map = new Map();

  $('.bge').each((_, el) => {
    const titleLink = $(el).find('.kan h3').length
      ? $(el).find('.kan h3')
      : $(el).find('h3');
    let title = titleLink.text().trim();

    const link =
      $(el).find('.kan a').attr('href') ||
      $(el).find('.bgei a').attr('href') ||
      $(el).find('a').attr('href') ||
      '';

    let slug = link
      .replace(/^https?:\/\/[^/]+/, '')
      .replace(/\/manga\//, '')
      .replace(/^\//, '')
      .replace(/\/$/, '')
      .replace(/^ch\//, '');

    // If link is a chapter link, extract comic slug
    if (slug.includes('-chapter-')) {
      slug = slug.split('-chapter-')[0];
    }

    const normSlug = slug.toLowerCase();
    if (SLUG_ALIASES[normSlug]) {
      slug = SLUG_ALIASES[normSlug];
    }

    if (!slug) return;

    if (!title || title.toLowerCase() === 'untitled') {
      title = cleanTitleFromSlug(slug);
    }

    const typeText =
      $(el).find('.bgei .tpe1_inf b').text().trim() ||
      $(el).find('.tpe1_inf b').text().trim() ||
      '';

    const fullInf = $(el).find('.tpe1_inf').text().trim();
    let type = typeText;
    if (!type) {
      if (fullInf.toLowerCase().includes('manhwa')) type = 'Manhwa';
      else if (fullInf.toLowerCase().includes('manhua')) type = 'Manhua';
      else if (fullInf.toLowerCase().includes('manga')) type = 'Manga';
      else type = defaultType;
    }
    let genreExtra = fullInf.replace(typeText, '').trim();

    const judul2 = $(el).find('.judul2').text().trim();
    const updatedAt = parseRelativeTime(judul2, map.size);
    const views = parseViewCount(judul2);

    let thumb =
      $(el).find('.bgei img').attr('src') ||
      $(el).find('.bgei img').attr('data-src') ||
      $(el).find('img').attr('src') ||
      '';

    // If placeholder lazy thumb, fallback to thumbnail CDN
    if (!thumb || thumb.includes('lazy.jpg')) {
      thumb = `https://thumbnail.komiku.to/uploads/manga/${slug}/manga_thumbnail-Komik-${cleanTitleFromSlug(slug).replace(/\s+/g, '-')}.jpg`;
    }

    const synopsis = $(el).find('.kan p').text().trim() || `${title} Bahasa Indonesia`;

    const genreList = [type];
    if (genreExtra) {
      genreList.push(genreExtra);
    }

    let chapterCount = 0;
    const new1Text = $(el).find('.new1').text();
    const kanText = $(el).find('.kan').text();
    const chMatch =
      new1Text.match(/Terbaru:\s*Chapter\s*(\d+(\.\d+)?)/i) ||
      kanText.match(/Terbaru:\s*Chapter\s*(\d+(\.\d+)?)/i) ||
      new1Text.match(/Chapter\s*(\d+(\.\d+)?)/i);
    if (chMatch) {
      chapterCount = Math.floor(parseFloat(chMatch[1])) || 0;
    } else {
      $(el).find('.kan a').each((_, a) => {
        const aText = $(a).text();
        const m = aText.match(/Chapter\s*(\d+(\.\d+)?)/i);
        if (m) {
          const num = Math.floor(parseFloat(m[1]));
          if (num > chapterCount) chapterCount = num;
        }
      });
    }

    if (!map.has(slug)) {
      map.set(
        slug,
        toComicModel({
          slug,
          title,
          type: type || defaultType,
          thumb,
          synopsis,
          genres: genreList,
          view_count: views > 0 ? views : undefined,
          chapter_count: chapterCount,
          updated_at: updatedAt,
        })
      );
    }
  });

  return Array.from(map.values());
}

/**
 * Parse `article.manga-card` elements (used on komiku.org/daftar-komik)
 */
function parseMangaCards($, defaultType = 'Manhwa') {
  const list = [];
  $('article.manga-card').each((_, el) => {
    const link = $(el).find('h4 a').attr('href') || $(el).find('a').attr('href') || '';
    const slug = link.replace(/.*\/manga\//, '').replace(/^\//, '').replace(/\/$/, '');
    const title = $(el).find('h4 a').text().trim() || cleanTitleFromSlug(slug);

    const imgEl = $(el).find('img');
    let thumb = imgEl.attr('data-src') || imgEl.attr('src') || '';
    if (thumb.includes('lazy.jpg') && imgEl.attr('data-src')) {
      thumb = imgEl.attr('data-src');
    }

    const meta = $(el).find('.meta').text().trim();
    let type = defaultType;
    let status = 'Ongoing';
    let genreText = '';

    if (meta) {
      const parts = meta.split('\n').map((p) => p.trim()).filter(Boolean);
      if (parts.length > 0) {
        genreText = parts[0];
        if (parts[0].toLowerCase().includes('manhwa')) type = 'Manhwa';
        else if (parts[0].toLowerCase().includes('manhua')) type = 'Manhua';
        else if (parts[0].toLowerCase().includes('manga')) type = 'Manga';
      }
      if (parts.length > 1 && parts[1].toLowerCase().includes('end')) {
        status = 'Completed';
      }
    }

    if (slug && title) {
      list.push(
        toComicModel({
          slug,
          title,
          type,
          thumb,
          status,
          genreText,
          synopsis: `${title} (${type}) - Baca komik ${title} gratis di ComicStream.`,
          updated_at: parseRelativeTime(null, list.length),
        })
      );
    }
  });

  return list;
}

/**
 * 1. Get Latest Manga Update (supports format: 'manga', 'manhwa', 'manhua')
 */
async function getLatestManga(page = 1, format = null) {
  try {
    let url = `${API_URL}/manga/page/${page}/`;
    if (format && format.trim()) {
      url += `?tipe=${encodeURIComponent(format.trim().toLowerCase())}`;
    }
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);
    const defaultType = format ? (format.charAt(0).toUpperCase() + format.slice(1).toLowerCase()) : 'Manga';
    const items = parseBgeElements($, defaultType);
    if (items.length > 0) return items;
  } catch (_) {}

  // Fallback to web daftar-komik
  try {
    let url = page === 1 ? `${WEB_URL}/daftar-komik/` : `${WEB_URL}/daftar-komik/page/${page}/`;
    if (format && format.trim()) {
      url += `?tipe=${encodeURIComponent(format.trim().toLowerCase())}`;
    }
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);
    return parseMangaCards($, format || 'Manga');
  } catch (err) {
    console.error('getLatestManga error:', err.message);
    return [];
  }
}

/**
 * 2. Get Popular Manga (supports format)
 */
async function getPopularManga(page = 1, format = null) {
  try {
    const path = page === 1 ? '/other/hot/' : `/other/hot/page/${page}/`;
    let url = `${API_URL}${path}`;
    if (format && format.trim()) {
      url += `?tipe=${encodeURIComponent(format.trim().toLowerCase())}`;
    }
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);
    const defaultType = format ? (format.charAt(0).toUpperCase() + format.slice(1).toLowerCase()) : 'Manhwa';
    const items = parseBgeElements($, defaultType);
    if (items.length > 0) return items;
  } catch (_) {}

  try {
    const path = page === 1 ? '/other/rekomendasi/' : `/other/rekomendasi/page/${page}/`;
    let url = `${API_URL}${path}`;
    if (format && format.trim()) {
      url += `?tipe=${encodeURIComponent(format.trim().toLowerCase())}`;
    }
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);
    const defaultType = format ? (format.charAt(0).toUpperCase() + format.slice(1).toLowerCase()) : 'Manhwa';
    const items = parseBgeElements($, defaultType);
    if (items.length > 0) return items;
  } catch (_) {}

  return getLatestManga(page, format);
}

/**
 * 3. Get Hot / Trending Manga (supports format)
 */
async function getHotManga(page = 1, format = null) {
  try {
    const path = page === 1 ? '/other/hot/' : `/other/hot/page/${page}/`;
    let url = `${API_URL}${path}`;
    if (format && format.trim()) {
      url += `?tipe=${encodeURIComponent(format.trim().toLowerCase())}`;
    }
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);
    const defaultType = format ? (format.charAt(0).toUpperCase() + format.slice(1).toLowerCase()) : 'Manga';
    const items = parseBgeElements($, defaultType);
    if (items.length > 0) return items;
  } catch (_) {}

  return getLatestManga(page, format);
}

/**
 * 4. Get Korean Manhwa (live latest updates)
 */
async function getManhwa(page = 1) {
  return getLatestManga(page, 'manhwa');
}

/**
 * 5. Get Chinese Manhua (live latest updates)
 */
async function getManhua(page = 1) {
  return getLatestManga(page, 'manhua');
}

/**
 * 5b. Get Japanese Manga (live latest updates)
 */
async function getManga(page = 1) {
  return getLatestManga(page, 'manga');
}

/**
 * 6. Search Manga by query
 */
async function searchManga(query) {
  if (!query || !query.trim()) return [];
  const q = query.trim();

  // Try api.komiku.org/?s=
  try {
    const url = `${API_URL}/?s=${encodeURIComponent(q)}`;
    const html = await fetchHtml(url);
    const $ = cheerio.load(html);
    const items = parseBgeElements($);
    if (items.length > 0) {
      // Enrich top search results with actual covers and chapter counts if missing
      for (let i = 0; i < Math.min(items.length, 5); i++) {
        const it = items[i];
        if (!it.cover_url || it.cover_url.includes('lazy.jpg') || it.title === 'Komik' || it.chapter_count === 0) {
          try {
            const detail = await getMangaDetail(it.id);
            if (detail && detail.comic) {
              items[i] = {
                ...it,
                ...detail.comic,
                id: it.id,
                chapter_count: detail.chapters ? detail.chapters.length : it.chapter_count,
              };
            }
          } catch (_) {}
        }
      }
      return items;
    }
  } catch (_) {}

  // Fallback to searching popular/latest and filtering locally
  try {
    const list = await getLatestManga(1);
    const filtered = list.filter((c) =>
      c.title.toLowerCase().includes(q.toLowerCase()) ||
      c.id.toLowerCase().includes(q.toLowerCase())
    );
    return filtered;
  } catch (err) {
    console.error('searchManga error:', err.message);
    return [];
  }
}

/**
 * 7. Get Manga Detail & Chapter List
 */
async function getMangaDetail(slug) {
  try {
    const cleanSlug = slug.replace(/^\//, '').replace(/\/$/, '');
    const alias = SLUG_ALIASES[cleanSlug.toLowerCase()];
    const candidates = [
      alias,
      cleanSlug,
      `${cleanSlug}-indonesia`,
      `${cleanSlug}-id`,
      `${cleanSlug}-indo`,
      `komik-${cleanSlug}-indo`,
      `komik-${cleanSlug}-indonesia`,
      `komik-${cleanSlug}`,
      `${cleanSlug}-modulo`,
    ].filter(Boolean);

    let html = null;
    let resolvedSlug = cleanSlug;

    for (const cand of candidates) {
      try {
        const url = `${WEB_URL}/manga/${cand}/`;
        html = await fetchHtml(url);
        if (html) {
          resolvedSlug = cand;
          break;
        }
      } catch (_) {
        // Continue to next candidate
      }
    }

    // Dynamic fallback resolver if candidates all returned 404
    if (!html) {
      const autoSlug = await resolveMangaSlug(cleanSlug);
      if (autoSlug && !candidates.includes(autoSlug)) {
        try {
          const url = `${WEB_URL}/manga/${autoSlug}/`;
          html = await fetchHtml(url);
          if (html) {
            resolvedSlug = autoSlug;
          }
        } catch (_) {}
      }
    }

    let title = '';
    let thumb = '';
    let synopsis = '';
    let type = 'Manga';
    let author = 'Komiku Author';
    let status = 'Ongoing';
    const genres = [];
    const chapters = [];

    if (html) {
      const $ = cheerio.load(html);
      title = $('#Judul h1').text().replace(/^Komik\s*/i, '').trim() || cleanTitleFromSlug(cleanSlug);
      thumb = $('.ims img').attr('src') || $('.ims img').attr('data-src') || $('img[itemprop="image"]').attr('src') || '';
      const rawType = $('.inftable tr:contains("Tipe") td:nth-child(2)').text().trim() ||
                      $('.inftable tr:contains("Jenis") td:nth-child(2)').text().trim() ||
                      '';
      if (rawType.toLowerCase().includes('manhwa')) {
        type = 'Manhwa';
      } else if (rawType.toLowerCase().includes('manhua')) {
        type = 'Manhua';
      } else if (rawType.toLowerCase().includes('manga')) {
        type = 'Manga';
      } else {
        type = 'Manga';
      }

      author = $('.inftable tr:contains("Author") td:nth-child(2)').text().trim() ||
               $('.inftable tr:contains("Pengarang") td:nth-child(2)').text().trim() ||
               'Komiku Author';
      status = $('.inftable tr:contains("Status") td:nth-child(2)').text().trim() || 'Ongoing';

      $('.genre li a').each((_, el) => {
        const g = $(el).text().trim();
        if (g) genres.push(g);
      });

      $('#Daftar_Chapter tbody tr').each((idx, el) => {
        const chLink = $(el).find('a');
        const rawTitle = chLink.text().trim();
        const href = chLink.attr('href') || '';
        const chSlug = href.replace(/^\//, '').replace(/\/$/, '');

        if (chSlug && rawTitle) {
          const numMatch = rawTitle.match(/chapter\s*([\d.]+)/i) || chSlug.match(/chapter-([\d.]+)/i);
          const chNumber = numMatch ? parseFloat(numMatch[1]) : idx + 1;
          const dateText = $(el).find('.tanggalseries').text().trim();
          const releasedAt = parseRelativeTime(dateText, chapters.length);

          chapters.push({
            id: chSlug,
            comic_id: cleanSlug,
            chapter_number: Math.floor(chNumber),
            title: rawTitle,
            page_count: 0,
            released_at: releasedAt,
          });
        }
      });
    }

    if (!html || chapters.length === 0) {
      const fallback = await getKomikindoDetail(cleanSlug);
      if (fallback) return fallback;
      if (!html) return null;
    }

    const comic = toComicModel({
      slug: cleanSlug,
      title,
      type,
      thumb,
      synopsis,
      genres,
      author,
      status,
      chapter_count: chapters.length,
    });

    return {
      comic,
      chapters,
    };
  } catch (err) {
    console.error('getMangaDetail error:', err.message);
    return getKomikindoDetail(slug);
  }
}

/**
 * Fallback parser for Komikindo source
 */
async function getKomikindoDetail(slug) {
  try {
    const cleanSlug = slug.replace(/^\//, '').replace(/\/$/, '');
    const candidates = [
      `https://komikindo.ch/komik/${cleanSlug}/`,
      `https://komikindo.ch/komik/846048-${cleanSlug}/`,
      `https://komikindo.ch/komik/${cleanSlug}-indonesia/`,
    ];

    let html = null;
    let finalUrl = '';
    for (const u of candidates) {
      try {
        const res = await fetch(u, {
          headers: {
            ...HEADERS,
            Referer: 'https://komikindo.ch/',
          },
        });
        if (res.ok) {
          html = await res.text();
          finalUrl = u;
          break;
        }
      } catch (_) {}
    }

    if (!html) return null;

    const $ = cheerio.load(html);
    const title = $('h1').text().replace(/^Komik\s*/i, '').trim() || cleanTitleFromSlug(cleanSlug);
    const thumb = $('.thumb img').attr('src') || $('.thumb img').attr('data-src') || '';
    const synopsis = $('.entry-content.entry-content-single').text().trim() ||
                     $('.sinopsis').text().trim() ||
                     `${title} Bahasa Indonesia - Baca komik ${title} gratis di ComicStream.`;

    const chapters = [];
    $('.list-chapter li, #chapter_list li, .chapters-list li').each((idx, el) => {
      const a = $(el).find('a');
      const href = a.attr('href') || '';
      const rawTitle = a.text().trim() || $(el).find('.chapter-number').text().trim();
      const chSlug = href.replace(/^https?:\/\/[^/]+/, '').replace(/^\//, '').replace(/\/$/, '');
      const dateText = $(el).find('.dt, .chapter-date, .date').text().trim();
      const releasedAt = parseRelativeTime(dateText, chapters.length);

      if (chSlug && rawTitle) {
        const numMatch = chSlug.match(/chapter-([\d.]+)/i) || rawTitle.match(/chapter\s*([\d.]+)/i);
        const chNum = numMatch ? parseFloat(numMatch[1]) : idx + 1;

        chapters.push({
          id: chSlug,
          comic_id: cleanSlug,
          chapter_number: Math.floor(chNum),
          title: `Chapter ${Math.floor(chNum)}`,
          page_count: 0,
          released_at: releasedAt,
        });
      }
    });

    if (chapters.length === 0) return null;

    const comic = toComicModel({
      slug: cleanSlug,
      title,
      type: 'Manhwa',
      thumb,
      synopsis,
      genres: ['Action', 'Manhwa'],
      author: 'Author',
      status: 'Ongoing',
      chapter_count: chapters.length,
    });

    return { comic, chapters };
  } catch (err) {
    console.error('getKomikindoDetail error:', err.message);
    return null;
  }
}

/**
 * 8. Get Chapter Pages (Reading Images) — Multi-source (Komiku & Komikindo)
 */
async function getChapterPages(chapterSlug) {
  try {
    const cleanSlug = chapterSlug.replace(/^\//, '').replace(/\/$/, '');
    const sources = [
      `${WEB_URL}/${cleanSlug}/`,
      `https://komikindo.ch/${cleanSlug}/`,
      `https://api.komiku.org/${cleanSlug}/`,
    ];

    for (const url of sources) {
      try {
        const isKomikindo = url.includes('komikindo');
        const res = await fetch(url, {
          headers: {
            ...HEADERS,
            Referer: isKomikindo ? 'https://komikindo.ch/' : 'https://komiku.org/',
          },
        });
        if (!res.ok) continue;

        const html = await res.text();
        const $ = cheerio.load(html);
        const pages = [];

        $('#Baca_Komik img, #chimg img, .chapter-image img, #readerarea img').each((i, el) => {
          const src = $(el).attr('src') || $(el).attr('data-src');
          if (
            src &&
            !src.includes('promosi') &&
            !src.includes('iklan') &&
            !src.includes('komiku-promosi') &&
            !src.endsWith('.gif')
          ) {
            pages.push({
              id: `${cleanSlug}-page-${pages.length + 1}`,
              chapter_id: cleanSlug,
              page_number: pages.length + 1,
              image_url: src,
            });
          }
        });

        if (pages.length > 0) {
          return pages;
        }
      } catch (_) {}
    }

    return [];
  } catch (err) {
    console.error('getChapterPages error:', err.message);
    return [];
  }
}

module.exports = {
  getLatestManga,
  getPopularManga,
  getHotManga,
  getManhwa,
  getManhua,
  getManga,
  searchManga,
  getMangaDetail,
  getChapterPages,
};
