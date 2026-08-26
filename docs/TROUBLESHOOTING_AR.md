<div align="center">

# استكشاف الأخطاء وإصلاحها - UMO

[![الإصدار](https://img.shields.io/badge/الإصدار-4.15.5-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![الرخصة](https://img.shields.io/badge/الرخصة-GPL--3.0-dc2626?style=flat-square)](../LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![المنصة](https://img.shields.io/badge/المنصة-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 🌐 اللغة

<a href="TROUBLESHOOTING.md">🇬🇧 English</a> · <a href="TROUBLESHOOTING_AR.md">🇸🇦 العربية</a>

---

## 📋 فهرس المحتويات

- [VNC ينقطع عند قفل الشاشة](#vnc-lock)
- [VNC يتوقف من تلقاء نفسه (أندرويد 12+)](#phantom-process)
- [لا يوجد صوت داخل proot](#no-audio)
- [systemctl يفشل](#systemctl)
- [شاشة سوداء أو VNC لا يتصل](#black-screen)
- [مساحة تخزين منخفضة أثناء التثبيت](#low-storage)
- [التثبيت يفشل في خطوة التبعيات](#dep-fail)
- [لا تزال عالقاً؟](#still-stuck)

---

<a id="vnc-lock"></a>
## 📱 VNC ينقطع عند قفل الشاشة

**السبب:** Android يوقف العمليات في الخلفية عند قفل الشاشة.

**الحل:** UMO يشغّل `termux-wake-lock` تلقائياً. إذا استمرت المشكلة:

```bash
termux-wake-lock
umo login
```

> أبقِ Termux مفتوحاً في المقدمة أو استخدم إشعاراً دائماً لمنع Android من إيقافه.

---

<a id="phantom-process"></a>
## 🛑 VNC يتوقف من تلقاء نفسه (أندرويد 12+)

**السبب:** «قاتل العمليات الوهمية» في أندرويد يُنهي سلاسل العمليات الخلفية العميقة (proot ← bash ← Xtigervnc) بعد ثوانٍ/دقائق من التشغيل حتى مع wake-lock. الخدمات المباشرة (PulseAudio) تنجو - ولهذا يُظهر `umo status` أن الصوت يعمل بينما VNC متوقف.

**الحل (مرة واحدة، من حاسوب عبر USB):**

```bash
adb shell device_config put activity_manager max_phantom_processes 2147483647
adb shell settings put global settings_enable_monitor_phantom_procs false
```

> أمر `settings` يُرفض على بعض إصدارات أندرويد 14+ - سطر `device_config` وحده كافٍ عادةً. كما أن UMO يعيد تشغيل خادم VNC تلقائياً حتى 3 مرات إذا مات.

**التحقق:** `umo start`، انتظر دقيقة، ثم `umo status`. إذا استمر التوقف، افحص `~/.umo/logs/vnc-start.log`.

---

<a id="no-audio"></a>
## 🔇 لا يوجد صوت داخل proot

**السبب:** PulseAudio لا يعمل أو جسر TCP غير نشط.

**الحل:**

```bash
# إعادة تشغيل كل شيء (موصى به)
umo stop
umo login

# أو تشغيل PulseAudio يدوياً داخل Ubuntu
pulseaudio --start
```

---

<a id="systemctl"></a>
## ⚙️ systemctl يفشل

**السبب:** `systemd` القياسي لا يعمل داخل حاويات proot.

**الحل:** UMO يثبِّت محاكي `systemctl` **عام** متوافق مع shell يعمل مع **أي خدمة**. استخدمه بشكل طبيعي:

```bash
systemctl start <service>
systemctl stop <service>
systemctl restart <service>
systemctl status <service>
systemctl enable <service>
systemctl disable <service>
# مثال: systemctl start ssh
```

> إذا كان المحاكي مفقوداً، أعِد تشغيل المثبِّت أو انسخ `modules/umo-systemctl.sh` يدوياً.

---

<a id="black-screen"></a>
## 🖥️ شاشة سوداء أو VNC لا يتصل

**السبب:** جلسة VNC قديمة أو فشل بيئة سطح المكتب في البدء.

**الحل:**

```bash
# إيقاف جميع الخدمات وإعادة التشغيل
umo stop
umo login
```

إذا استمرت المشكلة، اقتل أي عمليات VNC عالقة:

```bash
# داخل Ubuntu
vncserver -kill :1
vncserver :1
```

---

<a id="low-storage"></a>
## 💾 مساحة تخزين منخفضة أثناء التثبيت

**السبب:** ذاكرة التخزين المؤقت للحزم أو تنزيل غير مكتمل يستهلك المساحة.

**الحل:**

```bash
# مسح ذاكرة التخزين المؤقت لـ Termux
pkg clean

# مسح ذاكرة التخزين المؤقت لـ UMO
rm -rf ~/.umo/cache
```

ثم أعِد تشغيل المثبِّت.

---

<a id="dep-fail"></a>
## 📦 التثبيت يفشل في خطوة التبعيات

**السبب:** حزم Termux قديمة أو مرايا المستودع معطلة.

**الحل:**

```bash
# تحديث حزم Termux أولاً
pkg update && pkg upgrade

# ثم إعادة المحاولة
bash install.sh
```

> تأكد من أنك تستخدم Termux من **F-Droid أو GitHub** - إصدار Play Store قديم وغير مدعوم.

---

<a id="still-stuck"></a>
## 🆘 لا تزال عالقاً؟

تحقق من سجلات UMO للحصول على تفاصيل الخطأ:

```bash
cat ~/.umo/logs/install.log
```

إذا استمرت المشكلة، افتح issue مع إرفاق السجل:

[افتح Issue](https://github.com/shadow-x78/ubuntu-modded-optimized/issues)

---

<div align="center">

بُني بواسطة <a href="https://github.com/shadow-x78">shadow-x78</a> ·
[العودة إلى README](../README_AR.md)

<sub>&copy; 2026 Ubuntu Modded Optimized (UMO)</sub>

</div>
