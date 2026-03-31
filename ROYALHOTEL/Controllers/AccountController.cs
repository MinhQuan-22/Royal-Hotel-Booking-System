using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Services.Accounts;
using ROYALHOTEL.ViewModels.Account;

namespace ROYALHOTEL.Controllers
{
    public class AccountController : Controller
    {
        private readonly IAuthService _authService;
        private readonly IPasswordResetService _passwordResetService;
        private readonly IUserSessionService _userSessionService;

        public AccountController(
            IAuthService authService,
            IPasswordResetService passwordResetService,
            IUserSessionService userSessionService)
        {
            _authService = authService;
            _passwordResetService = passwordResetService;
            _userSessionService = userSessionService;
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
        public async Task<IActionResult> Login(LoginInputModel input)
        {
            var result = await _authService.LoginAsync(input);
            if (!result.Success || result.Data == null)
            {
                ViewBag.ErrorMessage = result.Message;
                return View();
            }

            _userSessionService.SignIn(result.Data);
            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult Register()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(RegisterInputModel input)
        {
            var result = await _authService.RegisterAsync(input);
            if (!result.Success || result.Data == null)
            {
                ViewBag.ErrorMessage = result.Message;
                return View();
            }

            _userSessionService.SignIn(result.Data);
            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult Logout()
        {
            _userSessionService.SignOut();
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
        public async Task<IActionResult> ForgotPassword(ForgotPasswordInputModel input)
        {
            var result = await _passwordResetService.SendResetOtpAsync(input);
            if (!result.Success)
            {
                ViewBag.ErrorMessage = result.Message;
                ViewBag.ShowOtpModal = false;
                return View();
            }

            ViewBag.ShowOtpModal = true;
            ViewBag.Email = result.Email;
            ViewBag.RequestId = result.RequestId;
            ViewBag.ExpiresAtIso = result.ExpiresAtIso;
            ViewBag.InfoMessage = result.Message;
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ResetPassword(ResetPasswordInputModel input)
        {
            var result = await _passwordResetService.ResetPasswordAsync(input);
            if (result.Success)
            {
                TempData["SuccessMessage"] = result.Message;
                return RedirectToAction("Login");
            }

            ViewBag.ErrorMessage = result.Message;
            ViewBag.ShowOtpModal = true;
            ViewBag.Email = (input.Email ?? "").Trim().ToLowerInvariant();
            ViewBag.RequestId = input.RequestId;
            ViewBag.ExpiresAtIso = await _passwordResetService.GetExpiresAtIsoAsync(input.RequestId);
            return View("ForgotPassword");
        }
    }
}
