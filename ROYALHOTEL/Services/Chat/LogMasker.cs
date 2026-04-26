using System.Text.RegularExpressions;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Service for masking personally identifiable information (PII) in logs.
/// Validates: Requirements 17.2 - Masks email addresses and phone numbers in logs
/// </summary>
public class LogMasker
{
    // Regex patterns for detecting PII
    private static readonly Regex EmailPattern = new Regex(
        @"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
        RegexOptions.Compiled
    );

    private static readonly Regex PhonePattern = new Regex(
        @"\b(?:\+?84|0)(?:\d{9,10})\b|(?:\d{3}[-.\s]?\d{3}[-.\s]?\d{4})\b",
        RegexOptions.Compiled
    );

    /// <summary>
    /// Masks PII in text for logging purposes.
    /// Email addresses are masked as: ***@***.***
    /// Phone numbers are masked as: ***-***-****
    /// </summary>
    /// <param name="text">The text to mask</param>
    /// <returns>Masked text with PII replaced</returns>
    public string Mask(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return text;
        }

        var masked = text;

        // Mask email addresses
        masked = EmailPattern.Replace(masked, "***@***.***");

        // Mask phone numbers
        masked = PhonePattern.Replace(masked, "***-***-****");

        return masked;
    }

    /// <summary>
    /// Checks if text contains any PII that should be masked
    /// </summary>
    /// <param name="text">The text to check</param>
    /// <returns>True if PII is detected, false otherwise</returns>
    public bool ContainsPII(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        return EmailPattern.IsMatch(text) || PhonePattern.IsMatch(text);
    }

    /// <summary>
    /// Alias for ContainsPII to match test expectations
    /// </summary>
    public bool ContainsSensitiveInfo(string text) => ContainsPII(text);
}
