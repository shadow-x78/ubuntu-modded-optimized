<div align="center">

<pre align="center">
  ██╗   ██╗███╗   ███╗ ██████╗
  ██║   ██║████╗ ████║██╔═══██╗
  ██║   ██║██╔████╔██║██║   ██║
  ██║   ██║██║╚██╔╝██║██║   ██║
  ╚██████╔╝██║ ╚═╝ ██║╚██████╔╝
   ╚═════╝ ╚═╝     ╚═╝ ╚═════╝
</pre>

# Ubuntu Modded Optimized

أوبنتو كامل على هاتفك الأندرويد — أمر واحد، بدون تعقيد

[![الإصدار](https://img.shields.io/badge/الإصدار-3.1.2-2563eb?style=flat-square&logo=semver)](CHANGELOG.md)
[![الرخصة](https://img.shields.io/badge/الرخصة-MIT-dc2626?style=flat-square)](LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![المنصة](https://img.shields.io/badge/المنصة-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 🌐 اللغة

<a href="README.md">🇬🇧 English</a> · <a href="README_AR.md">🇸🇦 العربية</a>

---

## 📋 فهرس المحتويات

- [ما هو UMO؟](#what-is-umo)
- [بيئات سطح المكتب](#desktop-environments)
- [البدء السريع](#quick-start)
- [الأوامر](#commands)
- [خيارات سطر الأوامر](#cli-options)
- [المتطلبات](#requirements)
- [هيكل المشروع](#project-structure)
- [التوثيق](#documentation)
- [المساهمة](#contributing)
- [الرخصة](#license)

---

<a id="what-is-umo"></a>
## 🤔 ما هو UMO؟

**UMO (Ubuntu Modded Optimized)** هو مثبِّت Ubuntu مفتوح المصدر لـ Termux، مُعاد كتابته من الصفر لحل المشاكل الجذرية الموجودة في كل مشروع مشابه. لا تبعيات واجهة خارجية، لا إعداد يدوي، لا مفاجآت.

| المشكلة | المشاريع الأخرى | UMO |
|---------|----------------|-----|
| واجهة `dialog` تنكسر | ❌ لا تزال تستخدمها | ✅ TUI نقي بـ POSIX sh — بدون تبعيات |
| VNC يموت عند قفل الشاشة | ❌ لا يوجد حل | ✅ `termux-wake-lock` مدمج |
| لا صوت داخل proot | ❌ حل يدوي | ✅ جسر PulseAudio عبر TCP |
| `systemctl` يفشل | ❌ أخطاء محيّرة | ✅ محاكي shell عام (أي خدمة) |
| عشرون خطوة يدوية | ❌ معقد للغاية | ✅ أمر واحد: `bash install.sh` |

---

<a id="desktop-environments"></a>
## 🖥️ بيئات سطح المكتب

| البيئة | النوع | مناسبة لـ |
|--------|-------|-----------|
| **XFCE4** | Full DE | الاستخدام اليومي — أداء متوازن |
| **LXDE** | Lightweight DE | الأجهزة القديمة وضعيفة الموارد |
| **Openbox** | Window Manager | المستخدمون المتقدمون، بصمة خفيفة |
| **Minimal** | CLI only | السيرفرات والاستخدام بدون واجهة |

**يشمل:** TigerVNC · جسر PulseAudio · Termux:X11 · محاكي systemctl عام · التحكم بالجلسات

---

<a id="quick-start"></a>
## 🚀 البدء السريع

```bash
# استنساخ المشروع
git clone https://github.com/Shadow-x78/termux-ubuntu-umo.git ~/UMO
cd ~/UMO

# تثبيت تفاعلي (موصى به)
bash install.sh

# تثبيت صامت بـ flags
bash install.sh --no-gui --de=xfce4 --apps=full

# تشغيل Ubuntu
~/umo-start.sh
```

---

<a id="commands"></a>
## ⌨️ الأوامر

### في Termux

| الأمر | الوصف |
|-------|-------|
| `~/umo-start.sh` | تشغيل Ubuntu + VNC + الصوت |
| `~/umo-stop.sh` | إيقاف جميع الخدمات |
| `~/umo-login.sh` | الدخول كـ root |
| `~/umo-user.sh` | الدخول كمستخدم ubuntu |
| `~/umo-vnc-start.sh` | تشغيل VNC فقط |
### داخل Ubuntu

| الأمر | الوصف |
|-------|-------|
| `umo-startvnc` | تشغيل خادم VNC |
| `umo-stopvnc` | إيقاف خادم VNC |
| `systemctl start <service>` | تشغيل خدمة (محاكى) |
| `systemctl status <service>` | فحص حالة الخدمة |
| `systemctl restart <service>` | إعادة تشغيل خدمة |

---

<a id="cli-options"></a>
## 🔧 خيارات سطر الأوامر

```bash
bash install.sh [OPTIONS]

  --no-gui, --non-interactive    تجاوز القوائم، استخدام الافتراضيات أو متغيرات البيئة
  --de=xfce4|lxde|openbox        اختيار بيئة سطح المكتب
  --apps=basic|dev|media|full    مجموعة التطبيقات المراد تثبيتها
  --dir=PATH                     مسار تثبيت مخصص
  --version=22.04|24.04          إصدار Ubuntu المطلوب
```

---

<a id="requirements"></a>
## 📋 المتطلبات

- Android 8.0+ — معالج ARM64 بنية (aarch64)
- Termux من F-Droid أو GitHub — **ليس** من Play Store
- مساحة حرة 2 GB+
- اتصال بالإنترنت

---

<a id="project-structure"></a>
## 🏗️ هيكل المشروع

```
UMO/
├── bin/
│   ├── umo-install          # المثبِّت الرئيسي
│   ├── umo-start            # مشغِّل الجلسة (Termux)
│   └── umo-stop             # موقف الجلسة (Termux)
├── lib/
│   ├── core-ansi.sh         # محرك الألوان والـ logging والـ banners
│   ├── core-ui.sh           # محرك TUI: قوائم، prompts، panels
│   ├── core-system.sh       # كشف المنصة، التخزين، الإنترنت
│   ├── core-net.sh          # التنزيل، المرايا، الاستخراج
│   └── core-fs.sh           # عمليات الملفات الآمنة والـ backups
├── modules/
│   ├── umo-proot.sh         # إعداد حاوية proot
│   ├── umo-vnc.sh           # تثبيت TigerVNC وإدارة الجلسات
│   ├── umo-audio.sh         # جسر PulseAudio عبر TCP
│   ├── umo-systemctl.sh     # محاكي systemctl
│   ├── umo-desktop.sh       # مثبِّت بيئات سطح المكتب
│   └── umo-apps.sh          # مثبِّت مجموعات التطبيقات
├── config/
│   ├── xstartup             # قالب جلسة VNC
│   ├── bashrc.patch         # تحسينات الـ shell داخل Ubuntu
│   └── sources.list         # قائمة مرايا Ubuntu
├── docs/
│   ├── INSTALL.md           # دليل التثبيت التفصيلي
│   └── TROUBLESHOOTING.md   # المشاكل الشائعة وحلولها
├── install.sh               # نقطة الدخول السريعة
├── CHANGELOG.md             # سجل التغييرات
├── LICENSE                  # MIT License
└── README.md                # الملف الرئيسي
```

---

<a id="documentation"></a>
## 📚 التوثيق

| المستند | الوصف |
|---------|-------|
| [INSTALL.md](docs/INSTALL.md) | دليل التثبيت التفصيلي |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | المشاكل الشائعة وحلولها |

---

<a id="contributing"></a>
## 🤝 المساهمة

1. Fork المستودع
2. أنشئ فرعاً جديداً: `git checkout -b feature/my-feature`
3. Commit التغييرات
4. Push إلى الفرع
5. افتح Pull Request

---

<a id="license"></a>
## 📜 الرخصة

موزَّع تحت [رخصة MIT](LICENSE).

---

<div align="center">

بُني بواسطة <a href="https://github.com/Shadow-x78">Shadow-x78</a> ·
<a href="https://github.com/Shadow-x78/termux-ubuntu-umo">termux-ubuntu-umo</a> ·
[سجل التغييرات](CHANGELOG.md)

<sub>&copy; 2026 Shadow-x78</sub>

</div>
