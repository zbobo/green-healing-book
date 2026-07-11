/* ==========================================================
   電子成果冊閱讀器
   載入 JSON → 建立頁面與縮圖 → 翻頁控制
   ========================================================== */

const reader      = document.getElementById('reader');
const bookTitle   = document.getElementById('bookTitle');
const currentEl   = document.getElementById('currentPage');
const totalEl     = document.getElementById('totalPages');
const prevBtn     = document.getElementById('prevBtn');
const nextBtn     = document.getElementById('nextBtn');
const thumbBtn    = document.getElementById('thumbBtn');
const thumbDialog = document.getElementById('thumbDialog');
const thumbGrid   = document.getElementById('thumbGrid');
const thumbClose  = document.getElementById('thumbCloseBtn');

let pageEls  = [];
let thumbEls = [];
let current  = 0;

init();

async function init() {
  let book;
  try {
    const res = await fetch('data/books.json');
    if (!res.ok) throw new Error(res.status);
    const data = await res.json();
    book = data.books[0];
  } catch (err) {
    showMessage('成果冊載入失敗，請稍後再試');
    console.error(err);
    return;
  }

  bookTitle.textContent = book.title;
  document.title = book.title;
  totalEl.textContent = book.pages.length;

  buildPages(book.pages);
  buildThumbs(book.pages);
  observePages();
  bindControls();

  // 依網址 #p=N 起始頁（重新整理、分享連結都會停在同一頁）
  const start = pageFromHash();
  if (start > 0) goToPage(start, false);
  else setCurrent(0);
}

/* ---------- 建立頁面 ---------- */

function buildPages(pages) {
  pages.forEach((src, i) => {
    const section = document.createElement('section');
    section.className = 'page';
    section.dataset.index = i;

    const img = document.createElement('img');
    img.src = src;
    img.alt = `第 ${i + 1} 頁`;
    img.decoding = 'async';
    // 前兩頁立即載入，其餘交給瀏覽器 lazy load
    img.loading = i < 2 ? 'eager' : 'lazy';
    img.draggable = false;

    section.appendChild(img);
    reader.appendChild(section);
    pageEls.push(section);
  });
}

function buildThumbs(pages) {
  pages.forEach((src, i) => {
    const btn = document.createElement('button');
    btn.className = 'thumb';
    btn.setAttribute('aria-label', `跳至第 ${i + 1} 頁`);

    const img = document.createElement('img');
    img.src = src;
    img.alt = '';
    img.loading = 'lazy';
    img.decoding = 'async';

    const num = document.createElement('span');
    num.className = 'thumb__num';
    num.textContent = i + 1;

    btn.append(img, num);
    btn.addEventListener('click', () => {
      thumbDialog.close();
      goToPage(i, false);
    });

    thumbGrid.appendChild(btn);
    thumbEls.push(btn);
  });
}

/* ---------- 目前頁碼追蹤 ---------- */

function observePages() {
  const io = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) setCurrent(Number(entry.target.dataset.index));
    }
  }, { root: reader, threshold: 0.6 });

  pageEls.forEach((el) => io.observe(el));
}

function setCurrent(i) {
  current = i;
  currentEl.textContent = i + 1;
  prevBtn.disabled = i === 0;
  nextBtn.disabled = i === pageEls.length - 1;

  thumbEls.forEach((el, j) => el.classList.toggle('is-active', j === i));

  // 用 replaceState 更新 #p=N，不寫入瀏覽紀錄
  history.replaceState(null, '', `#p=${i + 1}`);
}

/* ---------- 翻頁 ---------- */

function goToPage(i, smooth = true) {
  i = Math.max(0, Math.min(i, pageEls.length - 1));
  reader.scrollTo({
    left: pageEls[i].offsetLeft,
    behavior: smooth ? 'smooth' : 'auto',
  });
}

function pageFromHash() {
  const m = location.hash.match(/^#p=(\d+)$/);
  return m ? Number(m[1]) - 1 : -1;
}

/* ---------- 操作 ---------- */

function bindControls() {
  prevBtn.addEventListener('click', () => goToPage(current - 1));
  nextBtn.addEventListener('click', () => goToPage(current + 1));

  // 鍵盤 ← → 翻頁
  document.addEventListener('keydown', (e) => {
    if (thumbDialog.open) return;
    if (e.key === 'ArrowLeft') goToPage(current - 1);
    if (e.key === 'ArrowRight') goToPage(current + 1);
  });

  // 點頁面切換工具列（位移超過門檻視為滑動，不觸發）
  let downX = 0;
  let downY = 0;
  reader.addEventListener('pointerdown', (e) => {
    downX = e.clientX;
    downY = e.clientY;
  });
  reader.addEventListener('pointerup', (e) => {
    if (Math.abs(e.clientX - downX) < 8 && Math.abs(e.clientY - downY) < 8) {
      document.body.classList.toggle('ui-hidden');
    }
  });

  // 縮圖導覽
  thumbBtn.addEventListener('click', () => {
    thumbDialog.showModal();
    const active = thumbEls[current];
    if (active) active.scrollIntoView({ block: 'center' });
  });
  thumbClose.addEventListener('click', () => thumbDialog.close());
  thumbDialog.addEventListener('click', (e) => {
    if (e.target === thumbDialog) thumbDialog.close();
  });

  // 轉向 / 視窗縮放後，重新對齊目前頁
  window.addEventListener('resize', () => goToPage(current, false));
}

function showMessage(text) {
  const div = document.createElement('div');
  div.className = 'reader-message';
  div.textContent = text;
  document.body.appendChild(div);
}
