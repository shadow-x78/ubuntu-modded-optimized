<div align="center">

# دليل التثبيت — UMO

[![الإصدار](https://img.shields.io/badge/الإصدار-3.1.8-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![الرخصة](https://img.shields.io/badge/الرخصة-MIT-dc2626?style=flat-square)](../LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![المنصة](https://img.shields.io/badge/المنصة-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 🌐 اللغة

<a href="INSTALL.md">🇬🇧 English</a> · <a href="INSTALL_AR.md">🇸🇦 العربية</a>

---

## 📋 فهرس المحتويات

- [المتطلبات](#requirements)
- [التثبيت](#install)
- [التثبيت الصامت](#silent-install)
- [بيئات سطح المكتب](#desktop-environments)
- [مجموعات التطبيقات](#application-groups)
- [أول تشغيل](#first-boot)
- [مرجع الأوامر](#commands)
- [إلغاء التثبيت](#uninstall)

---

<a id="requirements"></a>
## 📋 المتطلبات

| المتطلب | التفاصيل |
|---------|---------|
| Android | 8.0 أو أحدث |
| المعالج | ARM64 (aarch64) |
| Termux | من F-Droid أو GitHub — **ليس** من Play Store |
| التخزين | 2 GB+ مساحة حرة |
| الشبكة | اتصال بالإنترنت مطلوب |

---

<a id="install"></a>
## 🚀 التثبيت

```bash
# استنساخ المشروع
git clone https://github.com/Shadow-x78/termux-ubuntu-umo.git ~/UMO
cd ~/UMO

# تشغيل المثبِّت التفاعلي
bash install.sh
```

سيقودك المثبِّت عبر المراحل التالية:
1. التحقق من البيئة
2. تثبيت التبعيات
3. اختيار بيئة سطح المكتب
4. اختيار مجموعة التطبيقات
5. تنزيل Ubuntu وإعداده

---

<a id="silent-install"></a>
## ⚙️ التثبيت الصامت

تجاوز جميع القوائم والتشغيل بخيارات محددة مسبقاً:

```bash
bash install.sh --no-gui --de=xfce4 --apps=full
```

يمكنك أيضاً استخدام متغيرات البيئة:

```bash
UMO_DE=lxde UMO_APP_SET=dev UMO_NON_INTERACTIVE=1 bash install.sh
```

---

<a id="desktop-environments"></a>
## 🖥️ بيئات سطح المكتب

| الـ Flag | البيئة | مناسبة لـ |
|----------|--------|-----------|
| `--de=xfce4` | XFCE4 | الاستخدام اليومي — أداء متوازن |
| `--de=lxde` | LXDE | الأجهزة القديمة وضعيفة الموارد |
| `--de=openbox` | Openbox | المستخدمون المتقدمون، بصمة خفيفة |
| `--de=minimal` | بدون واجهة | السيرفرات والاستخدام الخالص |

---

<a id="application-groups"></a>
## 📦 مجموعات التطبيقات

| الـ Flag | المجموعة | تشمل |
|----------|---------|------|
| `--apps=basic` | أساسية | الأدوات الأساسية فقط |
| `--apps=dev` | تطوير | git, vim, python3, nodejs, build-essential |
| `--apps=media` | وسائط | ffmpeg, vlc, gimp |
| `--apps=full` | كاملة | جميع ما سبق |

---

<a id="first-boot"></a>
## 🔐 أول تشغيل

```bash
# تشغيل Ubuntu (VNC + الصوت)
~/umo-start.sh

# الاتصال عبر تطبيق VNC
# العنوان  : localhost:5901
# كلمة المرور: ubuntu  ← غيّرها فوراً!
```

> **غيِّر كلمة مرور VNC مباشرة بعد أول دخول:**
> ```bash
> vncpasswd
> ```

---

<a id="commands"></a>
## ⌨️ مرجع الأوامر

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
| `systemctl stop <service>` | إيقاف خدمة (محاكى) |
| `systemctl enable <service>` | تفعيل خدمة |
| `systemctl disable <service>` | تعطيل خدمة |
| _(مثال: `systemctl start ssh`)_ | _تشغيل خادم SSH_ |

---

<a id="uninstall"></a>
## 🗑️ إلغاء التثبيت

```bash
# حذف Ubuntu وجميع ملفات UMO
rm -rf ~/umo-ubuntu ~/.umo ~/umo-*.sh
```

---

<div align="center">

بُني بواسطة <a href="https://github.com/Shadow-x78">Shadow-x78</a> ·
[العودة إلى README](../README_AR.md)

<sub>&copy; 2026 Shadow-x78</sub>

</div>
