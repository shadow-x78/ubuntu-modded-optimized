### ماذا يفعل هذا الـPR؟ / What does this PR do?

<!-- وصف موجز للتغيير / Brief description of the change -->

### لماذا؟ / Why?

<!-- راجع إدخال CHANGELOG.md أو issue المرجعية / Reference the CHANGELOG.md entry or related issue -->

### كيف تم اختباره؟ / How was it tested?

- [ ] `sh -n` يمر على جميع السكربتات المعدلة / passes on all modified scripts
- [ ] `shellcheck -s sh` لا يعرض تحذيرات جديدة / shows no new warnings
- [ ] اختبار يدوي على: <!-- إصدار Android + إصدار Termux / Android version + Termux version -->

### قائمة المراجعة / Checklist

- [ ] رؤوس الملفات تطابق نمط UMO / File headers match UMO style (`# UMO - <module> (MIT License)` + GitHub URL)
- [ ] `CHANGELOG.md` محدّث بإدخال إصدار جديد / updated with a new versioned entry
- [ ] رفع الإصدار في `bin/umo-install` إذا كان هذا PR إصداراً / Version bump if this is a release PR
