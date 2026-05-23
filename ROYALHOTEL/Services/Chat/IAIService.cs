namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Interface for AI service that integrates with OpenAI API
/// Provides question classification, response generation, and validation
/// Validates: Requirements 16.1, 16.5
/// </summary>
public interface IAIService
{
    /// <summary>
    /// Classifies a question as in-scope or out-of-scope
    /// </summary>
    /// <param name="messageText">The user's question text</param>
    /// <returns>Classification result with IsInScope, ConfidenceScore, Category, and Reason</returns>
    Task<QuestionClassification> ClassifyQuestionAsync(string messageText);

    /// <summary>
    /// Generates an AI response using OpenAI API with guardrails.
    /// P2-Context: Accepts optional conversation history for context-aware replies.
    /// </summary>
    /// <param name="messageText">The user's question text</param>
    /// <param name="contextData">Relevant context data from database</param>
    /// <param name="category">Question category (HotelAmenities, Policies, etc.)</param>
    /// <param name="conversationHistory">Optional: recent messages for context window (max 10)</param>
    /// <returns>Generated response text</returns>
    Task<string> GenerateResponseAsync(
        string messageText,
        string contextData,
        string category,
        IEnumerable<ConversationHistoryMessage>? conversationHistory = null);

    /// <summary>
    /// Validates an AI response against guardrail rules
    /// </summary>
    /// <param name="response">The AI-generated response to validate</param>
    /// <returns>Validation result with IsValid flag and violation details</returns>
    Task<ValidationResult> ValidateResponseAsync(string response);
}

/// <summary>
/// Result of question classification
/// </summary>
public class QuestionClassification
{
    public bool IsInScope { get; set; }
    public double ConfidenceScore { get; set; }
    public string Category { get; set; } = "";
    public string Reason { get; set; } = "";
}

/// <summary>
/// Result of response validation
/// </summary>
public class ValidationResult
{
    public bool IsValid { get; set; }
    public List<string> Violations { get; set; } = new List<string>();
}

/// <summary>
/// Represents a single message in conversation history for AI context window
/// </summary>
public class ConversationHistoryMessage
{
    public string SenderType { get; set; } = ""; // "User", "AI", "Admin"
    public string MessageText { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}
