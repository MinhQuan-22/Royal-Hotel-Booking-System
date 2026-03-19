using System.Security.Cryptography;
using System.Text;

namespace ROYALHOTEL.Security
{
    public static class CryptoHelper
    {
        public static (string hash, string salt) HashPassword(string password)
        {
            var saltBytes = RandomNumberGenerator.GetBytes(16);
            var hashBytes = Rfc2898DeriveBytes.Pbkdf2(
                Encoding.UTF8.GetBytes(password),
                saltBytes,
                iterations: 100_000,
                hashAlgorithm: HashAlgorithmName.SHA256,
                outputLength: 32
            );

            return (Convert.ToBase64String(hashBytes), Convert.ToBase64String(saltBytes));
        }

        public static bool VerifyPassword(string password, string storedHash, string storedSalt)
        {
            var saltBytes = Convert.FromBase64String(storedSalt);
            var hashBytes = Rfc2898DeriveBytes.Pbkdf2(
                Encoding.UTF8.GetBytes(password),
                saltBytes,
                iterations: 100_000,
                hashAlgorithm: HashAlgorithmName.SHA256,
                outputLength: 32
            );

            var storedHashBytes = Convert.FromBase64String(storedHash);
            return CryptographicOperations.FixedTimeEquals(hashBytes, storedHashBytes);
        }

        public static string GenerateOtp6()
        {
            var n = RandomNumberGenerator.GetInt32(0, 1_000_000);
            return n.ToString("D6");
        }

        public static (string hash, string salt) HashOtp(string otp)
        {
            var saltBytes = RandomNumberGenerator.GetBytes(16);
            using var sha = SHA256.Create();
            var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(otp + Convert.ToBase64String(saltBytes)));
            return (Convert.ToBase64String(bytes), Convert.ToBase64String(saltBytes));
        }

        public static bool VerifyOtp(string otp, string otpHash, string otpSalt)
        {
            using var sha = SHA256.Create();
            var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(otp + otpSalt));

            var storedHashBytes = Convert.FromBase64String(otpHash);
            return CryptographicOperations.FixedTimeEquals(bytes, storedHashBytes);
        }
    }
}
