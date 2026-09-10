const { createCanvas, GlobalFonts } = require('@napi-rs/canvas');
const fs = require('fs');
const path = require('path');

// Register Windows fonts to guarantee sharp typography without CAD symbol fallbacks
function setupFonts() {
  const fontDefs = [
    { file: 'C:/Windows/Fonts/segoeuib.ttf', name: 'ComicTitle' },
    { file: 'C:/Windows/Fonts/segoeui.ttf', name: 'ComicBody' },
    { file: 'C:/Windows/Fonts/segoeuii.ttf', name: 'ComicItalic' },
    { file: 'C:/Windows/Fonts/impact.ttf', name: 'ComicSFX' },
    { file: 'C:/Windows/Fonts/arialbd.ttf', name: 'ComicBold' },
    { file: 'C:/Windows/Fonts/arial.ttf', name: 'ComicRegular' },
  ];
  for (const f of fontDefs) {
    if (fs.existsSync(f.file)) {
      try {
        GlobalFonts.registerFromPath(f.file, f.name);
      } catch (_) {}
    }
  }
}
setupFonts();

/**
 * Story Page Generator for ComicStream
 * Generates high-quality manga/manhwa chapter story pages with real dialog,
 * narrative panels, sound effects (SFX), and dark-themed webtoon styling in Indonesian.
 */

const COMIC_STORIES = {
  'solo-leveling': {
    title: 'SOLO LEVELING',
    themeColor: '#38bdf8',
    secondaryColor: '#6366f1',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Awal Mula Sang Terlemah',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'GATE DAN SANG HUNTER RANK-E',
            narrations: [
              'Sepuluh tahun yang lalu, sebuah gerbang (Gate) dimensi misterius terbuka, menghubungkan dunia manusia dengan dungeon penuh monster berbahaya.',
              'Manusia terpilih yang membangkitkan kekuatan gaib untuk melawan monster ini disebut: HUNTER.'
            ],
            dialogues: [
              { speaker: 'Hunter Lain', text: 'Lihat itu, Sung Jin-Woo sudah datang... Sang "Senjata Terlemah Umat Manusia".' },
              { speaker: 'Sung Jin-Woo', text: '(Bahkan di dungeon rank-E sekalipun, aku hampir mati setiap saat... tapi aku harus membiayai rumah sakit ibuku.)' }
            ],
            sfx: '⚡ BZZZZTT!! ⚡',
            footer: 'Geser ke bawah untuk melanjutkan...'
          },
          {
            pageNumber: 2,
            sceneTitle: 'KUIL GANDA (DOUBLE DUNGEON)',
            narrations: [
              'Raid dungeon rank-D tampak berjalan normal, sampai regu menemukan pintu masuk tersembunyi yang belum pernah terdata.',
              'Pintu gerbang raksasa dengan ukiran simbol dewa kuno yang menakutkan.'
            ],
            dialogues: [
              { speaker: 'Ketua Tim Song', text: 'Ada ruangan tersembunyi! Jumlah kita genap, mari kita voting apakah masuk atau mundur!' },
              { speaker: 'Sung Jin-Woo', text: 'Aku butuh uang untuk biaya sekolah adikku Jin-Ah... Aku memilih masuk!' }
            ],
            sfx: '🚪 KRREEEKKKK...!! 🚪',
            footer: 'Pintu gerbang tertutup rapat di belakang mereka!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'TATAPAN SANG PATUNG DEWA',
            narrations: [
              'Di dalam aula kuil kuno berdiri lingkaran patung raksasa. Di ujung aula, duduk patung dewa dengan senyuman mengerikan.',
              'Tiba-tiba, pintu keluar tertutup dengan sendirinya dan mata patung batu itu mulai menyala merah menyala!'
            ],
            dialogues: [
              { speaker: 'Hunter Pembawa Pedang', text: 'Sialan! Pintu tidak bisa dibuka! Kita terkunci di sini!' },
              { speaker: 'Sung Jin-Woo', text: 'JANGAN BERGERAK! Patung dewa itu... matanya sedang mengawasi kita!' }
            ],
            sfx: '💥 ZZZZROOOOOMMM!! 💥',
            footer: 'Sinar laser mematikan ditembakkan dari mata patung!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'TIGA PERATURAN KUIL KUNstorage',
            narrations: [
              'Korban mulai berjatuhan. Api biru menyala di atas mezbah suci. Jin-Woo menggunakan kecerdasannya untuk memecahkan teka-teki prasasti kuno.'
            ],
            dialogues: [
              { speaker: 'Sung Jin-Woo', text: 'Pertama: Sembahlah Dewa! Kedua: Pujilah Dewa! Ketiga: Buktikan Imanmu!' },
              { speaker: 'Hunter Lain', text: 'Jin-Woo, kau benar! Patung dewa berhenti menyerang saat kita bersujud!' }
            ],
            sfx: '🔥 SWUUUUUUSHHH! 🔥',
            footer: 'Ujian terakhir pengorbanan mezbah telah dimulai!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'PENGORBANAN SUNG JIN-WOO',
            narrations: [
              'Pintu keluar akhirnya terbuka perlahan saat mezbah menyala, namun satu orang harus tetap tinggal agar yang lain bisa lolos.',
              'Dengan kaki yang terpotong parah, Sung Jin-Woo memilih tinggal sendirian mengulur waktu.'
            ],
            dialogues: [
              { speaker: 'Sung Jin-Woo', text: 'Kalian pergilah cepat! Biar aku yang menahan mezbah ini!' },
              { speaker: 'Hunter Joohee', text: 'Jin-Woo! Jangan! Kau akan mati di sana!' },
              { speaker: 'Sung Jin-Woo', text: '(Jika aku diberi satu kesempatan lagi... aku tidak ingin mati selemah ini...)' }
            ],
            sfx: '⚔️ CRAAASSHHH!! ⚔️',
            footer: 'Patung monster menusuk tubuh Jin-Woo dengan pedang raksasa!'
          },
          {
            pageNumber: 6,
            sceneTitle: 'KEBANGKITAN SANG PLAYER',
            isSpecialQuest: true,
            questTitle: '[ QUEST RAHASIA: KEBERANIAN YANG LEMAH ]',
            questDesc: 'Selamat! Anda telah memenuhi semua syarat kualifikasi untuk menjadi Player dalam System.',
            dialogues: [
              { speaker: 'System Hologram', text: '[Jantung Anda akan berhenti dalam 0.02 detik. Apakah Anda menerima kontrak menjadi Player?]' },
              { speaker: 'Sung Jin-Woo', text: 'A-apa ini?! Jendela sistem mengambang di udara?!' },
              { speaker: 'Sung Jin-Woo', text: 'AKU MENERIMANYA!!' }
            ],
            sfx: '✨ DENGG!! LEVEL UP! ✨',
            footer: 'Bersambung ke Chapter 2 — Kebangkitan Sang Bayangan!'
          }
        ]
      }
    ]
  },
  'the-beginning-after-the-end': {
    title: 'THE BEGINNING AFTER THE END',
    themeColor: '#a855f7',
    secondaryColor: '#ec4899',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Reinkarnasi Sang Raja',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'KEHIDUPAN SANG RAJA GREY',
            narrations: [
              'Di duniaku sebelumnya, aku adalah Raja Grey. Memiliki kekuatan militer, kekayaan, dan takhta tertinggi.',
              'Namun di puncak kekuasaan, aku hidup dalam kesendirian tanpa keluarga, cinta, atau kawan sejati.'
            ],
            dialogues: [
              { speaker: 'Raja Grey', text: '(Kekuasaan ini terasa sangat hampa... Kematianku dalam tidur adalah akhir yang pantas.)' }
            ],
            sfx: '🕯️ ...SENYAP... 🕯️',
            footer: 'Namun kematian bukanlah akhir dari segalanya...'
          },
          {
            pageNumber: 2,
            sceneTitle: 'LAHIR KEMBALI DI DICATHEN',
            narrations: [
              'Kesadaranku perlahan kembali. Cahaya menyilaukan dan suara tangisan bayi terdengar.',
              'Aku terlahir kembali sebagai seorang bayi bernama Arthur Leywin di dunia baru bernama Dicathen!'
            ],
            dialogues: [
              { speaker: 'Alice Leywin', text: 'Reynolds, lihat dia... anak kita sangat tampan. Kita beri nama Arthur.' },
              { speaker: 'Reynolds Leywin', text: 'Arthur Leywin! Kelak kau akan jadi kesatria yang lebih hebat dari ayahmu!' }
            ],
            sfx: '👶 *UWAANGG!!* 👶',
            footer: 'Dunia yang dipenuhi energi magis bernama MANA!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'MENEMUKAN TEORI MANA CORE',
            narrations: [
              'Ketika berusia 3 tahun, aku sering mengamati ayahku berlatih sihir api Augmenter.',
              'Aku menyadari prinsip energi mana di dunia ini mirip dengan energi Ki di kehidupanku yang dulu!'
            ],
            dialogues: [
              { speaker: 'Arthur Leywin', text: '(Orang di dunia ini butuh waktu belasan tahun sampai masa puber untuk membentuk Mana Core...)' },
              { speaker: 'Arthur Leywin', text: '(Tapi dengan kontrol Ki lamaku, aku bisa memampatkan partikel mana di tubuhku sekarang juga!)' }
            ],
            sfx: '🌀 SHUUUUSSHHH!! 🌀',
            footer: 'Arthur memulai meditasi pembentukan Mana Core pertamanya!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'BADAI MANA DI KAMAR BAYI',
            narrations: [
              'Partikel mana di sekeliling rumah mulai tertarik deras ke tubuh mungil Arthur.',
              'Pusaran angin mana bercahaya warna-warni berputar kencang, mengguncang seluruh pondok keluarga Leywin!'
            ],
            dialogues: [
              { speaker: 'Reynolds Leywin', text: 'Alice! Gempa apa ini?! Kenapa konsentrasi mana di kamar Art begitu padat?!' },
              { speaker: 'Alice Leywin', text: 'Arthur di dalam! Reynolds, cepat selamatkan Arthur!' }
            ],
            sfx: '💥 BLAASSTTT!! 💥',
            footer: 'Dinding kamar meledak akibat pelepasan energi mana yang masif!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'MANA CORE TERAWAL DALAM SEJARAH',
            narrations: [
              'Debu ledakan mereda. Di tengah reruntuhan, Arthur duduk bersila dengan tubuh diselimuti aura pelindung emas.',
              'Di dadanya, inti mana tingkat hitam telah terbentuk sempurna pada usia 3 tahun!'
            ],
            dialogues: [
              { speaker: 'Reynolds Leywin', text: 'I-ini mustahil... Anak 3 tahun berhasil membangkitkan Mana Core?!' },
              { speaker: 'Arthur Leywin', text: '(Kehidupan kedua ini... kali ini aku akan hidup demi melindungi orang-orang yang kucintai!)' }
            ],
            sfx: '✨ KILAUAN EMAS ✨',
            footer: 'Bersambung ke Chapter 2 — Petualangan Dimulai!'
          }
        ]
      }
    ]
  },
  'omniscient-reader': {
    title: "OMNISCIENT READER'S VIEWPOINT",
    themeColor: '#10b981',
    secondaryColor: '#06b6d4',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Layanan Berbayar Dimulai',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'SATU-SATUNYA PEMBACA SETIA',
            narrations: [
              'Namaku Kim Dokja. "Dokja" bisa berarti anak tunggal, atau pembaca.',
              'Selama lebih dari 10 tahun, aku adalah satu-satunya orang di dunia yang setia membaca web novel sepanjang 3.149 bab: "Tiga Cara Bertahan Hidup di Dunia yang Hancur".'
            ],
            dialogues: [
              { speaker: 'Kim Dokja', text: 'Akhirnya bab epilog selesai... Novel yang menemaniku sejak masa sekolah kini tamat.' },
              { speaker: 'Pesan Penulis tls123', text: '[Terima kasih Dokja. Sebagai hadiah, layanan berbayar akan segera dimulai pada pukul 19:00.]' }
            ],
            sfx: '📱 *TING!* 📱',
            footer: 'Jam menunjukkan pukul 18:59 di kereta bawah tanah Seoul jalur 3...'
          },
          {
            pageNumber: 2,
            sceneTitle: 'KERETA BAWAH TANAH BERHENTI',
            narrations: [
              'Tepat pukul 19:00, kereta bawah tanah berguncang keras dan mengerem mendadak dengan percikan api tajam.',
              'Lampu di dalam gerbong padam total. Kegelapan dan kepanikan mulai melanda para penumpang.'
            ],
            dialogues: [
              { speaker: 'Yoo Sangah', text: 'Dokja-ssi! Keretanya tiba-tiba mati! Apa ada kecelakaan?' },
              { speaker: 'Kim Dokja', text: '(Tidak... perasaan ini... jam 19:00... persis seperti bab 1 dari novel itu!)' }
            ],
            sfx: '⚡ CKKRRRIIEEETTT!! ⚡',
            footer: 'Sesosok makhluk bertanduk muncul melayang di tengah gerbong!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'KEMUNCULAN SANG DOKKAEBI',
            narrations: [
              'Makhluk mungil berbulu putih dengan dua tanduk kecil dan mata bersinar keemasan melayang sambil menyeringai.',
              'Dokkaebi Bihyung telah tiba di dunia nyata!'
            ],
            dialogues: [
              { speaker: 'Dokkaebi Bihyung', text: 'Halo cacing-cacing tanah! Masa damai gratisan kalian telah resmi berakhir hari ini!' },
              { speaker: 'Penumpang Marah', text: 'Apa-apaan kau boneka aneh?! Jangan main-main dengan kami!' }
            ],
            sfx: '💥 BAAAMMMM!! 💥',
            footer: 'Dokkaebi menjentikkan jari dan meledakkan kepala penumpang yang membantah!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'SKENARIO UTAMA PERTAMA',
            isSpecialQuest: true,
            questTitle: '[ SKENARIO UTAMA #1: BUKTIKAN NILAI ANDA ]',
            questDesc: 'Bunuh satu atau lebih makhluk hidup dalam batas waktu 30 menit. Kegagalan: KEMATIAN.',
            dialogues: [
              { speaker: 'System Announcement', text: '[Skenario Utama #1 telah dimulai di Gerbong 3807.]' },
              { speaker: 'Kim Dokja', text: '(Aturan nomor satu novel: "Membunuh makhluk hidup", tidak harus manusia!)' },
              { speaker: 'Preman Gerbong', text: 'Hanya ada satu cara bertahan... kita harus membunuh orang terlemah di sini!' }
            ],
            sfx: '⏳ 30:00 BERHITUNG MUNDUR ⏳',
            footer: 'Kepanikan berubah menjadi pertumpahan darah antar penumpang!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'STRATEGI SANG PEMBACA CERDAS',
            narrations: [
              'Sementara preman mengincar orang tua dan anak-anak, Kim Dokja mengamati anak kecil bernama Gilyoung yang membawa toples serangga.',
              'Kim Dokja merebut toples belalang milik Gilyoung dan menghancurkannya di lantai!'
            ],
            dialogues: [
              { speaker: 'Kim Dokja', text: 'Belalang juga makhluk hidup! Gilyoung, injak belalang ini cepat!' },
              { speaker: 'System Announcement', text: '[Anda telah membunuh seekor belalang. Anda telah menyelesaikan Skenario Utama #1!]' },
              { speaker: 'Kim Dokja', text: '(Dunia ini sekarang adalah duniaku... dan aku tahu bagaimana caraku bertahan sampai akhir!)' }
            ],
            sfx: '🎉 SKENARIO SELESAI! 🎉',
            footer: 'Bersambung ke Chapter 2 — Sang Protagonis Yoo Joonghyuk Tiba!'
          }
        ]
      }
    ]
  },
  'tower-of-god': {
    title: 'TOWER OF GOD',
    themeColor: '#eab308',
    secondaryColor: '#f97316',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Pintu Masuk Menara',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'RACHEL DAN SANG ANAK KEGELAPAN',
            narrations: [
              'Apa yang kau inginkan? Uang, kehormatan, kekuatan, atau balas dendam? Apa pun yang kau cari, ada di puncak Menara.',
              'Bam, bocah yang hidup di bawah gua kegelapan tanpa ingatan masa lalu, hanya memiliki Rachel sebagai dunianya.'
            ],
            dialogues: [
              { speaker: 'Bam', text: 'Rachel! Tolong jangan pergi! Tetaplah di sini bersamaku!' },
              { speaker: 'Rachel', text: 'Maafkan aku Bam... Aku lelah hidup dalam kegelapan ini. Aku ingin melihat langit biru dan bintang-bintang di puncak Menara!' }
            ],
            sfx: '✨ CAHAYA GERBANG MEMBUKA ✨',
            footer: 'Rachel terhisap ke dalam gerbang misterius Menara!'
          },
          {
            pageNumber: 2,
            sceneTitle: 'SANG IRREGULAR YANG MEMBUKA PINTU',
            narrations: [
              'Bam menolak ditinggalkan. Dengan tekad membara mengejar Rachel, Bam memukul dinding pembatas.',
              'Secara mengejutkan, pintu Menara yang biasanya memilih tuannya, terbuka paksa oleh kehendak Bam sendiri!'
            ],
            dialogues: [
              { speaker: 'Bam', text: 'RACHELLL!! Aku akan menyusulmu kemanapun kau pergi!' },
              { speaker: 'Headon', text: 'Hohoho... sudah sangat lama sejak seorang "Irregular" membuka pintu ini dengan kekuatannya sendiri.' }
            ],
            sfx: '💥 DUUUMMMM!! 💥',
            footer: 'Bam tiba di Lantai Pertama Menara — Wilayah Pengawas Headon!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'UJIAN SANG BELUT BAJA PUTIH',
            narrations: [
              'Headon, penjaga lantai berbentuk kelinci berwajah licik, mengarahkan Bam ke kandang raksasa berisi Belut Baja Putih yang buas.',
              'Ujiannya: Menembus sangkar monster dan memecahkan Bola Hitam raksasa!'
            ],
            dialogues: [
              { speaker: 'Headon', text: 'Jika kau ingin naik ke lantai berikutnya, masuklah ke sangkar itu dan pecahkan bolanya.' },
              { speaker: 'Bam', text: 'Jika itu satu-satunya cara bertemu Rachel... aku akan melakukannya!' }
            ],
            sfx: '🐍 ROOOAAARRRR!! 🐍',
            footer: 'Monster belut raksasa mengibaskan ekornya menghancurkan lantai batu!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'KEDATANGAN PUTRI YURI JAHAD',
            narrations: [
              'Tiba-tiba, langit lantai satu retak! Seorang wanita cantik berbusana merah hitam melompat turun dengan kekuatan dahsyat!',
              'Putri Raja Menara: Yuri Jahad dan pengawalnya Evan!'
            ],
            dialogues: [
              { speaker: 'Yuri Jahad', text: 'Headon pembohong licik! Ujian macam apa ini untuk anak kecil tanpa senjata?!' },
              { speaker: 'Yuri Jahad', text: 'Hei bocah lucu! Wajahmu tampan sekali, aku menyukaimu! Ambil pedang legendarisku ini: BLACK MARCH!' }
            ],
            sfx: '🗡️ CRIIINNNGGG!! 🗡️',
            footer: 'Senjata legendaris Black March berpindah ke tangan Bam!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'TEBASAN KEBERANIAN BAM',
            narrations: [
              'Dengan pedang Black March di tangan, Bam melompat lurus ke dalam mulut Belut Baja Putih!',
              'Alih-alih takut ditelan, Bam menusuk langit-langit mulut monster dari dalam dan melesat memecahkan Bola Hitam!'
            ],
            dialogues: [
              { speaker: 'Evan', text: 'Anak itu... dia benar-benar melompat ke mulut monster tanpa ragu sedikitpun?!' },
              { speaker: 'Bam', text: 'PECAHLAH!!' },
              { speaker: 'Headon', text: 'Kukuku... Menara ini akan segera menyambut badai baru...' }
            ],
            sfx: '💥 PRRAAAANNGGG!! 💥',
            footer: 'Bersambung ke Chapter 2 — Lantai Pengujian Kehidupan!'
          }
        ]
      }
    ]
  },
  'jujutsu-kaisen': {
    title: 'JUJUTSU KAISEN',
    themeColor: '#ef4444',
    secondaryColor: '#dc2626',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Ryomen Sukuna',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'PESAN TERAKHIR SANG KAKEK',
            narrations: [
              'Yuji Itadori adalah remaja SMA biasa dengan bakat atletik yang melampaui rekor atlet dunia.',
              'Malam itu di rumah sakit, kakeknya memberikan nasihat terakhir sebelum menghembuskan napas terakhirnya.'
            ],
            dialogues: [
              { speaker: 'Kakek Itadori', text: 'Yuji... kau anak yang kuat. Gunakan kekuatanmu untuk menolong orang lain.' },
              { speaker: 'Kakek Itadori', text: 'Jangan sampai kau mati sendirian seperti aku... matilah dikelilingi banyak orang.' }
            ],
            sfx: '🏥 *BEEP... BEEP...* 🏥',
            footer: 'Pesan kakek yang mengubah takdir hidup Yuji selamanya...'
          },
          {
            pageNumber: 2,
            sceneTitle: 'SEGEL KUTUKAN TERLEPAS',
            narrations: [
              'Di SMA Sugisawa, teman-teman klub ilmu gaib Yuji membuka kotak jimat kutukan tingkat khusus yang mereka temukan di lapangan.',
              'Jimat itu adalah salah satu jari kering terkutuk milik Raja Kutukan kuno!'
            ],
            dialogues: [
              { speaker: 'Megumi Fushiguro', text: 'Gawat! Segelnya sudah dilepas! Roh kutukan di seluruh kota berkumpul ke sekolah ini!' },
              { speaker: 'Yuji Itadori', text: 'Teman-temanku ada di lantai atas! Aku harus menolong mereka!' }
            ],
            sfx: '👻 GRRRHHH... KU-TU-KAN... 👻',
            footer: 'Monster kutukan berlendir melilit tubuh teman-teman Yuji!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'MENEROBOS DINDING KACA',
            narrations: [
              'Dari luar gedung lantai 4, Yuji melompat tanpa bantuan alat dan mendobrak kaca jendela dengan tinjuan keras!',
              'Megumi mengeluarkan teknik bayangannya untuk membantu Yuji.'
            ],
            dialogues: [
              { speaker: 'Yuji Itadori', text: 'LEPASKAN TEMAN-TEMANKU, MONSTER JELEK!!' },
              { speaker: 'Megumi Fushiguro', text: 'Gokuken, serang kutukan itu!' }
            ],
            sfx: '💥 BBRRRAAAKKKK!! 💥',
            footer: 'Kutukan tingkat tinggi menyerang balik dan melukai Megumi parah!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'KEPUTUSAN NEKAT SANG WADAH',
            narrations: [
              'Megumi terkapar bersimbah darah. Roh kutukan raksasa mencengkeram Yuji dan jari Sukuna terlempar ke udara.',
              'Untuk mendapatkan energi kutukan dan menyelamatkan semua orang, Yuji menangkap jari beracun itu dengan mulutnya!'
            ],
            dialogues: [
              { speaker: 'Megumi Fushiguro', text: 'JANGAN DITELAN, BODOH!! ITU RACUN MEMATIKAN YANG BISA MEMBUNUHMU!!' },
              { speaker: 'Yuji Itadori', text: '*GULPP!!*' }
            ],
            sfx: '⚡ KILAT MERAH HITAM MELEDAK ⚡',
            footer: 'Tato hitam terkutuk mulai merambat di sekujur tubuh Yuji!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'BANGKITNYA SANG RAJA KUTUKAN',
            narrations: [
              'Kutukan raksasa meledak hancur berkeping-keping hanya dengan satu kibasan tangan!',
              'Raja Kutukan Terkuat sepanjang sejarah, Ryomen Sukuna, telah terbangun dari tidurnya selama seribu tahun!'
            ],
            dialogues: [
              { speaker: 'Ryomen Sukuna', text: 'HA HA HA!! Cahaya rembulan begitu indah di tubuh baru ini!' },
              { speaker: 'Ryomen Sukuna', text: 'Di mana para wanita dan anak-anak?! Ini akan jadi pesta pembantaian yang luar biasa!' },
              { speaker: 'Yuji Itadori', text: 'Hei... tubuh siapa yang kau panggil milikmu, brengsek?! Kembalikan tubuhku!' }
            ],
            sfx: '🩸 RYOMEN SUKUNA 🩸',
            footer: 'Bersambung ke Chapter 2 — Pertemuan dengan Satoru Gojo!'
          }
        ]
      }
    ]
  },
  'return-of-the-mount-hua-sect': {
    title: 'RETURN OF THE MOUNT HUA SECT',
    themeColor: '#f43f5e',
    secondaryColor: '#fb7185',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Pedang Bunga Plum Terlahir Kembali',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'PERANG BESAR 100 TAHUN LALU',
            narrations: [
              'Di puncak Gunung 100 tahun yang lalu, Chung Myung sang Pedang Suci Bunga Plum berhasil memenggal kepala Pemimpin Iblis Cheon Ma.',
              'Namun seluruh rekannya telah gugur, dan napasnya pun terhenti di atas salju berlumur darah.'
            ],
            dialogues: [
              { speaker: 'Chung Myung', text: 'Mount Hua... Sekte tercintaku... kita telah menang...' }
            ],
            sfx: '⚔️ TEBASAN TERAKHIR ⚔️',
            footer: 'Dan Sang Legenda pun menutup mata selamanya...'
          },
          {
            pageNumber: 2,
            sceneTitle: 'BANGKIT SEBAGAI PENGEMIS CILIK',
            narrations: [
              'Seratus tahun berlalu. Chung Myung membuka mata dan mendapati dirinya berada dalam tubuh seorang anak pengemis kurus kering.',
              'Ingatan dan teknik pedang legendarisnya masih tersimpan utuh di dalam kepalanya!'
            ],
            dialogues: [
              { speaker: 'Chung Myung', text: 'Hah?! Tubuhku mengecil?! Berapa lama aku tidur?!' },
              { speaker: 'Pedagang Pasar', text: 'Anak pengemis, pergilah! Sekarang sudah seratus tahun sejak Perang Iblis usai!' }
            ],
            sfx: '👀 *MELOTOT KAGET* 👀',
            footer: 'Chung Myung bergegas berlari mendaki Gunung Hua!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'KONDISI SEKTENYA YANG MENYEDIHKAN',
            narrations: [
              'Dengan bangga Chung Myung mendaki gerbang Mount Hua... namun pemandangan di depannya membuatnya syok berat.',
              'Genteng aula utama runtuh, murid-murid sekte berpakaian compang-camping, dan lambang bunga plum tertutup debu tebal!'
            ],
            dialogues: [
              { speaker: 'Chung Myung', text: 'A-APA-APAAN INI?! Mana aula megah kita?! Mana harta karun sekte kita?!' },
              { speaker: 'Penagih Hutang', text: 'Hei Sekte Mount Hua bangkrut! Bayar hutang kalian atau kami sita gunung ini!' }
            ],
            sfx: '💥 JLEBBB DI HATI 💥',
            footer: 'Sekte nomor satu di dunia kini terpuruk di dasar lumpur kehancuran!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'TEKAD SANG PEDANG BUNGA PLUM',
            narrations: [
              'Melihat sekte yang ia perjuangkan dengan darah dan nyawa diinjak-injak, api amarah membakar dada Chung Myung.',
              'Dengan senyuman licik khasnya, ia mengambil dahan pohon kering sebagai pengganti pedang!'
            ],
            dialogues: [
              { speaker: 'Chung Myung', text: 'Kalian penagih hutang sialan... berani-beraninya menginjak tanah suci Mount Hua!' },
              { speaker: 'Penagih Hutang', text: 'Bocah pengemis gila! Habisi dia!' }
            ],
            sfx: '🌸 SRRRIIINGGG!! 🌸',
            footer: 'Kelopak bunga plum magis berterbangan dari dahan pohon!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'KEMBALINYA KEJAYAAN GUNUNG HUA',
            narrations: [
              'Hanya dengan sebatang ranting, Chung Myung menghajar puluhan preman penagih hutang hingga babak belur melayang!',
              'Sang Tetua Mount Hua yang menyaksikan dari kejauhan tertegun melihat jurus pedang leluhur yang telah hilang!'
            ],
            dialogues: [
              { speaker: 'Tetua Hyun Young', text: 'I-ilmu pedang itu... Gerakan Dua Puluh Empat Bunga Plum Leluhur?!' },
              { speaker: 'Chung Myung', text: 'Dengarkan kalian para murid pemalas! Mulai hari ini, aku akan melatih kalian seperti neraka sampai Mount Hua kembali jadi nomor satu di dunia!' }
            ],
            sfx: '✨ BUNGA PLUM MEKAR KEMBALI ✨',
            footer: 'Bersambung ke Chapter 2 — Latihan Neraka Dimulai!'
          }
        ]
      }
    ]
  },
  'nano-machine': {
    title: 'NANO MACHINE',
    themeColor: '#06b6d4',
    secondaryColor: '#3b82f6',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Suntikan Mesin Masa Depan',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'PUTRA SELIR YANG TERTINDAS',
            narrations: [
              'Cheon Yeo-Woon adalah anak haram Lord Demonic Cult dari seorang wanita pelayan.',
              'Ia dilarang belajar ilmu bela diri dan setiap hari hidup dalam ancaman racun dari enam klan besar yang berkuasa.'
            ],
            dialogues: [
              { speaker: 'Pembunuh Bayaran', text: 'Anak haram rendahan, kematianmu malam ini akan memastikan takhta jatuh ke klan kami!' },
              { speaker: 'Cheon Yeo-Woon', text: '(Sial... racun di tubuhku membuatku tidak bisa bergerak... Ibu, maafkan aku...)' }
            ],
            sfx: '🩸 CRASHHH!! 🩸',
            footer: 'Yeo-Woon roboh bersimbah darah di hutan bambu terlarang!'
          },
          {
            pageNumber: 2,
            sceneTitle: 'KETURUNAN DARI MASA DEPAN',
            narrations: [
              'Tiba-tiba waktu di sekeliling hutan terhenti membeku. Kilatan listrik biru membuka portal waktu!',
              'Seorang pemuda berbaju zirah futuristik melangkah keluar menatap Yeo-Woon yang sekarat.'
            ],
            dialogues: [
              { speaker: 'Pria Masa Depan', text: 'Tepat waktu. Halo, Kakek Buyut ketujuhku, Cheon Yeo-Woon.' },
              { speaker: 'Pria Masa Depan', text: 'Sejarah mencatat kau mati di sini... tapi keturunanmu di abad ke-30 tidak akan membiarkannya terjadi!' }
            ],
            sfx: '⚡ BZZZT! WARP TIME ⚡',
            footer: 'Pria misterius menancapkan suntikan pistol ke leher Yeo-Woon!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'INJEKSI NANO MACHINE GENERASI KE-7',
            isSpecialQuest: true,
            questTitle: '[ NANO MACHINE v7.4 DIINSTAL ]',
            questDesc: 'Menyuntikkan miliaran nanomachine ke dalam pembuluh darah. Merekonstruksi sel dan dantian rusak.',
            dialogues: [
              { speaker: 'Suara AI Nano', text: '[Detak jantung kritis. Memulai netralisasi racun dan penyembuhan sel.]' },
              { speaker: 'Cheon Yeo-Woon', text: 'A-apa ini?! Suara siapa yang ada di dalam kepalaku?!' },
              { speaker: 'Suara AI Nano', text: '[Saya adalah Nano Machine. Pelayan setia Tuan Cheon Yeo-Woon.]' }
            ],
            sfx: '🧬 REGENERASI SEL INTENSIF 🧬',
            footer: 'Semua luka parah dan racun di tubuh Yeo-Woon sembuh total dalam sekejap!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'ANALISIS BELA DIRI OTOMATIS',
            narrations: [
              'Pembunuh bayaran yang membeku kembali bergerak dan menyerang dengan pedang beracun.',
              'Namun di mata Yeo-Woon, jalur pedang musuh terproyeksi dalam garis lintasan laser merah!'
            ],
            dialogues: [
              { speaker: 'Suara AI Nano', text: '[Lintasan pedang musuh terdeteksi. Rekomendasi: Geser tubuh 15 derajat ke kiri dan hantam ulu hati.]' },
              { speaker: 'Pembunuh Bayaran', text: 'Bocah ini... bagaimana bisa dia menghindari tebasanku secepat itu?!' }
            ],
            sfx: '💥 DUKKKK!! PATAH TULANG 💥',
            footer: 'Yeo-Woon melumpuhkan pembunuh bayaran dengan satu pukulan presisi!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'LANGKAH PERTAMA MENJADI LORD TERKUAT',
            narrations: [
              'Darah musuh mengalir di lantai tanah. Yeo-Woon menatap tangannya yang kini dialiri energi nano canggih.',
              'Masa depan Demonic Cult tidak akan lagi sama!'
            ],
            dialogues: [
              { speaker: 'Cheon Yeo-Woon', text: 'Nano... bisakah kau memindai semua kitab bela diri rahasia di perpustakaan kultus?' },
              { speaker: 'Suara AI Nano', text: '[Tentu saja Tuan. Pemindaian dan peniruan gerakan dapat dilakukan instan.]' },
              { speaker: 'Cheon Yeo-Woon', text: 'Enam klan besar... bersiaplah berlutut di bawah kakiku!' }
            ],
            sfx: '✨ MATA BIRU ELEKTRIK ✨',
            footer: 'Bersambung ke Chapter 2 — Ujian Akademi Demonic Cult!'
          }
        ]
      }
    ]
  },
  'one-piece': {
    title: 'ONE PIECE',
    themeColor: '#f97316',
    secondaryColor: '#eab308',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Romance Dawn — Fajar Petualangan',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'ERA BAJAK LAUT BESAR',
            narrations: [
              'Kekayaan, ketenaran, kekuasaan... Pria yang memperoleh segalanya di dunia ini adalah Sang Raja Bajak Laut, Gol D. Roger.',
              'Kata-kata terakhirnya di tiang eksekusi memicu jutaan orang berlayar ke lautan luas mencari harta karun legendaris: ONE PIECE!'
            ],
            dialogues: [
              { speaker: 'Gol D. Roger', text: '"Harta karunku? Jika kalian menginginkannya, carilah! Aku telah meninggalkan semuanya di tempat itu!"' }
            ],
            sfx: '🌊 OMBAK LAUTAN GRAND LINE 🌊',
            footer: 'Dunia memasuki Era Bajak Laut Terbesar!'
          },
          {
            pageNumber: 2,
            sceneTitle: 'DESA FOOSHA DAN BUAH IBLIS',
            narrations: [
              'Di sebuah pulau kecil Desa Foosha, bocah laki-laki periang bernama Monkey D. Luffy sangat mengagumi kapten bajak laut berambut merah: Shanks.',
              'Tanpa sengaja, Luffy yang kelaparan memakan buah aneh bermotif spiral dari peti harta Shanks!'
            ],
            dialogues: [
              { speaker: 'Luffy', text: 'Shanks! Biarkan aku ikut berlayar di kapal bajak lautmu!' },
              { speaker: 'Shanks', text: 'Hahaha! Kau masih ingusan Luffy, sepuluh tahun lagi baru bicara!' },
              { speaker: 'Shanks', text: 'TUNGGU! LUFFY, APA YANG KAU MAKAN DARI PETI ITU?!' }
            ],
            sfx: '🍎 GOMU GOMU NO MI DIMAKAN! 🍎',
            footer: 'Leher Luffy tiba-tiba ditarik dan memanjang elastis seperti karet!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'SERANGAN BANDIT GUNUNG',
            narrations: [
              'Bandit gunung Higuma datang membuat onar di kedai dan menghina Shanks.',
              'Luffy yang marah membela nama baik Shanks diculik dan dibawa ke tengah laut oleh sang pemimpin bandit.'
            ],
            dialogues: [
              { speaker: 'Luffy', text: 'Minta maaf pada Shanks! Bajak laut bukanlah pengecut!' },
              { speaker: 'Higuma', text: 'Bocah sialan! Kau akan jadi makanan monster laut di sini!' }
            ],
            sfx: '🌊 SPLAASSHHH!! 🌊',
            footer: 'Monster Raja Lautan raksasa muncul dari kedalaman air dan melahap perahu Higuma!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'PENGORBANAN LENGAN SHANKS',
            narrations: [
              'Saat monster laut membuka taring raksasanya hendak memangsa Luffy, Shanks berenang secepat kilat mendekap Luffy erat-erat!',
              'Dengan tatapan tajam berwibawa Haki, Shanks mengusir monster buas tersebut!'
            ],
            dialogues: [
              { speaker: 'Shanks', text: 'PERGI KAU DARI SINI!!' },
              { speaker: 'Luffy', text: 'Shanks... tangan kirimu... tangan kirimu putus demi aku!! Uwaaaa!!' },
              { speaker: 'Shanks', text: 'Hanya satu lengan Luffy... bukan masalah besar, yang penting kau selamat.' }
            ],
            sfx: '🩸 TANGISAN PENUH AIR MATA 🩸',
            footer: 'Momen berharga yang menancapkan impian besar di sanubari Luffy.'
          },
          {
            pageNumber: 5,
            sceneTitle: 'JANJI TOPI JERAMI',
            narrations: [
              'Hari perpisahan tiba. Kapal Bajak Laut Rambut Merah bersiap mengangkat jangkar meninggalkan desa.',
              'Shanks melepaskan topi jerami kesayangannya dan meletakkannya di kepala Luffy.'
            ],
            dialogues: [
              { speaker: 'Luffy', text: 'Shanks! Kelak aku akan mengumpulkan kru yang lebih hebat dari kalian, dan menemukan One Piece!' },
              { speaker: 'Luffy', text: 'AKU AKAN MENJADI RAJA BAJAK LAUT!!' },
              { speaker: 'Shanks', text: 'Bagus... simpan topi jerami ini Luffy. Suatu hari nanti jika kau sudah jadi bajak laut hebat, kembalikan padaku!' }
            ],
            sfx: '👒 JANJI TOPI JERAMI 👒',
            footer: 'Bersambung ke Chapter 2 — Luffy Memulai Pelayaran Soliter!'
          }
        ]
      }
    ]
  },
  'eleceed': {
    title: 'ELECEED',
    themeColor: '#eab308',
    secondaryColor: '#f59e0b',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Kucing Petir Terkuat',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'JIWOO DAN KUCING-KUCING JALANAN',
            narrations: [
              'Seo Jiwoo adalah siswa SMA yang berhati lembut. Setiap hari ia selalu membawa makanan untuk memberi makan kucing jalanan di kotanya.',
              'Jiwoo menyimpan satu rahasia besar: Ia memiliki kekuatan kecepatan super supernatural yang tidak berani ia perlihatkan pada siapa pun.'
            ],
            dialogues: [
              { speaker: 'Jiwoo Seo', text: 'Makan yang banyak ya meong... Jangan sampai kalian kelaparan.' }
            ],
            sfx: '🐱 *MEOW... MEOW...* 🐱',
            footer: 'Kebaikan hati Jiwoo membawanya ke takdir yang tak terduga...'
          },
          {
            pageNumber: 2,
            sceneTitle: 'BURONAN AWAKENER PETIR TERKUAT',
            narrations: [
              'Di gang gelap lain, pertarungan maut antar Awakener kelas dunia baru saja terjadi.',
              'Kayden Break, awakener pengguna petir terkuat yang ditakuti seluruh organisasi dunia, terluka parah dan terpaksa mengubah wujudnya untuk menyamarkan diri.'
            ],
            dialogues: [
              { speaker: 'Kayden Break', text: '(Sialan para bajingan itu... Tubuhku mencapai batas. Aku harus memindahkan kesadaranku ke tubuh hewan di dekat sini...)' }
            ],
            sfx: '⚡ FLASHHH PETIR KUNING ⚡',
            footer: 'Kayden terbangun dan mendapati dirinya berubah menjadi... seekor kucing oranye gemuk gendut!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'PERTEMUAN TAKDIR',
            narrations: [
              'Jiwoo menemukan kucing oranye gemuk itu terkapar penuh luka di samping tempat sampah.',
              'Tanpa ragu sedikitpun, Jiwoo menggendong kucing tersebut dan membawanya pulang untuk diobati.'
            ],
            dialogues: [
              { speaker: 'Jiwoo Seo', text: 'Astaga! Kucing malang, tubuhmu luka parah sekali! Tenang ya, aku akan merawatmu.' },
              { speaker: 'Kayden (Dalam Batin)', text: '(APA-APAAN MANUSIA INI?! Jangan pegang-pegang sembarangan! Aku ini Kayden sang petir terkuat!!)' }
            ],
            sfx: '🩹 DIOBATI DENGAN HATI-HATI 🩹',
            footer: 'Kayden mendengkur nyaman tanpa sadar saat diusap Jiwoo!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'SERANGAN AWAKENER MUSUH',
            narrations: [
              'Malam harinya, seorang Awakener pemburu musuh berhasil melacak sisa residu energi petir Kayden hingga ke depan rumah Jiwoo.',
              'Awakener jahat itu langsung menyerang hendak membunuh si kucing gemuk!'
            ],
            dialogues: [
              { speaker: 'Awakener Musuh', text: 'Hawa keberadaan Kayden ada di sini! Musnahlah bersama rumah ini!' },
              { speaker: 'Kayden (Kucing)', text: '(Sial! Dalam wujud kucing gemuk ini aku tidak punya cukup energi untuk menembakkan petir!)' }
            ],
            sfx: '💥 BLAASSTTT!! 💥',
            footer: 'Gelombang energi menghancurkan pekarangan rumah!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'KECEPATAN CAHAYA JIWOO SEO',
            narrations: [
              'Sebelum serangan mengenai kucing oranye, Jiwoo melesat dengan kecepatan kilat melebihi pandangan mata manusia!',
              'Jiwoo menyambar Kayden dan menghajar sang penyerang dengan pukulan kecepatan sonik!'
            ],
            dialogues: [
              { speaker: 'Jiwoo Seo', text: 'JANGAN PERNAH SAKITI KUCINGKU!!' },
              { speaker: 'Awakener Musuh', text: 'D-dari mana anak ini muncul?! Aku bahkan tidak bisa melihat bayangannya!' },
              { speaker: 'Kayden (Kucing)', text: '(Anak ini... dia bukan awakener terlatih... tapi kecepatan murninya ini luar biasa!)' }
            ],
            sfx: '⚡ SONIC BOOM!! ⚡',
            footer: 'Bersambung ke Chapter 2 — Pelatihan Rahasia Dimulai!'
          }
        ]
      }
    ]
  },
  'chainsaw-man': {
    title: 'CHAINSAW MAN',
    themeColor: '#f97316',
    secondaryColor: '#dc2626',
    chapters: [
      {
        chapterNumber: 1,
        title: 'Anjing dan Gergaji Mesin',
        pages: [
          {
            pageNumber: 1,
            sceneTitle: 'HIDUP DENJI DAN POCHITA',
            narrations: [
              'Denji hidup dalam kemiskinan ekstrem menanggung hutang warisan ayahnya kepada Yakuza senilai puluhan juta yen.',
              'Satu-satunya teman setianya adalah Pochita, iblis anjing berwujud gergaji mesin yang terluka saat mereka pertama kali bertemu.'
            ],
            dialogues: [
              { speaker: 'Denji', text: 'Pochita... impianku sederhana. Aku cuma ingin makan roti selai dan memeluk seorang gadis sebelum mati.' }
            ],
            sfx: '🪚 *VRRRRR... VRRRRR...* 🪚',
            footer: 'Mereka berdua berburu iblis kecil demi sepotong roti busuk.'
          },
          {
            pageNumber: 2,
            sceneTitle: 'PENGKHIANATAN YAKUZA ZOMBIE',
            narrations: [
              'Malam itu, bos Yakuza memanggil Denji ke sebuah gudang kosong dengan alasan ada iblis baru.',
              'Namun setibanya di sana, seluruh anggota Yakuza telah berubah menjadi monster zombie berlendir!'
            ],
            dialogues: [
              { speaker: 'Bos Yakuza Zombie', text: 'Denji... kami telah membuat kontrak dengan Zombie Devil demi kekuasaan abadi!' },
              { speaker: 'Zombie Devil', text: 'Devil Hunter pembunuh iblis... cincang tubuhnya jadi makanan kami!' }
            ],
            sfx: '🧟 GROAAARRRR!! 🧟',
            footer: 'Ratusan zombie mengeroyok dan mencincang tubuh Denji dan Pochita ke tempat sampah!'
          },
          {
            pageNumber: 3,
            sceneTitle: 'KONTRAK JANTUNG POCHITA',
            narrations: [
              'Di dalam tumpukan tempat sampah, darah Denji yang menetes memicu kesadaran terakhir Pochita.',
              'Pochita memilih menyatukan tubuh dan jiwanya ke dalam dada Denji sebagai jantung pengganti!'
            ],
            dialogues: [
              { speaker: 'Pochita', text: 'Denji... aku sangat suka mendengarkan impian-impian konyolmu.' },
              { speaker: 'Pochita', text: 'Ini adalah kontrak kita. Aku akan menjadi jantungmu... dan sebagai gantinya, tunjukkan padaku impianmu tercapai!' }
            ],
            sfx: '❤️ DUK... DUK... DUK... ❤️',
            footer: 'Tali starter gergaji mesin muncul menyembul dari dada Denji!'
          },
          {
            pageNumber: 4,
            sceneTitle: 'TRANSFORMASI CHAINSAW MAN',
            narrations: [
              'Denji bangkit dari tumpukan mayat. Dengan senyuman liar tanpa rasa takut, Denji menarik tali starter di dadanya!',
              'Gigi gergaji mesin raksasa mencuat keluar membelah kepalanya, dan bilah rantai berputar cepat di kedua lengannya!'
            ],
            dialogues: [
              { speaker: 'Denji', text: 'Kalian hutang padaku gaji berburu iblis... SEKARANG SAATNYA MEMBAYAR DENGAN NYAWA KALIAN!!' }
            ],
            sfx: '🪚 VRRRRRROOOOOOMMMMMMMM!! 🪚',
            footer: 'Darah dan raungan gergaji mesin memecah keheningan malam!'
          },
          {
            pageNumber: 5,
            sceneTitle: 'PEMBANTAIAN SANG CHAINSAW',
            narrations: [
              'Chainsaw Man mengamuk liar mencabik-cabik Zombie Devil dan ratusan monster zombie hingga tak bersisa.',
              'Keesokan paginya, Makima dari Biro Keamanan Publik tiba di lokasi dan memeluk tubuh Denji yang kelelahan.'
            ],
            dialogues: [
              { speaker: 'Makima', text: 'Kau manusia atau iblis? Tenanglah, kau aman bersamaku sekarang.' },
              { speaker: 'Denji', text: '(Wangi sekali... perempuan ini memelukku... sarapan roti selai setiap hari... impianku dimulai di sini!)' }
            ],
            sfx: '🩸 CHAINSAW MAN BANGKIT 🩸',
            footer: 'Bersambung ke Chapter 2 — Selamat Datang di Divisi Khusus 4!'
          }
        ]
      }
    ]
  }
};

function cleanEmoji(str) {
  if (!str) return '';
  return str.replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}]/gu, '').trim();
}

function wrapLines(ctx, text, maxWidth) {
  const words = text.split(' ');
  const lines = [];
  let current = '';
  for (let i = 0; i < words.length; i++) {
    const test = current ? current + ' ' + words[i] : words[i];
    if (ctx.measureText(test).width > maxWidth && current) {
      lines.push(current);
      current = words[i];
    } else {
      current = test;
    }
  }
  if (current) lines.push(current);
  return lines;
}

function drawRoundBox(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

function drawComicPage(comicSlug, chapter, page) {
  const width = 800;
  const height = 1200;
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');

  const storyInfo = COMIC_STORIES[comicSlug] || {
    title: comicSlug.toUpperCase().replace(/-/g, ' '),
    themeColor: '#38bdf8',
    secondaryColor: '#6366f1'
  };

  const themeColor = storyInfo.themeColor || '#38bdf8';
  const secondaryColor = storyInfo.secondaryColor || '#818cf8';

  // ── 1. Webtoon Dark Background ──
  const bgGrad = ctx.createLinearGradient(0, 0, 0, height);
  bgGrad.addColorStop(0, '#0a0d16');
  bgGrad.addColorStop(0.3, '#101626');
  bgGrad.addColorStop(0.7, '#0d1322');
  bgGrad.addColorStop(1, '#06080e');
  ctx.fillStyle = bgGrad;
  ctx.fillRect(0, 0, width, height);

  // Subtle speed lines in background
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.025)';
  ctx.lineWidth = 1;
  for (let y = 0; y < height; y += 36) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(width, y);
    ctx.stroke();
  }

  // ── 2. Top Header Bar ──
  ctx.fillStyle = '#162032';
  drawRoundBox(ctx, 24, 20, width - 48, 64, 12);
  ctx.fill();
  ctx.strokeStyle = themeColor;
  ctx.lineWidth = 2;
  ctx.stroke();

  ctx.font = 'bold 22px ComicTitle';
  ctx.fillStyle = themeColor;
  ctx.fillText(storyInfo.title, 42, 58);

  ctx.font = 'bold 14px ComicTitle';
  ctx.fillStyle = '#94a3b8';
  const pageLabel = `CH. ${chapter.chapterNumber}  •  HALAMAN ${page.pageNumber}`;
  const labelWidth = ctx.measureText(pageLabel).width;
  ctx.fillText(pageLabel, width - 42 - labelWidth, 58);

  // ── 3. Scene Title ──
  let currentY = 120;
  ctx.font = 'bold 15px ComicTitle';
  ctx.fillStyle = secondaryColor;
  const cleanScene = cleanEmoji(page.sceneTitle);
  ctx.fillText(`[ SCENE: ${cleanScene} ]`, 32, currentY);
  currentY += 24;

  // ── 4. Narrations ──
  if (page.narrations && page.narrations.length > 0) {
    for (const nar of page.narrations) {
      ctx.font = 'italic 15px ComicItalic';
      const lines = wrapLines(ctx, nar, width - 100);
      const boxH = Math.max(54, lines.length * 24 + 16);

      ctx.fillStyle = 'rgba(15, 23, 42, 0.9)';
      drawRoundBox(ctx, 30, currentY, width - 60, boxH, 8);
      ctx.fill();

      // Accent border line on left
      ctx.fillStyle = themeColor;
      ctx.fillRect(30, currentY, 4, boxH);

      ctx.fillStyle = '#e2e8f0';
      for (let i = 0; i < lines.length; i++) {
        ctx.fillText(lines[i], 46, currentY + 24 + i * 24);
      }
      currentY += boxH + 12;
    }
  }

  // ── 5. Special Quest / System Box (for Manhwa) ──
  if (page.isSpecialQuest) {
    const questH = 120;
    ctx.fillStyle = '#0f172a';
    drawRoundBox(ctx, 32, currentY, width - 64, questH, 12);
    ctx.fill();
    ctx.strokeStyle = '#38bdf8';
    ctx.lineWidth = 2.5;
    ctx.stroke();

    ctx.font = 'bold 18px ComicTitle';
    ctx.fillStyle = '#38bdf8';
    ctx.textAlign = 'center';
    ctx.fillText(cleanEmoji(page.questTitle), width / 2, currentY + 38);

    ctx.font = '15px ComicBody';
    ctx.fillStyle = '#e2e8f0';
    const qLines = wrapLines(ctx, page.questDesc, width - 120);
    for (let i = 0; i < qLines.length; i++) {
      ctx.fillText(qLines[i], width / 2, currentY + 70 + i * 24);
    }
    ctx.textAlign = 'left';

    currentY += questH + 16;
  } else {
    // ── 5b. Atmospheric Comic Artwork Illustration Panel ──
    const panelH = 340;
    const panelY = currentY;

    ctx.save();
    drawRoundBox(ctx, 30, panelY, width - 60, panelH, 14);
    ctx.clip();

    // Dark atmosphere radial gradient
    const centerX = width / 2;
    const centerY = panelY + panelH / 2;
    const pGrad = ctx.createRadialGradient(centerX, centerY, 20, centerX, centerY, 260);
    pGrad.addColorStop(0, '#1e293b');
    pGrad.addColorStop(0.35, '#0f172a');
    pGrad.addColorStop(0.7, '#090d16');
    pGrad.addColorStop(1, '#030712');
    ctx.fillStyle = pGrad;
    ctx.fillRect(30, panelY, width - 60, panelH);

    // Dynamic aura burst
    const aura = ctx.createRadialGradient(centerX, centerY, 10, centerX, centerY, 150);
    aura.addColorStop(0, themeColor + 'd0');
    aura.addColorStop(0.4, secondaryColor + '80');
    aura.addColorStop(0.8, themeColor + '20');
    aura.addColorStop(1, 'transparent');
    ctx.fillStyle = aura;
    ctx.fillRect(30, panelY, width - 60, panelH);

    // Comic action rays radiating
    ctx.strokeStyle = themeColor + '50';
    ctx.lineWidth = 1.5;
    for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 10) {
      ctx.beginPath();
      ctx.moveTo(centerX + Math.cos(angle) * 35, centerY + Math.sin(angle) * 35);
      ctx.lineTo(centerX + Math.cos(angle) * 300, centerY + Math.sin(angle) * 300);
      ctx.stroke();
    }

    // Outer and inner concentric rings
    ctx.strokeStyle = themeColor + '80';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(centerX, centerY, 52, 0, Math.PI * 2);
    ctx.stroke();

    ctx.strokeStyle = secondaryColor + '60';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(centerX, centerY, 90, 0, Math.PI * 2);
    ctx.stroke();

    // Center scene focus banner
    ctx.fillStyle = 'rgba(15, 23, 42, 0.88)';
    drawRoundBox(ctx, centerX - 230, centerY - 36, 460, 72, 12);
    ctx.fill();
    ctx.strokeStyle = themeColor;
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.font = 'bold 20px ComicTitle';
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.shadowColor = themeColor;
    ctx.shadowBlur = 10;
    ctx.fillText(cleanScene.toUpperCase(), centerX, centerY + 2);
    ctx.shadowBlur = 0;

    ctx.font = 'italic 13px ComicItalic';
    ctx.fillStyle = '#93c5fd';
    ctx.fillText('Adegan aksi cerita berlanjut di dalam bab ini...', centerX, centerY + 24);
    ctx.textAlign = 'left';

    ctx.restore();

    // Border stroke
    ctx.strokeStyle = themeColor;
    ctx.lineWidth = 2.5;
    drawRoundBox(ctx, 30, panelY, width - 60, panelH, 14);
    ctx.stroke();

    currentY = panelY + panelH + 16;
  }

  // ── 6. Sound Effect (SFX) ──
  if (page.sfx) {
    const cleanSfx = cleanEmoji(page.sfx).replace(/^[!* ]+|[!* ]+$/g, '').trim();
    if (cleanSfx) {
      ctx.save();
      ctx.translate(width / 2, currentY + 22);
      ctx.rotate(-0.02);
      ctx.font = '38px ComicSFX';
      ctx.textAlign = 'center';

      // Outline
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 8;
      ctx.strokeText(`* ${cleanSfx} *`, 0, 0);

      // Gradient text fill
      ctx.fillStyle = '#f59e0b';
      ctx.fillText(`* ${cleanSfx} *`, 0, 0);
      ctx.restore();

      currentY += 52;
    }
  }

  // ── 7. Speech Bubbles / Dialogue ──
  if (page.dialogues && page.dialogues.length > 0) {
    for (let i = 0; i < page.dialogues.length; i++) {
      const d = page.dialogues[i];
      const isAltSpeaker = i % 2 === 1;
      const speakerColor = isAltSpeaker ? secondaryColor : themeColor;
      const bubbleX = isAltSpeaker ? 65 : 35;
      const bubbleW = width - 100;

      // Speaker Name Tag & Avatar Circle
      const speakerName = cleanEmoji(d.speaker);
      const initial = speakerName.charAt(0).toUpperCase() || 'P';

      ctx.font = 'bold 14px ComicBold';
      ctx.fillStyle = speakerColor;
      ctx.fillText(`[ ${speakerName} ]`, bubbleX + 38, currentY + 16);

      // Avatar Circle with initial
      ctx.fillStyle = speakerColor;
      ctx.beginPath();
      ctx.arc(bubbleX + 18, currentY + 11, 13, 0, Math.PI * 2);
      ctx.fill();

      ctx.font = 'bold 12px ComicBold';
      ctx.fillStyle = '#ffffff';
      ctx.textAlign = 'center';
      ctx.fillText(initial, bubbleX + 18, currentY + 15);
      ctx.textAlign = 'left';

      currentY += 24;

      // Dialogue text wrapping & dynamic height
      ctx.font = 'bold 15px ComicBody';
      const cleanText = cleanEmoji(d.text);
      const lines = wrapLines(ctx, cleanText, bubbleW - 36);
      const bubbleH = Math.max(54, lines.length * 24 + 18);

      // Speech bubble body
      ctx.fillStyle = '#ffffff';
      drawRoundBox(ctx, bubbleX, currentY, bubbleW, bubbleH, 14);
      ctx.fill();
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 2.5;
      ctx.stroke();

      // Dialogue text inside bubble
      ctx.fillStyle = '#0f172a';
      for (let l = 0; l < lines.length; l++) {
        ctx.fillText(lines[l], bubbleX + 18, currentY + 25 + l * 24);
      }

      currentY += bubbleH + 16;
      if (currentY > height - 90) break;
    }
  }

  // ── 8. Bottom Footer ──
  ctx.fillStyle = '#162032';
  drawRoundBox(ctx, 24, height - 68, width - 48, 48, 10);
  ctx.fill();
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
  ctx.lineWidth = 1;
  ctx.stroke();

  ctx.font = 'bold 14px ComicTitle';
  ctx.fillStyle = '#cbd5e1';
  ctx.textAlign = 'center';
  const cleanFooter = cleanEmoji(page.footer) || 'Bersambung...';
  ctx.fillText(cleanFooter, width / 2, height - 38);
  ctx.textAlign = 'left';

  return canvas.toBuffer('image/jpeg', 92);
}

/**
 * Generates all chapter story pages and saves to public/pages/<slug>/ch<num>/pg<num>.jpg
 */
async function generateAllComicPages() {
  const pagesBaseDir = path.join(__dirname, '../../public/pages');
  if (!fs.existsSync(pagesBaseDir)) {
    fs.mkdirSync(pagesBaseDir, { recursive: true });
  }

  console.log('🎨 Generating authentic comic story pages in Bahasa Indonesia...\n');

  for (const [slug, comicData] of Object.entries(COMIC_STORIES)) {
    for (const chapter of comicData.chapters) {
      const chapterDir = path.join(pagesBaseDir, slug, `ch${chapter.chapterNumber}`);
      if (!fs.existsSync(chapterDir)) {
        fs.mkdirSync(chapterDir, { recursive: true });
      }

      for (const page of chapter.pages) {
        const filePath = path.join(chapterDir, `pg${page.pageNumber}.jpg`);
        const buf = drawComicPage(slug, chapter, page);
        fs.writeFileSync(filePath, buf);
      }
      console.log(`  📖 ${comicData.title} Ch.${chapter.chapterNumber}: ${chapter.pages.length} story pages created`);
    }
  }

  console.log('\n✅ All comic story pages generated successfully!');
}

if (require.main === module) {
  generateAllComicPages()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Error generating pages:', err);
      process.exit(1);
    });
}

module.exports = {
  generateAllComicPages,
  COMIC_STORIES
};
