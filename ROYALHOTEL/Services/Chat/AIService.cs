using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Service for integrating with OpenAI API for question classification and response generation
/// Implements guardrails to prevent AI from making business decisions
/// Validates: Requirements 16.1, 16.5, 7.1, 7.2, 7.3, 7.4, 7.5
/// </summary>
public class AIService : IAIService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AIService> _logger;
    private const int TimeoutSeconds = 8;
    private const int MaxRetries = 2;

    // In-scope keywords (Vietnamese + English)
    private static readonly string[] InScopeKeywords = new[]
    {
        "tiện ích", "phòng", "giá", "chính sách", "check-in", "check-out", "hủy phòng",
        "wifi", "hồ bơi", "gym", "nhà hàng", "spa", "dịch vụ", "tiện nghi",
        "loại phòng", "so sánh", "khác biệt", "mô tả", "đặt phòng", "thuê phòng",
        "chi phí", "tổng tiền", "bao gồm", "phí", "bữa sáng", "ăn sáng",
        "tien ich", "gia phong", "gia ca", "bao nhieu", "room", "amenities",
        "standard", "deluxe", "suite", "family", "executive", "superior",
        "ho boi", "nha hang", "dat phong", "gia phong", "gia ca"
    };

    // Out-of-scope keywords — questions requiring admin human support
    private static readonly string[] OutOfScopeKeywords = new[]
    {
        // Hoàn tiền & khiếu nại
        "hoàn tiền", "khiếu nại", "phàn nàn", "không hài lòng", "thất vọng",
        "refund", "complaint", "complain", "dissatisfied",

        // Thay đổi & hủy booking cụ thể
        "thay đổi booking", "hủy đặt phòng", "thay đổi đặt phòng", "đổi phòng",
        "gia hạn", "change booking", "modify reservation", "cancel reservation",
        "cancel booking", "reschedule",

        // Tra cứu booking theo mã
        "mã booking", "booking number", "reservation code", "mã đặt phòng",
        "mã xác nhận", "confirmation code", "tình trạng booking",
        "booking của tôi", "đặt phòng của tôi", "xem booking", "kiểm tra booking",

        // Hóa đơn & VAT
        "hóa đơn", "hoa don", "invoice", "vat", "thuế", "xuất hóa đơn",
        "biên lai", "receipt", "chứng từ",

        // Sự cố trong phòng
        "sự cố", "hỏng", "bị hỏng", "không hoạt động", "báo hỏng",
        "điều hòa hỏng", "nước nóng", "điện", "nước", "thiếu",
        "phòng bẩn", "phòng chưa dọn", "report issue", "room problem",
        "maintenance",

        // Loyalty & điểm thưởng
        "điểm thưởng", "loyalty", "reward", "member", "thành viên",
        "tích điểm", "đổi điểm", "ưu đãi thành viên",

        // Nâng hạng phòng
        "nâng hạng", "upgrade", "room upgrade", "đổi lên phòng"
    };

    // Hotel domain cues: if user asks broad hotel questions without exact keywords,
    // still keep it in scope so AI can attempt with database context.
    private static readonly string[] HotelDomainKeywords = new[]
    {
        "khách sạn", "hotel", "royal", "chi nhánh", "cơ sở",
        "phong", "gia", "tien nghi", "room", "price", "amenity"
    };

    // Prohibited patterns for guardrail validation
    private static readonly string[] ProhibitedPatterns = new[]
    {
        "phòng còn trống",
        "hết phòng",
        "booking thành công",
        "đặt phòng thành công",
        "thanh toán thành công",
        "payment completed",
        "available on",
        "rooms available",
        "confirmed booking",
        "payment confirmed"
    };

    public AIService(HttpClient httpClient, IConfiguration configuration, ILogger<AIService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;

        // Configure HttpClient timeout
        _httpClient.Timeout = TimeSpan.FromSeconds(TimeoutSeconds);
    }

    /// <summary>
    /// Classifies a question as in-scope or out-of-scope using keyword matching
    /// Validates: Requirements 3.1, 3.2, 3.3, 3.4
    /// </summary>
    /// <summary>
    /// P3-2: AI-powered classification with keyword fallback.
    /// Uses a fast LLM call with a strict JSON schema to classify the intent.
    /// Falls back to keyword matching if the LLM is unavailable (circuit-breaker pattern).
    /// </summary>
    public async Task<QuestionClassification> ClassifyQuestionAsync(string messageText)
    {
        if (string.IsNullOrWhiteSpace(messageText))
        {
            return new QuestionClassification
            {
                IsInScope = false,
                ConfidenceScore = 0.0,
                Category = "Invalid",
                Reason = "Empty message"
            };
        }

        var apiKey = _configuration["OpenAI:ApiKey"];
        bool aiClassEnabled = !string.IsNullOrWhiteSpace(apiKey)
            && _configuration.GetValue("AI:ClassificationEnabled", true);

        if (aiClassEnabled)
        {
            try
            {
                var result = await ClassifyWithAIAsync(messageText);
                if (result != null)
                {
                    _logger.LogDebug("AI classified message as {Category} (confidence={Confidence})",
                        result.Category, result.ConfidenceScore);
                    return result;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "AI classification failed — falling back to keyword classifier");
            }
        }

        // Fallback: keyword-based classification
        return ClassifyWithKeywords(messageText);
    }

    /// <summary>
    /// P3-2: Calls the LLM with a strict classification prompt.
    /// Returns null if the LLM response cannot be parsed (triggers keyword fallback).
    /// Uses a very short timeout (1.5 s) to avoid slowing down the main response path.
    /// </summary>
    private async Task<QuestionClassification?> ClassifyWithAIAsync(string messageText)
    {
        var apiKey = _configuration["OpenAI:ApiKey"];
        var model = _configuration["OpenAI:Model"] ?? "gpt-4o-mini";
        var endpoint = _configuration["OpenAI:Endpoint"] ?? "https://openrouter.ai/api/v1/chat/completions";

        const string classificationPrompt = @"
Bạn là bộ phân loại câu hỏi cho chatbot khách sạn Royal Hotel.
Phân tích câu hỏi của khách và trả lời CHỈ JSON sau, không giải thích thêm:
{""isInScope"": true/false, ""category"": ""Amenities|Policies|FAQ|Pricing|OutOfScope|Unknown"", ""confidence"": 0.0-1.0, ""reason"": ""ngắn gọn""}

Phân loại IN-SCOPE (AI có thể trả lời):
- Amenities: hỏi về tiện ích phòng, hồ bơi, spa, wifi, gym, nhà hàng, mô tả phòng
- Pricing: hỏi về giá phòng, chi phí, tổng tiền
- Policies: hỏi về chính sách check-in/out, hủy phòng, thanh toán, trẻ em, thú cưng
- FAQ: câu hỏi chung về khách sạn, địa điểm, liên hệ, đặt phòng chung

Phân loại OUT-OF-SCOPE (cần chuyển admin — isInScope=false):
- Tra cứu booking theo mã/số đặt phòng cụ thể
- Yêu cầu hoàn tiền, khiếu nại, phàn nàn
- Thay đổi, hủy, gia hạn booking hiện tại
- Yêu cầu hóa đơn VAT, biên lai
- Báo cáo sự cố trong phòng (hỏng, bẩn, thiếu)
- Điểm thưởng, loyalty, thành viên
- Nâng hạng phòng (room upgrade)

Unknown: không liên quan đến khách sạn";

        var requestBody = new
        {
            model,
            messages = new[]
            {
                new { role = "system", content = classificationPrompt },
                new { role = "user", content = $"Câu hỏi: {messageText}" }
            },
            max_tokens = 120,
            temperature = 0.1,
            response_format = new { type = "json_object" }
        };

        using var cts = new System.Threading.CancellationTokenSource(TimeSpan.FromSeconds(1.5));
        using var request = new HttpRequestMessage(HttpMethod.Post, endpoint);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(
            JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

        var response = await _httpClient.SendAsync(request, cts.Token);
        if (!response.IsSuccessStatusCode) return null;

        var responseBody = await response.Content.ReadAsStringAsync(cts.Token);
        using var doc = JsonDocument.Parse(responseBody);

        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(content)) return null;

        using var classDoc = JsonDocument.Parse(content);
        var root = classDoc.RootElement;

        bool isInScope = root.TryGetProperty("isInScope", out var inScopeEl) && inScopeEl.GetBoolean();
        string category = root.TryGetProperty("category", out var catEl) ? catEl.GetString() ?? "Unknown" : "Unknown";
        double confidence = root.TryGetProperty("confidence", out var confEl) ? confEl.GetDouble() : 0.5;
        string reason = root.TryGetProperty("reason", out var reasonEl) ? reasonEl.GetString() ?? "AI classification" : "AI classification";

        // Apply confidence threshold
        if (confidence < 0.6)
        {
            isInScope = false;
            category = "LowConfidence";
        }

        return new QuestionClassification
        {
            IsInScope = isInScope,
            ConfidenceScore = confidence,
            Category = category,
            Reason = $"[AI] {reason}"
        };
    }

    /// <summary>
    /// P3-2: Original keyword-based classification preserved as fallback.
    /// </summary>
    private QuestionClassification ClassifyWithKeywords(string messageText)
    {
        var lowerText = messageText.ToLower();

        // Check for out-of-scope keywords first (higher priority)
        var outOfScopeMatches = OutOfScopeKeywords.Count(keyword => lowerText.Contains(keyword.ToLower()));
        if (outOfScopeMatches > 0)
        {
            return new QuestionClassification
            {
                IsInScope = false,
                ConfidenceScore = 0.9,
                Category = "OutOfScope",
                Reason = $"[Keyword] Contains out-of-scope keywords: {string.Join(", ", OutOfScopeKeywords.Where(k => lowerText.Contains(k.ToLower())))}"
            };
        }

        // Check for in-scope keywords
        var inScopeMatches = InScopeKeywords.Count(keyword => lowerText.Contains(keyword.ToLower()));
        if (inScopeMatches > 0)
        {
            var confidenceScore = Math.Min(0.7 + (inScopeMatches * 0.1), 1.0);
            var category = DetermineCategory(lowerText);

            var classification = new QuestionClassification
            {
                IsInScope = true,
                ConfidenceScore = confidenceScore,
                Category = category,
                Reason = $"[Keyword] Contains in-scope keywords: {string.Join(", ", InScopeKeywords.Where(k => lowerText.Contains(k.ToLower())))}"
            };

            if (classification.ConfidenceScore < 0.7)
            {
                classification.IsInScope = false;
                classification.Category = "LowConfidence";
                classification.Reason += " (Confidence below threshold)";
            }

            return classification;
        }

        // Broad hotel-domain fallback
        var domainMatches = HotelDomainKeywords.Count(keyword => lowerText.Contains(keyword));
        if (domainMatches > 0)
        {
            return new QuestionClassification
            {
                IsInScope = true,
                ConfidenceScore = 0.75,
                Category = DetermineCategory(lowerText),
                Reason = "[Keyword] Matched broad hotel-domain keywords"
            };
        }

        // No useful match
        return new QuestionClassification
        {
            IsInScope = false,
            ConfidenceScore = 0.3,
            Category = "Unknown",
            Reason = "[Keyword] No matching hotel-domain keywords found"
        };
    }

    /// <summary>
    /// Generates an AI response using OpenAI API with guardrails
    /// Validates: Requirements 7.1, 7.2, 7.3, 7.4, 16.1, 16.2, 16.3, 16.4
    /// Sub-task 9.2: Comprehensive error handling with timeout and retry logic
    /// Validates: Requirements 16.2, 16.3, 16.4
    /// </summary>
    public async Task<string> GenerateResponseAsync(
        string messageText,
        string contextData,
        string category,
        IEnumerable<ConversationHistoryMessage>? conversationHistory = null)
    {
        var apiKey = _configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogError("OpenAI API key not configured");
            throw new InvalidOperationException("OpenAI API key not configured");
        }

        var systemPrompt = GetGuardrailPrompt(category);

        // P2-Context: Build multi-turn message array with conversation history
        var messages = BuildMessagesWithHistory(systemPrompt, messageText, contextData, conversationHistory);

        var requestBody = new
        {
            model = _configuration["OpenAI:Model"] ?? "gpt-4o-mini",
            messages,
            temperature = 0.7,
            max_tokens = 600
        };

        var jsonContent = JsonSerializer.Serialize(requestBody);

        // Implement retry logic with exponential backoff
        int attempt = 0;
        Exception? lastException = null;
        var requestStartTime = DateTime.UtcNow;

        while (attempt <= MaxRetries)
        {
            try
            {
                _logger.LogInformation(
                    "Calling OpenAI API (attempt {Attempt}/{MaxAttempts}). Model={Model}, Timeout={TimeoutSeconds}s",
                    attempt + 1, MaxRetries + 1, requestBody.model, TimeoutSeconds);

                var request = new HttpRequestMessage(HttpMethod.Post, "https://openrouter.ai/api/v1/chat/completions");
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                request.Headers.Add("HTTP-Referer", "http://localhost:5033"); // Optional but recommended for OpenRouter
                request.Headers.Add("X-Title", "Royal Hotel AI Assistant");
                request.Content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.SendAsync(request);

                // Requirement 16.4: Handle HTTP 429 rate limit errors without retry
                if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
                {
                    _logger.LogError(
                        "OpenAI API rate limit exceeded (HTTP 429). Attempt={Attempt}, RequestTime={RequestTimeMs}ms",
                        attempt + 1, (DateTime.UtcNow - requestStartTime).TotalMilliseconds);

                    throw new HttpRequestException("OpenAI API rate limit exceeded (HTTP 429). Please try again later.");
                }

                // Handle billing/quota issues explicitly (OpenRouter HTTP 402)
                if ((int)response.StatusCode == 402)
                {
                    _logger.LogWarning(
                        "OpenAI provider billing/quota issue (HTTP 402). Attempt={Attempt}, RequestTime={RequestTimeMs}ms",
                        attempt + 1, (DateTime.UtcNow - requestStartTime).TotalMilliseconds);

                    throw new HttpRequestException("OpenAI provider returned HTTP 402 Payment Required (insufficient credits/quota).");
                }

                // Requirement 16.3: Check for 5xx errors (server errors) - retry these
                if ((int)response.StatusCode >= 500 && (int)response.StatusCode < 600)
                {
                    lastException = new HttpRequestException($"OpenAI API returned {response.StatusCode}");
                    
                    _logger.LogWarning(
                        "OpenAI API returned {StatusCode}. Attempt={Attempt}/{MaxAttempts}, RequestTime={RequestTimeMs}ms",
                        response.StatusCode, attempt + 1, MaxRetries + 1, (DateTime.UtcNow - requestStartTime).TotalMilliseconds);

                    if (attempt < MaxRetries)
                    {
                        // Exponential backoff: 1s, 2s
                        var delaySeconds = Math.Pow(2, attempt);
                        _logger.LogInformation("Retrying after {DelaySeconds}s delay", delaySeconds);
                        await Task.Delay(TimeSpan.FromSeconds(delaySeconds));
                        attempt++;
                        requestStartTime = DateTime.UtcNow; // Reset timer for retry
                        continue;
                    }
                }

                // For other errors (4xx, etc.), don't retry
                response.EnsureSuccessStatusCode();

                var responseContent = await response.Content.ReadAsStringAsync();
                var responseJson = JsonDocument.Parse(responseContent);

                var generatedText = responseJson.RootElement
                    .GetProperty("choices")[0]
                    .GetProperty("message")
                    .GetProperty("content")
                    .GetString() ?? "";

                var totalRequestTime = (DateTime.UtcNow - requestStartTime).TotalMilliseconds;

                _logger.LogInformation(
                    "OpenAI API call successful. Attempt={Attempt}, ResponseTime={ResponseTimeMs}ms, ResponseLength={ResponseLength}",
                    attempt + 1, totalRequestTime, generatedText.Length);

                return generatedText;
            }
            catch (TaskCanceledException ex)
            {
                // Requirement 16.2: Implement timeout handling (8 seconds)
                var elapsedTime = (DateTime.UtcNow - requestStartTime).TotalSeconds;
                
                _logger.LogError(ex, 
                    "OpenAI API request timed out. Attempt={Attempt}, Timeout={TimeoutSeconds}s, ElapsedTime={ElapsedSeconds}s",
                    attempt + 1, TimeoutSeconds, elapsedTime);

                throw new TimeoutException($"OpenAI API request timed out after {TimeoutSeconds} seconds", ex);
            }
            catch (HttpRequestException ex) when (ex.Message.Contains("429"))
            {
                // HTTP 429 - don't retry, throw immediately
                throw;
            }
            catch (HttpRequestException ex) when (ex.Message.Contains("402") || ex.Message.Contains("Payment Required", StringComparison.OrdinalIgnoreCase))
            {
                // HTTP 402 - no retry, handled upstream by DB fallback path
                throw;
            }
            catch (HttpRequestException ex) when ((int?)((ex.InnerException as HttpRequestException)?.StatusCode) >= 500)
            {
                lastException = ex;
                if (attempt < MaxRetries)
                {
                    var delaySeconds = Math.Pow(2, attempt);
                    _logger.LogInformation("Retrying after {DelaySeconds}s delay due to server error", delaySeconds);
                    await Task.Delay(TimeSpan.FromSeconds(delaySeconds));
                    attempt++;
                    requestStartTime = DateTime.UtcNow; // Reset timer for retry
                    continue;
                }
            }
            catch (Exception ex)
            {
                var elapsedTime = (DateTime.UtcNow - requestStartTime).TotalMilliseconds;
                
                _logger.LogError(ex, 
                    "Unexpected error calling OpenAI API. Attempt={Attempt}, ElapsedTime={ElapsedTimeMs}ms, ErrorType={ErrorType}",
                    attempt + 1, elapsedTime, ex.GetType().Name);
                
                throw;
            }
        }

        // All retries exhausted
        var totalElapsedTime = (DateTime.UtcNow - requestStartTime).TotalMilliseconds;
        
        _logger.LogError(lastException, 
            "OpenAI API call failed after {MaxRetries} retries. TotalElapsedTime={ElapsedTimeMs}ms",
            MaxRetries, totalElapsedTime);
        
        throw lastException ?? new HttpRequestException("OpenAI API call failed after all retries");
    }

    /// <summary>
    /// Validates an AI response against guardrail rules
    /// Validates: Requirements 7.5
    /// </summary>
    public async Task<ValidationResult> ValidateResponseAsync(string response)
    {
        var result = new ValidationResult { IsValid = true };

        if (string.IsNullOrWhiteSpace(response))
        {
            result.IsValid = false;
            result.Violations.Add("Response is empty");
            return result;
        }

        var lowerResponse = response.ToLower();

        // Check for prohibited patterns
        foreach (var pattern in ProhibitedPatterns)
        {
            if (lowerResponse.Contains(pattern.ToLower()))
            {
                result.IsValid = false;
                result.Violations.Add($"Contains prohibited pattern: '{pattern}'");
                _logger.LogWarning("AI response validation failed: contains prohibited pattern '{Pattern}'", pattern);
            }
        }

        return await Task.FromResult(result);
    }

    /// <summary>
    /// Gets the guardrail system prompt for OpenAI
    /// Validates: Requirements 7.1, 7.2, 7.3, 7.4
    /// </summary>
    private string GetGuardrailPrompt(string category)
    {
        return @"Bạn là trợ lý ảo của Royal Hotel. Nhiệm vụ của bạn là diễn giải dữ liệu và trả lời câu hỏi của khách hàng.

QUAN TRỌNG - CÁC RÀNG BUỘC:
1. KHÔNG BAO GIỜ khẳng định phòng còn trống hoặc hết phòng theo ngày cụ thể
2. KHÔNG BAO GIỜ xác nhận booking đã thành công
3. KHÔNG BAO GIỜ xác nhận thanh toán đã thành công
4. CHỈ diễn giải dữ liệu được cung cấp trong context
5. Nếu thiếu dữ liệu, nói rõ và đề nghị liên hệ admin

Dữ liệu bạn có thể diễn giải:
- Tiện ích khách sạn và mô tả phòng
- Chính sách check-in/check-out
- Chính sách hủy phòng
- So sánh các loại phòng
- Giải thích kết quả tìm kiếm

Trả lời bằng tiếng Việt, ngắn gọn, thân thiện.
Nếu câu hỏi nằm ngoài phạm vi dữ liệu bạn có, hãy lịch sự từ chối và đề nghị khách liên hệ admin.";
    }

    /// <summary>
    /// Builds the user prompt combining context data and user message
    /// </summary>
    private string BuildUserPrompt(string messageText, string contextData)
    {
        if (string.IsNullOrWhiteSpace(contextData))
        {
            return $"Câu hỏi: {messageText}";
        }

        return $@"Context: {contextData}

Câu hỏi: {messageText}";
    }

    /// <summary>
    /// P2-Context: Builds an OpenAI messages array with:
    ///   [0] system prompt
    ///   [1..N-1] conversation history (user/assistant turns, max 10 messages)
    ///   [N] current user message with database context
    /// This gives the AI awareness of prior turns so it can answer coherently.
    /// </summary>
    private object[] BuildMessagesWithHistory(
        string systemPrompt,
        string messageText,
        string contextData,
        IEnumerable<ConversationHistoryMessage>? conversationHistory)
    {
        var messageList = new List<object>
        {
            new { role = "system", content = systemPrompt }
        };

        // Add up to 10 most recent messages from history (skip current message)
        if (conversationHistory != null)
        {
            var historyItems = conversationHistory
                .OrderBy(m => m.CreatedAt)
                .Take(10)
                .ToList();

            foreach (var msg in historyItems)
            {
                var role = msg.SenderType switch
                {
                    "User" => "user",
                    "AI" => "assistant",
                    "Admin" => "assistant", // Admin replies appear as assistant in AI context
                    _ => "user"
                };

                // Truncate long history messages to keep token count manageable
                var truncated = msg.MessageText.Length > 500
                    ? msg.MessageText[..500] + "..."
                    : msg.MessageText;

                messageList.Add(new { role, content = truncated });
            }
        }

        // Add current user message with database context
        var userPrompt = BuildUserPrompt(messageText, contextData);
        messageList.Add(new { role = "user", content = userPrompt });

        return messageList.ToArray();
    }

    /// <summary>
    /// Determines the question category based on keywords
    /// </summary>
    private string DetermineCategory(string lowerText)
    {
        if (lowerText.Contains("tiện ích") || lowerText.Contains("wifi") || 
            lowerText.Contains("hồ bơi") || lowerText.Contains("gym") || 
            lowerText.Contains("nhà hàng") || lowerText.Contains("spa"))
        {
            return "HotelAmenities";
        }

        if (lowerText.Contains("phòng") || lowerText.Contains("phong") ||
            lowerText.Contains("loại phòng") || lowerText.Contains("loai phong") ||
            lowerText.Contains("so sánh") || lowerText.Contains("so sanh") ||
            lowerText.Contains("mô tả") || lowerText.Contains("mo ta") ||
            lowerText.Contains("room"))
        {
            return "RoomDescription";
        }

        if (lowerText.Contains("chính sách") || lowerText.Contains("hủy phòng") || 
            lowerText.Contains("check-in") || lowerText.Contains("check-out"))
        {
            return "Policies";
        }

        if (lowerText.Contains("giá") || lowerText.Contains("gia") ||
            lowerText.Contains("bao nhieu") || lowerText.Contains("price") || lowerText.Contains("cost"))
        {
            return "Pricing";
        }

        return "General";
    }
}
