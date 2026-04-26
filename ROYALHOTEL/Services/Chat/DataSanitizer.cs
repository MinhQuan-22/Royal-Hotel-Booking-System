using System.Text.RegularExpressions;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Service for detecting and removing sensitive data patterns from text
/// before sending to external AI providers.
/// Validates: Requirements 17.1 - Prevents sensitive information (password, payment details) from being sent to AI_Provider
/// </summary>
public class DataSanitizer
{
    // Regex patterns for detecting sensitive data
    private static readonly Regex PasswordPattern = new Regex(
        @"\b(password|pass|pwd|mật\s*khẩu)\s*[:=]?\s*\S+",
        RegexOptions.IgnoreCase | RegexOptions.Compiled
    );

    private static readonly Regex CreditCardPattern = new Regex(
        @"\b(?:\d{4}[-\s]?){3}\d{4}\b",
        RegexOptions.Compiled
    );

    private static readonly Regex CvvPattern = new Regex(
        @"\b(cvv|cvc|security\s*code|mã\s*bảo\s*mật)\s*[:=]?\s*\d{3,4}\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled
    );

    /// <summary>
    /// Sanitizes text by removing sensitive data patterns.
    /// Detects and removes: passwords, credit card numbers, CVV codes
    /// </summary>
    /// <param name="text">The text to sanitize</param>
    /// <returns>Sanitized text with sensitive data removed</returns>
    public string Sanitize(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return text;
        }

        var sanitized = text;

        // Remove password patterns
        sanitized = PasswordPattern.Replace(sanitized, "[REDACTED_PASSWORD]");

        // Remove credit card numbers
        sanitized = CreditCardPattern.Replace(sanitized, "[REDACTED_CARD]");

        // Remove CVV codes
        sanitized = CvvPattern.Replace(sanitized, "[REDACTED_CVV]");

        return sanitized;
    }

    /// <summary>
    /// Checks if text contains any sensitive data patterns
    /// </summary>
    /// <param name="text">The text to check</param>
    /// <returns>True if sensitive data is detected, false otherwise</returns>
    public bool ContainsSensitiveData(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        return PasswordPattern.IsMatch(text) ||
               CreditCardPattern.IsMatch(text) ||
               CvvPattern.IsMatch(text);
    }

    /// <summary>
    /// Detects which types of sensitive data are present in the text
    /// </summary>
    /// <param name="text">The text to analyze</param>
    /// <returns>List of detected sensitive data types</returns>
    public List<string> DetectSensitiveDataTypes(string text)
    {
        var types = new List<string>();

        if (string.IsNullOrWhiteSpace(text))
        {
            return types;
        }

        if (PasswordPattern.IsMatch(text))
        {
            types.Add("Password");
        }

        if (CreditCardPattern.IsMatch(text))
        {
            types.Add("CreditCard");
        }

        if (CvvPattern.IsMatch(text))
        {
            types.Add("CVV");
        }

        return types;
    }
}
