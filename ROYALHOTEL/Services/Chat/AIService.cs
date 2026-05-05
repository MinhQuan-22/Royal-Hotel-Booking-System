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

    // In-scope keywords (Vietnamese)
    private static readonly string[] InScopeKeywords = new[]
    {
        "tiện ích", "phòng", "giá", "chính sách", "check-in", "check-out", "hủy phòng",
        "wifi", "hồ bơi", "gym", "nhà hàng", "spa", "dịch vụ", "tiện nghi",
        "loại phòng", "so sánh", "khác biệt", "mô tả",
        "tien ich", "gia phong", "gia ca", "bao nhieu", "room", "amenities",
        "standard", "deluxe", "suite"
    };

    // Out-of-scope keywords (Vietnamese)
    private static readonly string[] OutOfScopeKeywords = new[]
    {
        "hoàn tiền", "khiếu nại", "thay đổi booking", "hủy đặt phòng",
        "refund", "complaint", "change booking", "modify reservation"
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
    public Task<QuestionClassification> ClassifyQuestionAsync(string messageText)
    {
        if (string.IsNullOrWhiteSpace(messageText))
        {
            return Task.FromResult(new QuestionClassification
            {
                IsInScope = false,
                ConfidenceScore = 0.0,
                Category = "Invalid",
                Reason = "Empty message"
            });
        }

        var lowerText = messageText.ToLower();

        // Check for out-of-scope keywords first (higher priority)
        var outOfScopeMatches = OutOfScopeKeywords.Count(keyword => lowerText.Contains(keyword.ToLower()));
        if (outOfScopeMatches > 0)
        {
            return Task.FromResult(new QuestionClassification
            {
                IsInScope = false,
                ConfidenceScore = 0.9,
                Category = "OutOfScope",
                Reason = $"Contains out-of-scope keywords: {string.Join(", ", OutOfScopeKeywords.Where(k => lowerText.Contains(k.ToLower())))}"
            });
        }

        // Check for in-scope keywords
        var inScopeMatches = InScopeKeywords.Count(keyword => lowerText.Contains(keyword.ToLower()));
        if (inScopeMatches > 0)
        {
            // Calculate confidence score based on keyword matches
            var confidenceScore = Math.Min(0.7 + (inScopeMatches * 0.1), 1.0);

            // Determine category based on keywords
            var category = DetermineCategory(lowerText);

            var classification = new QuestionClassification
            {
                IsInScope = true,
                ConfidenceScore = confidenceScore,
                Category = category,
                Reason = $"Contains in-scope keywords: {string.Join(", ", InScopeKeywords.Where(k => lowerText.Contains(k.ToLower())))}"
            };

            // Apply confidence threshold rule (Requirement 3.4)
            if (classification.ConfidenceScore < 0.7)
            {
                classification.IsInScope = false;
                classification.Category = "LowConfidence";
                classification.Reason += " (Confidence below threshold)";
            }

            return Task.FromResult(classification);
        }

        // Broad hotel-domain fallback:
        // keep in-scope and let LLM decide from retrieved context.
        var domainMatches = HotelDomainKeywords.Count(keyword => lowerText.Contains(keyword));
        if (domainMatches > 0)
        {
            return Task.FromResult(new QuestionClassification
            {
                IsInScope = true,
                ConfidenceScore = 0.75,
                Category = DetermineCategory(lowerText),
                Reason = "Matched broad hotel-domain keywords"
            });
        }

        // No useful match: treat as out-of-scope
        return Task.FromResult(new QuestionClassification
        {
            IsInScope = false,
            ConfidenceScore = 0.3,
            Category = "Unknown",
            Reason = "No matching hotel-domain keywords found"
        });
    }

    /// <summary>
    /// Generates an AI response using OpenAI API with guardrails
    /// Validates: Requirements 7.1, 7.2, 7.3, 7.4, 16.1, 16.2, 16.3, 16.4
    /// Sub-task 9.2: Comprehensive error handling with timeout and retry logic
    /// Validates: Requirements 16.2, 16.3, 16.4
    /// </summary>
    public async Task<string> GenerateResponseAsync(string messageText, string contextData, string category)
    {
        var apiKey = _configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogError("OpenAI API key not configured");
            throw new InvalidOperationException("OpenAI API key not configured");
        }

        var systemPrompt = GetGuardrailPrompt(category);
        var userPrompt = BuildUserPrompt(messageText, contextData);

        var requestBody = new
        {
            model = _configuration["OpenAI:Model"] ?? "gpt-4",
            messages = new[]
            {
                new { role = "system", content = systemPrompt },
                new { role = "user", content = userPrompt }
            },
            temperature = 0.7,
            max_tokens = 500
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
