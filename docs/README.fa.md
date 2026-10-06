# راهنمای نصب یک‌کلیکی Telegram MTProxy

نویسنده: Sunny8886667

Telegram: [@Bill_999](https://t.me/Bill_999)

پروژه: [github.com/Sunny8886667/MTProxy](https://github.com/Sunny8886667/MTProxy)

## معرفی

این پروژه یک نصب‌کنندهٔ چندزبانه بر پایهٔ کد رسمی Telegram MTProxy است و برای سرورهای Debian، Ubuntu و خانوادهٔ RHEL طراحی شده است.

اسکریپت وابستگی‌های لازم را بررسی و نصب می‌کند، کد رسمی را می‌سازد، فایل‌های پیکربندی رسمی Telegram را دریافت می‌کند، سرویس systemd می‌سازد و لینک اتصال Telegram را نمایش می‌دهد.

## پیش‌نیازها

- Debian 11/12؛
- Ubuntu 20.04/22.04/24.04؛
- RHEL، CentOS، Rocky، AlmaLinux یا Fedora؛
- دسترسی root؛
- systemd؛
- معماری x86_64 پیشنهاد می‌شود.

اسکریپت سرویس دیگری مانند Nginx یا Apache را که از پورت استفاده می‌کند متوقف نمی‌کند و در صورت تداخل متوقف می‌شود.

## نصب

### کلون کردن و اجرا

```bash
git clone https://github.com/Sunny8886667/MTProxy.git
cd MTProxy
sudo bash install.sh
```

با اجرای بدون گزینه، ابتدا زبان را انتخاب می‌کنید، معرفی پروژه نمایش داده می‌شود و پس از Enter نصب مستقیماً شروع می‌شود. پس از نصب، برای ورود به پنل مدیریت `menu` را وارد کنید.

### نصب یک‌خطی

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh | tr -d '\r' | sudo bash
```

این دستور مستقیماً با مقادیر پیش‌فرض امن نصب می‌کند: زبان چینی، secret خودکار با padding تصادفی `dd`، بدون tag، تشخیص خودکار IP عمومی، پورت‌های ۴۴۳ و ۸۸۸۸ و یک worker.

برای سرور production بهتر است ابتدا اسکریپت را دانلود و بررسی کنید.

## فرمان‌های مدیریت

پس از نصب، برای ورود به منوی مدیریت اجرا کنید:

```bash
menu
```

یا:

```bash
sudo bash install.sh menu
```

همچنین می‌توانید یک عملیات را مستقیم اجرا کنید:

```bash
sudo bash install.sh status
sudo bash install.sh connection
sudo bash install.sh logs
sudo bash install.sh restart
sudo bash install.sh update-config
sudo bash install.sh uninstall
```

حذف پیش‌فرض فقط سرویس و timer مربوط به systemd را حذف می‌کند و برنامه، تنظیمات و secret را نگه می‌دارد. برای حذف کامل، به‌صورت صریح اجرا کنید:

```bash
sudo bash install.sh uninstall --purge --yes
```

همچنین می‌توانید منوی مدیریت را مستقیماً از GitHub باز کنید:

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh -o /tmp/mtproxy-install.sh
sudo bash /tmp/mtproxy-install.sh menu
```

## گزینه‌های نصب‌کننده

۱. انتخاب زبان چینی، انگلیسی یا فارسی؛
۲. نمایش معرفی پروژه، نویسنده و راه تماس Telegram؛
۳. ورود secret دلخواه یا تولید خودکار با Enter؛
۴. ورود tag دریافتی از `@MTProxybot` یا رد کردن آن؛
۵. ورود IP/دامنهٔ عمومی، پورت اتصال، پورت آمار و تعداد worker.

secretهای قابل قبول:

- ۳۲ کاراکتر هگزادسیمال برای secret استاندارد؛
- می‌توانید secret سی‌وچهارکاراکتری با پیشوند `dd` هم وارد کنید؛ اسکریپت `dd` را برای اجرای سرور حذف می‌کند و در پیوند کاربر نگه می‌دارد.

tag دریافتی از `@MTProxybot` باید یک رشتهٔ ۳۲ کاراکتری هگزادسیمال باشد.

مقادیر پیش‌فرض:

- پورت اتصال: 443؛
- پورت آمار محلی: 8888؛
- تعداد worker: 1.

## دستورات سرویس

```bash
sudo systemctl status mtproxy
sudo journalctl -u mtproxy -f
sudo systemctl restart mtproxy
curl http://127.0.0.1:8888/stats
```

پیکربندی رسمی proxy هر روز توسط timer مربوط به systemd بررسی می‌شود:

```bash
sudo systemctl status mtproxy-config-update.timer
sudo systemctl start mtproxy-config-update.service
```

## مسیرهای مهم

```text
/opt/MTProxy/objs/bin/mtproto-proxy
/etc/mtproxy/proxy-secret
/etc/mtproxy/proxy-multi.conf
/etc/mtproxy/mtproxy.env
/etc/systemd/system/mtproxy.service
```

فایل secret و تنظیمات runtime با سطح دسترسی محدود ذخیره می‌شوند. آن‌ها را در GitHub یا چت عمومی منتشر نکنید.

## دربارهٔ TLS و دامنه

راهنمای رسمی فعلی MTProxy روش استانداردی برای اتصال TLS به یک دامنه ارائه نمی‌کند. بنابراین این پروژه تنظیمات غیررسمی Fake-TLS یا secretهای `ee` را اضافه نمی‌کند.

## حذف نصب

```bash
sudo bash mtproxy-install.sh uninstall
```

این اسکریپت به‌صورت پیش‌فرض سرویس‌ها را حذف می‌کند، اما فایل باینری و تنظیمات را نگه می‌دارد تا secret به‌اشتباه حذف نشود. پس از بررسی، پوشه‌ها را دستی حذف کنید.

## منابع رسمی

- [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy)
- [README رسمی MTProxy](https://github.com/TelegramMessenger/MTProxy/blob/master/README.md)
- [مستندات رسمی MTProto transports](https://core.telegram.org/mtproto/mtproto-transports)

