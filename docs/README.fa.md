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

### نصب یک‌خطی

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh | tr -d '\r' | sudo bash
```

این دستور از مقادیر پیش‌فرض امن استفاده می‌کند: زبان چینی، secret خودکار، بدون tag، تشخیص خودکار IP عمومی، پورت‌های ۴۴۳ و ۸۸۸۸ و یک worker.

برای نمایش گزینه‌ها، ابتدا فایل را دانلود و سپس به‌صورت تعاملی اجرا کنید:

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh | tr -d '\r' > mtproxy-install.sh && sudo bash mtproxy-install.sh
```

برای سرور production بهتر است ابتدا اسکریپت را دانلود و بررسی کنید.

برای تست کامل تعامل بدون تغییر سیستم:

```bash
bash install.sh --dry-run
```

حالت آزمایشی به root نیاز ندارد و وابستگی نصب نمی‌کند، کد را نمی‌سازد، فایل سیستمی نمی‌نویسد و سرویسی اجرا نمی‌کند.

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
sudo bash uninstall.sh
```

این اسکریپت به‌صورت پیش‌فرض سرویس‌ها را حذف می‌کند، اما فایل باینری و تنظیمات را نگه می‌دارد تا secret به‌اشتباه حذف نشود. پس از بررسی، پوشه‌ها را دستی حذف کنید.

## منابع رسمی

- [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy)
- [README رسمی MTProxy](https://github.com/TelegramMessenger/MTProxy/blob/master/README.md)
- [مستندات رسمی MTProto transports](https://core.telegram.org/mtproto/mtproto-transports)
