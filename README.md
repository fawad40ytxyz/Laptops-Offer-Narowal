# Apex Computers — Website + Admin Panel

Imported laptops (Narowal) ki single-file website + built-in admin panel.
Data aur images **Supabase** me save hote hain — is liye site kisi bhi device par same rehti hai.

- **Stack:** plain HTML/CSS/JS (ek hi file), no build step
- **Database:** Supabase (`site_content` table) — pehle se setup + connected
- **Images:** Supabase Storage (`media` bucket, public URLs)
- **Hosting:** Vercel (static)

---

## 🚀 Deploy (GitHub → Vercel)

### 1. GitHub par repo banayein
```bash
# is folder ke andar
git init
git add .
git commit -m "Apex Computers — website + admin panel"
git branch -M main
git remote add origin https://github.com/<YOUR-USERNAME>/<YOUR-REPO>.git
git push -u origin main
```

### 2. Vercel se connect karein
1. https://vercel.com/new kholein
2. **Import Git Repository** → apna repo select karein
3. Settings me:
   - **Framework Preset:** `Other`
   - **Build Command:** *(khali chhor dein)*
   - **Output Directory:** *(khali / `.`)*
4. **Deploy** dabayein — 20-30 second me live.

> Har `git push` par Vercel khud naya deploy kar dega.
> Koi environment variable set karne ki zaroorat **nahi** — Supabase URL + publishable key `index.html` ke andar set hain.

### 3. Custom domain (optional)
Vercel → Project → **Settings → Domains** → domain add karein → jo DNS record de, wo apne registrar me laga dein.

---

## 🔐 Admin panel

| | |
|---|---|
| **Kholne ka tarika** | Website ke kisi bhi **search bar** me `7939015601` type karein |
| Shortcut | `Ctrl + Shift + A` |
| URL | `https://<your-domain>/#/admin` |
| **Password** | `7939015601` → **Admin settings → Change admin password** se badlein |

Password database me **SHA-256 hash** ho kar rehta hai (plain text me kahin nahi), aur save/change sirf password verify hone par hota hai.

### Sections
- **Products** — add / edit / duplicate / delete, optional specs, extra details, **Mark as unavailable** (image par UNAVAILABLE watermark), **Hide** (site se chhupayein)
- **Categories** — brands, processors, RAM, budget ranges (+ storage/display/GPU/OS) → website ke **filters** aur dropdowns dono me lagu
- **Rails** — home page ki moving rows: brand ke products, **manually selected + ordered**, ya baaki brands
- **Reviews** — username / description / stars edit, add, delete (site ke 3D card style me live preview)
- **Contact & info** — numbers, WhatsApp, social links, location + Maps, hero/about text, ribbon, services, FAQ
- **Admin settings** — password change, Supabase connection test, JSON backup/restore
- **Media library** — image upload (→ Supabase Storage) ya direct URL paste

> ⚠️ **Har change ke baad upar wala "Save changes" button dabayein** — tabhi cloud me jata hai.

---

## 📁 Structure
```
├── index.html            # poori website + admin panel (single file)
├── vercel.json           # static config + security headers
├── robots.txt
├── README.md
└── supabase/
    └── setup.sql         # record ke liye (database pehle se setup hai)
```

---

## 🧪 Testing notes
- 47/47 automated checks pass: site render, filters, search, product page, saare 7 admin panels, product CRUD, image upload → Storage, unavailable watermark, categories → live filters, rails (brand/manual/off), reviews CRUD, contact edits, cloud password change, offline fallback, mobile 390px
- Supabase par direct write (bina password) **blocked** hai — public key se sirf read hota hai
- Network band ho to cached data se site chalti hai (graceful fallback)

## 🛠 Troubleshooting
| Masla | Hal |
|---|---|
| Admin nahi khul raha | Password check karein; `Ctrl+Shift+A` try karein |
| "Save" par error | Admin settings → **Test connection** (teeno green hone chahiye) |
| Image upload fail | Supabase → Storage → `media` bucket public hona chahiye |
| Purana data dikh raha | Hard refresh (`Ctrl+Shift+R`) |

---
© Apex Computers, Narowal.

---

## 🗂️ Catalogue (67 laptops)

Site ab **Laptop_Price_List_Resale.pdf** wali list par chal rahi hai:

- **67 products** — HP 29, Lenovo 29, Toshiba 4, Toshiba (Dynabook) 2, Acer 1, Dell 1, Microsoft 1
- Price range **Rs 21,000 – Rs 132,500**
- Har product ki photo **isi project ke Supabase Storage** (`media/catalogue/v1/...`) me hai — koi bahar ki website se hotlink nahi
- Filters: Brand / Processor / RAM / Budget — nayi list ke mutabiq set
- Home rails: **HP**, **Lenovo**, **Toshiba**, **Acer, Dell & Microsoft**

`index.html` ke andar bhi yehi 67 products **baked** hain — agar internet/Supabase band ho to bhi site puri list dikhati hai.

---

## 🔁 Naya price list aa jaye to?

Do tareeqe hain — tafseel `PRODUCT-LIST-UPDATE-GUIDE.md` me hai:

**A) Admin panel se (5–15 products):**
1. Media panel → photos upload → URL copy
2. Products panel → purane delete/hide, naye add (brand, name, price, cpu, ram, ssd, screen, gpu, specs, image URL)
3. **Save changes** — bas

**B) Script se (bari list):**
```bash
python3 tools/update_catalogue.py --csv new_list.csv --images ./photos --dry-run   # test
python3 tools/update_catalogue.py --csv new_list.csv --images ./photos             # live
```
Script photos upload karta hai, products replace karta hai, filters bhi khud refresh karta hai. Settings / reviews / media / password ko chhoota nahi.

> Update se pehle **Admin → Settings → Export data** se backup zaroor lein.
