using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.Security;
using ROYALHOTEL.Services.Email;

namespace ROYALHOTEL.Controllers
{
    public class AccountController : Controller
    {
        private readonly RoyalHotelDbContext _db;
        private readonly IEmailSender _email;

        private const string S_USER_NAME = "USER_NAME";
        private const string S_USER_EMAIL = "USER_EMAIL";
        private const string S_USER_ROLE = "USER_ROLE";
        private const string S_USER_ID = "USER_ID";

        public AccountController(RoyalHotelDbContext db, IEmailSender email)
        {
            _db = db;
            _email = email;
        }

        [HttpGet]
        public IActionResult Login()
        {
            ViewBag.ErrorMessage = TempData["ErrorMessage"];
            ViewBag.SuccessMessage = TempData["SuccessMessage"];
            return View();

            
        }
        

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(string email, string password)
        {
            email = (email ?? "").Trim().ToLowerInvariant();
            password = password ?? "";

            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            {
                ViewBag.ErrorMessage = "Vui lòng điền đầy đủ thông tin";
                return View();
            }

            var acc = await _db.Accounts.AsNoTracking().FirstOrDefaultAsync(x => x.Email == email);
            if (acc == null || !CryptoHelper.VerifyPassword(password, acc.PasswordHash, acc.PasswordSalt))
            {
                ViewBag.ErrorMessage = "Email hoặc mật khẩu không đúng";
                return View();
            }   
            if ((acc.Status ?? "active").ToLower() == "locked")
            {
                ViewBag.ErrorMessage = "Tài khoản của bạn đã bị khóa";
                return View();
            }

            HttpContext.Session.SetString(S_USER_NAME, acc.FullName);
            HttpContext.Session.SetString(S_USER_EMAIL, acc.Email);
            HttpContext.Session.SetString(S_USER_ROLE, acc.Role ?? "user");
            HttpContext.Session.SetInt32(S_USER_ID, acc.Id);

            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult Register() => View();

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(string fullName, string email, string phone, string password, string confirmPassword)
        {
            fullName = (fullName ?? "").Trim();
            email = (email ?? "").Trim().ToLowerInvariant();
            phone = (phone ?? "").Trim();
            password = password ?? "";
            confirmPassword = confirmPassword ?? "";

            if (string.IsNullOrWhiteSpace(fullName) ||
                string.IsNullOrWhiteSpace(email) ||
                string.IsNullOrWhiteSpace(phone) ||
                string.IsNullOrWhiteSpace(password) ||
                string.IsNullOrWhiteSpace(confirmPassword))
            {
                ViewBag.ErrorMessage = "Vui lòng điền đầy đủ thông tin";
                return View();
            }

            if (password.Length < 6)
            {
                ViewBag.ErrorMessage = "Mật khẩu tối thiểu 6 ký tự";
                return View();
            }

            if (password != confirmPassword)
            {
                ViewBag.ErrorMessage = "Mật khẩu xác nhận không khớp";
                return View();
            }

            var exists = await _db.Accounts.AnyAsync(x => x.Email == email);
            if (exists)
            {
                ViewBag.ErrorMessage = "Email đã được đăng ký";
                return View();
            }

            var (hash, salt) = CryptoHelper.HashPassword(password);

            var acc = new Account
            {
                FullName = fullName,
                Email = email,
                Phone = phone,
                PasswordHash = hash,
                PasswordSalt = salt,
                Role = "user",
                Status = "active",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Accounts.Add(acc);
            await _db.SaveChangesAsync();

            HttpContext.Session.SetString(S_USER_NAME, acc.FullName);
            HttpContext.Session.SetString(S_USER_EMAIL, acc.Email);
            HttpContext.Session.SetString(S_USER_ROLE, acc.Role ?? "user");
            HttpContext.Session.SetInt32(S_USER_ID, acc.Id);

            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult Logout()
        {
            HttpContext.Session.Remove(S_USER_NAME);
            HttpContext.Session.Remove(S_USER_EMAIL);
            HttpContext.Session.Remove(S_USER_ROLE);
            HttpContext.Session.Remove(S_USER_ID);
            return RedirectToAction("Login");
        }

        [HttpGet]
        public IActionResult ForgotPassword()
        {
            ViewBag.ShowOtpModal = false;
            ViewBag.ErrorMessage = TempData["ErrorMessage"];
            ViewBag.InfoMessage = TempData["InfoMessage"];
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ForgotPassword(string email)
        {
            email = (email ?? "").Trim().ToLowerInvariant();
            if (string.IsNullOrWhiteSpace(email))
            {
                ViewBag.ErrorMessage = "Vui lòng nhập email";
                ViewBag.ShowOtpModal = false;
                return View();
            }

            var acc = await _db.Accounts.FirstOrDefaultAsync(x => x.Email == email);
            if (acc == null)
            {
                ViewBag.ErrorMessage = "Email chưa được đăng ký";
                ViewBag.ShowOtpModal = false;
                return View();
            }

            var otp = CryptoHelper.GenerateOtp6();
            var (otpHash, otpSalt) = CryptoHelper.HashOtp(otp);
            var expiresAt = DateTime.UtcNow.AddMinutes(3);

            // vô hiệu OTP cũ còn hạn
            var old = await _db.PasswordResetOtps
                .Where(x => x.AccountId == acc.Id && x.UsedAt == null && x.ExpiresAt > DateTime.UtcNow)
                .ToListAsync();
            foreach (var o in old) o.UsedAt = DateTime.UtcNow;

            var req = new PasswordResetOtp
            {
                AccountId = acc.Id,
                OtpHash = otpHash,
                OtpSalt = otpSalt,
                ExpiresAt = expiresAt,
                UsedAt = null,
                AttemptCount = 0,
                CreatedAt = DateTime.UtcNow
            };

            _db.PasswordResetOtps.Add(req);
            await _db.SaveChangesAsync();

            try
            {
                var subject = "Royal Hotel - Mã OTP đặt lại mật khẩu";
                var body = $@"
                <div style='font-family:Arial'>
                  <h2>Royal Luxury Hotel</h2>
                  <p>Mã OTP của anh là: <b style='font-size:20px'>{otp}</b></p>
                  <p>Mã có hiệu lực <b>3 phút</b>.</p>
                </div>";
                await _email.SendAsync(email, subject, body);
            }
            catch (Exception ex)
            {
                ViewBag.ErrorMessage = "Không gửi được OTP. Anh kiểm tra cấu hình SMTP. (" + ex.Message + ")";
                ViewBag.ShowOtpModal = false;
                return View();
            }

            ViewBag.ShowOtpModal = true;
            ViewBag.Email = email;
            ViewBag.RequestId = req.Id.ToString();
            ViewBag.ExpiresAtIso = expiresAt.ToString("o");
            ViewBag.InfoMessage = "OTP đã được gửi đến email. Vui lòng nhập trong 3 phút.";
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ResetPassword(string requestId, string email, string otp, string newPassword, string confirmPassword)
        {
            email = (email ?? "").Trim().ToLowerInvariant();
            otp = (otp ?? "").Trim();
            newPassword = newPassword ?? "";
            confirmPassword = confirmPassword ?? "";

            if (!Guid.TryParse(requestId, out var rid))
            {
                ViewBag.ErrorMessage = "Yêu cầu OTP không hợp lệ";
                return View("ForgotPassword");
            }

            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(otp))
            {
                ViewBag.ErrorMessage = "Vui lòng nhập OTP";
                ViewBag.ShowOtpModal = true;
                ViewBag.Email = email;
                ViewBag.RequestId = requestId;

                // cố gắng lấy lại ExpiresAtIso từ DB theo requestId
                var reqForIso = await _db.PasswordResetOtps.AsNoTracking().FirstOrDefaultAsync(x => x.Id == rid);
                ViewBag.ExpiresAtIso = reqForIso?.ExpiresAt.ToString("o") ?? "";

                return View("ForgotPassword");
            }

            if (newPassword.Length < 6)
            {
                ViewBag.ErrorMessage = "Mật khẩu mới tối thiểu 6 ký tự";
                ViewBag.ShowOtpModal = true;
                ViewBag.Email = email;
                ViewBag.RequestId = requestId;

                // cố gắng lấy lại ExpiresAtIso từ DB theo requestId
                var reqForIso = await _db.PasswordResetOtps.AsNoTracking().FirstOrDefaultAsync(x => x.Id == rid);
                ViewBag.ExpiresAtIso = reqForIso?.ExpiresAt.ToString("o") ?? "";

                return View("ForgotPassword");
            }

            if (newPassword != confirmPassword)
            {
                ViewBag.ErrorMessage = "Mật khẩu xác nhận không khớp";
                ViewBag.ShowOtpModal = true;
                ViewBag.Email = email;
                ViewBag.RequestId = requestId;

                // cố gắng lấy lại ExpiresAtIso từ DB theo requestId
                var reqForIso = await _db.PasswordResetOtps.AsNoTracking().FirstOrDefaultAsync(x => x.Id == rid);
                ViewBag.ExpiresAtIso = reqForIso?.ExpiresAt.ToString("o") ?? "";

                return View("ForgotPassword");
            }

            var req = await _db.PasswordResetOtps
                .Include(x => x.Account)
                .FirstOrDefaultAsync(x => x.Id == rid);

            if (req == null || req.Account == null || req.Account.Email != email)
            {
                ViewBag.ErrorMessage = "OTP không hợp lệ";
                return View("ForgotPassword");
            }

            if (req.UsedAt != null || req.ExpiresAt <= DateTime.UtcNow)
            {
                ViewBag.ErrorMessage = "OTP đã hết hạn. Vui lòng gửi lại OTP.";
                return View("ForgotPassword");
            }

            if (req.AttemptCount >= 5)
            {
                req.UsedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();
                ViewBag.ErrorMessage = "OTP sai quá nhiều lần. Vui lòng gửi lại OTP.";
                return View("ForgotPassword");
            }

            if (!CryptoHelper.VerifyOtp(otp, req.OtpHash, req.OtpSalt))
            {
                req.AttemptCount += 1;
                await _db.SaveChangesAsync();

                ViewBag.ErrorMessage = "OTP không đúng";
                ViewBag.ShowOtpModal = true;
                ViewBag.Email = email;
                ViewBag.RequestId = requestId;
                ViewBag.ExpiresAtIso = req.ExpiresAt.ToString("o");
                return View("ForgotPassword");
            }

            var (hash, salt) = CryptoHelper.HashPassword(newPassword);
            req.Account.PasswordHash = hash;
            req.Account.PasswordSalt = salt;
            req.Account.UpdatedAt = DateTime.UtcNow;

            req.UsedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            TempData["SuccessMessage"] = "Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.";
            return RedirectToAction("Login");
        }
    }
}
