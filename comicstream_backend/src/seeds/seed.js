const { pool, initDB } = require('../config/database');
const { generateAllComicPages, COMIC_STORIES } = require('./generate_comic_pages');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

/**
 * Seed script — populates database with real comic data for ComicStream
 * Uses local covers in /public/covers/ and real comic story pages in /public/pages/
 */

const COMICS = [
  {
    slug: 'solo-leveling',
    title: 'Solo Leveling',
    alternative_title: '나 혼자만 레벨업',
    synopsis: 'Dalam dunia di mana pemburu (hunter) harus bertarung melawan monster berbahaya untuk melindungi ras manusia dari kepunahan total, Sung Jinwoo adalah hunter terlemah dari semua rank-E hunter. Suatu hari, setelah nyaris terbunuh di dungeon tingkat tinggi, sebuah quest misterius muncul di hadapannya. Dengan kekuatan barunya, ia memulai perjalanan menjadi hunter terkuat di dunia.',
    cover_url: '/covers/solo-leveling.jpg',
    genre: ['Action', 'Adventure', 'Fantasy'],
    status: 'Completed',
    author: 'Chugong',
    artist: 'Dubu (Redice Studio)',
    format: 'Manhwa',
    rating: 9.2,
    view_count: 2500000,
    bookmark_count: 150000,
  },
  {
    slug: 'the-beginning-after-the-end',
    title: 'The Beginning After the End',
    alternative_title: 'TBATE',
    synopsis: 'Raja Arthur Leywin yang pernah memiliki kekuatan, kekayaan, dan prestise yang tak tertandingi di dunia bernama Dicathen. Terlahir kembali di dunia baru yang dipenuhi sihir dan monster, ia mendapat kesempatan kedua untuk memperbaiki segalanya.',
    cover_url: '/covers/the-beginning-after-the-end.jpg',
    genre: ['Action', 'Adventure', 'Fantasy', 'Romance'],
    status: 'Ongoing',
    author: 'TurtleMe',
    artist: 'Fuyuki23',
    format: 'Manhwa',
    rating: 9.0,
    view_count: 1800000,
    bookmark_count: 120000,
  },
  {
    slug: 'omniscient-reader',
    title: "Omniscient Reader's Viewpoint",
    alternative_title: '전지적 독자 시점',
    synopsis: 'Kim Dokja adalah satu-satunya pembaca yang menyelesaikan novel web terpanjang di dunia, "Three Ways to Survive the Apocalypse." Suatu hari, dunia nyata berubah mengikuti alur novel tersebut. Dengan pengetahuan yang ia miliki tentang masa depan, Kim Dokja harus bertahan hidup dan mengubah takdir.',
    cover_url: '/covers/omniscient-reader.jpg',
    genre: ['Action', 'Adventure', 'Fantasy', 'Drama'],
    status: 'Ongoing',
    author: 'Sing Shong',
    artist: 'Sleepy-C',
    format: 'Manhwa',
    rating: 9.1,
    view_count: 2200000,
    bookmark_count: 130000,
  },
  {
    slug: 'tower-of-god',
    title: 'Tower of God',
    alternative_title: '신의 탑',
    synopsis: 'Apa yang kamu inginkan? Uang dan kekayaan? Otoritas dan kekuasaan? Balas dendam? Apa pun yang kamu inginkan, ada di puncak menara. Bam, seorang anak laki-laki yang menghabiskan seluruh hidupnya terkurung di bawah menara misterius, memasuki menara untuk mengejar sahabatnya Rachel.',
    cover_url: '/covers/tower-of-god.jpg',
    genre: ['Action', 'Adventure', 'Mystery', 'Fantasy'],
    status: 'Ongoing',
    author: 'SIU',
    artist: 'SIU',
    format: 'Manhwa',
    rating: 8.8,
    view_count: 3000000,
    bookmark_count: 200000,
  },
  {
    slug: 'jujutsu-kaisen',
    title: 'Jujutsu Kaisen',
    alternative_title: '呪術廻戦',
    synopsis: 'Yuji Itadori adalah siswa SMA yang luar biasa atletis. Suatu hari, untuk menyelamatkan teman-temannya dari kutukan, ia menelan jari Ryomen Sukuna, raja kutukan terkuat. Kini ia menjadi wadah bagi Sukuna dan bergabung dengan Jujutsu High.',
    cover_url: '/covers/jujutsu-kaisen.jpg',
    genre: ['Action', 'Supernatural', 'Drama'],
    status: 'Completed',
    author: 'Gege Akutami',
    artist: 'Gege Akutami',
    format: 'Manga',
    rating: 8.7,
    view_count: 4000000,
    bookmark_count: 250000,
  },
  {
    slug: 'return-of-the-mount-hua-sect',
    title: 'Return of the Mount Hua Sect',
    alternative_title: '화산귀환',
    synopsis: 'Chung Myung, pedang terkuat dari sekte Gunung Hua, berhasil membunuh pemimpin iblis tetapi mati dalam prosesnya. 100 tahun kemudian, ia terlahir kembali dan menemukan sekte Gunung Hua dalam kondisi menyedihkan. Ia bertekad memulihkan kejayaan sekte yang pernah ia cintai.',
    cover_url: '/covers/return-of-the-mount-hua-sect.jpg',
    genre: ['Action', 'Martial Arts', 'Comedy', 'Fantasy'],
    status: 'Ongoing',
    author: 'Bee-yeon',
    artist: 'LICO',
    format: 'Manhwa',
    rating: 9.0,
    view_count: 1500000,
    bookmark_count: 90000,
  },
  {
    slug: 'nano-machine',
    title: 'Nano Machine',
    alternative_title: '나노 마신',
    synopsis: 'Cheon Yeo-Woon, seorang yatim piatu dari Demonic Cult, menerima nanomachine dari cucunya yang datang dari masa depan. Dengan bantuan teknologi nano yang ada di tubuhnya, ia memulai perjalanan untuk menjadi Lord terkuat.',
    cover_url: '/covers/nano-machine.jpg',
    genre: ['Action', 'Martial Arts', 'Sci-Fi', 'Fantasy'],
    status: 'Ongoing',
    author: 'Han-Joong-Wol-Ya',
    artist: 'Geum Gang Bul Gae',
    format: 'Manhwa',
    rating: 8.5,
    view_count: 1200000,
    bookmark_count: 75000,
  },
  {
    slug: 'one-piece',
    title: 'One Piece',
    alternative_title: 'ワンピース',
    synopsis: 'Gol D. Roger dikenal sebagai "Raja Bajak Laut," manusia terkuat dan paling terkenal yang pernah berlayar di Grand Line. Kata-kata terakhirnya sebelum kematiannya mengungkapkan keberadaan harta karun terbesar di dunia, One Piece.',
    cover_url: '/covers/one-piece.jpg',
    genre: ['Action', 'Adventure', 'Comedy', 'Fantasy'],
    status: 'Ongoing',
    author: 'Eiichiro Oda',
    artist: 'Eiichiro Oda',
    format: 'Manga',
    rating: 9.5,
    view_count: 5000000,
    bookmark_count: 350000,
  },
  {
    slug: 'eleceed',
    title: 'Eleceed',
    alternative_title: '일렉시드',
    synopsis: 'Jiwoo adalah murid SMA yang baik hati dan suka menolong kucing jalanan. Ia memiliki kecepatan supernatural. Suatu hari ia menemukan kucing gemuk bernama Kayden — yang sebenarnya adalah salah satu awakener terkuat di dunia.',
    cover_url: '/covers/eleceed.jpg',
    genre: ['Action', 'Comedy', 'Supernatural', 'Slice of Life'],
    status: 'Ongoing',
    author: 'Son Jae-ho',
    artist: 'ZHENA',
    format: 'Manhwa',
    rating: 8.9,
    view_count: 1600000,
    bookmark_count: 95000,
  },
  {
    slug: 'chainsaw-man',
    title: 'Chainsaw Man',
    alternative_title: 'チェンソーマン',
    synopsis: 'Denji adalah remaja miskin yang bekerja sebagai devil hunter. Ketika ia dikhianati dan dibunuh, Pochita mengorbankan dirinya untuk menyelamatkan Denji dengan menjadi jantungnya, memberikannya kekuatan untuk berubah menjadi Chainsaw Man.',
    cover_url: '/covers/chainsaw-man.jpg',
    genre: ['Action', 'Supernatural', 'Horror', 'Drama'],
    status: 'Ongoing',
    author: 'Tatsuki Fujimoto',
    artist: 'Tatsuki Fujimoto',
    format: 'Manga',
    rating: 8.6,
    view_count: 3200000,
    bookmark_count: 220000,
  },
];

async function seed() {
  const client = await pool.connect();

  try {
    console.log('🌱 Starting seed with local covers & comic stories...\n');

    await initDB();

    // Ensure pages are generated
    await generateAllComicPages();

    // Clear existing data
    await client.query('DELETE FROM pages');
    await client.query('DELETE FROM chapters');
    await client.query('DELETE FROM bookmarks');
    await client.query('DELETE FROM comics');
    console.log('🗑️  Cleared existing data\n');

    for (const comic of COMICS) {
      const updatedAt = new Date(Date.now() - Math.floor(Math.random() * 72) * 3600000).toISOString();
      const genreJson = JSON.stringify(comic.genre);

      const comicResult = await client.query(
        `INSERT INTO comics (title, alternative_title, synopsis, cover_url, genre, status, author, artist, format, rating, view_count, bookmark_count, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         RETURNING id`,
        [
          comic.title,
          comic.alternative_title,
          comic.synopsis,
          comic.cover_url,
          genreJson,
          comic.status,
          comic.author,
          comic.artist,
          comic.format,
          comic.rating,
          comic.view_count,
          comic.bookmark_count,
          updatedAt,
        ]
      );

      const comicId = comicResult.rows[0].id;
      const chapterCount = 5;

      console.log(`  📚 ${comic.title} — ${chapterCount} chapters`);

      const storyData = COMIC_STORIES[comic.slug];
      const ch1PageCount = storyData && storyData.chapters[0] ? storyData.chapters[0].pages.length : 5;

      for (let ch = 1; ch <= chapterCount; ch++) {
        const daysAgo = (chapterCount - ch) * 7 + Math.floor(Math.random() * 3);
        const releasedAt = new Date(Date.now() - daysAgo * 86400000).toISOString();
        const chapterTitle = ch === 1
          ? (storyData && storyData.chapters[0] ? storyData.chapters[0].title : 'Awal Mula')
          : `Chapter ${ch}`;

        const chapterResult = await client.query(
          `INSERT INTO chapters (comic_id, chapter_number, title, released_at)
           VALUES (?, ?, ?, ?)
           RETURNING id`,
          [comicId, ch, chapterTitle, releasedAt]
        );

        const chapterId = chapterResult.rows[0].id;

        // For Chapter 1: use the authentic story pages
        // For other chapters: use the story pages as well so reader always has story content
        const pageCount = ch1PageCount;
        for (let pg = 1; pg <= pageCount; pg++) {
          const pageUrl = `/pages/${comic.slug}/ch1/pg${pg}.jpg`;
          await client.query(
            `INSERT INTO pages (chapter_id, page_number, image_url)
             VALUES (?, ?, ?)`,
            [chapterId, pg, pageUrl]
          );
        }
      }
    }

    console.log(`\n🎉 Seed complete! ${COMICS.length} comics inserted with local covers and story pages.`);
  } catch (err) {
    console.error('❌ Seed error:', err);
  } finally {
    client.release();
    process.exit(0);
  }
}

seed();
