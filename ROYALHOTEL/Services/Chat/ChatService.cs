using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using MongoDB.Driver;
using ROYALHOTEL.Data;
using ROYALHOTEL.DTOs;
using ROYALHOTEL.Hubs;
using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Email;
using System.Globalization;
using System.Text;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Service for managing chat conversations and orchestrating AI interactions
/// Validates: Requirements 2.4, 2.5, 3.1, 3.5, 4.5, 5.5, 6.5, 7.5, 8.1, 8.4, 8.5, 9.1, 20.2, 20.4, 1.3, 17.4, 15.3
/// </summary>
public class ChatService : IChatService
{
    private readonly RoyalHotelDbContext _dbContext;
    private readonly MongoDbContext _mongoContext;
    private readonly IAIService _aiService;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ChatService> _logger;
    private readonly ConversationCodeGenerator _codeGenerator;
    private readonly LogMasker _logMasker;
    private readonly DataSanitizer _dataSanitizer;
    private readonly IEmailSender _emailSender;
    private readonly SmtpSettings _smtpSettings;
    private readonly ChatHubNotifier _hubNotifier;

    // Cache keys and TTLs
    private const string FAQ_CACHE_KEY_PREFIX = "faq_";
    private const int FAQ_CACHE_TTL_MINUTES = 60;
    private const string HOTEL_AMENITIES_CACHE_KEY_PREFIX = "hotel_amenities_";
    private const int HOTEL_AMENITIES_CACHE_TTL_MINUTES = 30;

    public ChatService(
        RoyalHotelDbContext dbContext,
        MongoDbContext mongoContext,
        IAIService aiService,
        IMemoryCache cache,
        ILogger<ChatService> logger,
        ConversationCodeGenerator codeGenerator,
        LogMasker logMasker,
        DataSanitizer dataSanitizer,
        IEmailSender emailSender,
        IOptions<SmtpSettings> smtpSettings,
        ChatHubNotifier hubNotifier)
    {
        _dbContext = dbContext;
        _mongoContext = mongoContext;
        _aiService = aiService;
        _cache = cache;
        _logger = logger;
        _codeGenerator = codeGenerator;
        _logMasker = logMasker;
        _dataSanitizer = dataSanitizer;
        _emailSender = emailSender;
        _smtpSettings = smtpSettings.Value;
        _hubNotifier = hubNotifier;
    }

    /// <summary>
    /// Sub-task 4.3: Main orchestration method for processing questions
    /// Validates: Requirements 2.4, 2.5, 3.1, 3.5, 4.5, 5.5, 6.5, 7.5, 8.1
    /// Sub-task 9.1: Comprehensive error handling with structured logging
    /// Validates: Requirements 18.1, 18.2, 18.3, 18.5, 13.1, 13.2, 13.3, 13.4, 13.5, 17.2
    /// </summary>
    public async Task<ChatResponse> ProcessQuestionAsync(SendMessageRequest request, int? userId)
    {
        var startTime = DateTime.UtcNow;
        int conversationId = 0;

        try
        {
            // Sub-task 4.2: Get or create conversation
            ChatConversation conversation;
            try
            {
                conversation = await GetOrCreateConversationAsync(request, userId);
                conversationId = conversation.Id;
            }
            catch (Exception ex)
            {
                // Requirement 18.2: SQL Server unavailable
                _logger.LogError(ex, 
                    "SQL Server error creating/retrieving conversation. UserId={UserId}, MessageText={MaskedMessage}",
                    userId, _logMasker.Mask(request.MessageText));

                return new ChatResponse
                {
                    ConversationId = 0,
                    ResponseText = "Hệ thống đang bảo trì, vui lòng thử lại sau.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            // If admin ended the session earlier, switch conversation back to AI mode
            // while preserving the same conversation history/thread.
            if (conversation.Status == "Closed")
            {
                conversation.Status = "Open";
                conversation.EscalatedAt = null; // Reset escalation timestamp - this is a new AI session
                conversation.UpdatedAt = DateTime.UtcNow;
                await _dbContext.SaveChangesAsync();

                _logger.LogInformation(
                    "Conversation {ConversationId} reopened in AI mode after admin closure. EscalatedAt reset to null.",
                    conversation.Id);
            }

            // Save user message
            try
            {
                var userMessage = new ChatMessage
                {
                    ConversationId = conversation.Id,
                    SenderType = "User",
                    MessageText = request.MessageText,
                    IsEscalationMessage = false,
                    CreatedAt = DateTime.UtcNow
                };

                _dbContext.ChatMessages.Add(userMessage);
                await _dbContext.SaveChangesAsync();

                // Requirement 13.1: Log each question with masked sensitive data
                _logger.LogInformation(
                    "User message saved. ConversationId={ConversationId}, MessageText={MaskedMessage}, Timestamp={Timestamp}",
                    conversation.Id, _logMasker.Mask(request.MessageText), DateTime.UtcNow);
            }
            catch (Exception ex)
            {
                // Requirement 18.2: SQL Server error saving message
                _logger.LogError(ex, 
                    "SQL Server error saving user message. ConversationId={ConversationId}",
                    conversation.Id);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Hệ thống đang bảo trì, vui lòng thử lại sau.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            // Do not trigger AI while conversation is being handled by Admin.
            var isHandledByAdmin = conversation.Status == "EscalatedToAdmin"
                || conversation.Status == "AnsweredByAdmin";
            if (isHandledByAdmin)
            {
                _logger.LogInformation(
                    "Skipping AI response because conversation {ConversationId} is being handled by admin with status {Status}",
                    conversation.Id,
                    conversation.Status);
                
                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "", // Empty response means AI won't say anything
                    ShowContactAdmin = false,
                    Timestamp = DateTime.UtcNow
                };
            }

            // P4-RateLimit: Per-conversation cooldown — max 1 message per 3 seconds
            var cooldownKey = $"chat:cooldown:{conversation.Id}";
            if (_cache.TryGetValue(cooldownKey, out _))
            {
                _logger.LogWarning(
                    "Conversation {ConversationId} cooldown active — message sent too quickly",
                    conversation.Id);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Bạn đang gửi tin nhắn quá nhanh. Vui lòng chờ vài giây trước khi tiếp tục.",
                    ShowContactAdmin = false,
                    Timestamp = DateTime.UtcNow
                };
            }

            // Set cooldown: 3 seconds before next message is processed
            _cache.Set(cooldownKey, true, TimeSpan.FromSeconds(3));

            // P4-RateLimit: Per-conversation message count limit — max 50 user messages
            var messageCountKey = $"chat:msgcount:{conversation.Id}";
            if (!_cache.TryGetValue(messageCountKey, out int userMessageCount))
            {
                // Count from DB on first check (cold cache)
                userMessageCount = await _dbContext.ChatMessages
                    .CountAsync(m => m.ConversationId == conversation.Id && m.SenderType == "User");
                _cache.Set(messageCountKey, userMessageCount, TimeSpan.FromMinutes(30));
            }

            if (userMessageCount >= 50)
            {
                _logger.LogWarning(
                    "Conversation {ConversationId} exceeded max message limit ({Count}/50)",
                    conversation.Id, userMessageCount);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Cuộc hội thoại này đã đạt giới hạn 50 tin nhắn. " +
                                   "Bạn có thể bắt đầu cuộc hội thoại mới hoặc liên hệ admin để được hỗ trợ tiếp tục.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            // Increment cached message counter (will be refreshed from DB on next cold start)
            _cache.Set(messageCountKey, userMessageCount + 1, TimeSpan.FromMinutes(30));


            // Classify question
            QuestionClassification classification;
            try
            {
                classification = await _aiService.ClassifyQuestionAsync(request.MessageText);

                // Requirement 13.1: Log classification with confidence score
                _logger.LogInformation(
                    "Question classified. ConversationId={ConversationId}, IsInScope={IsInScope}, Category={Category}, ConfidenceScore={ConfidenceScore}, Timestamp={Timestamp}",
                    conversation.Id, classification.IsInScope, classification.Category, classification.ConfidenceScore, DateTime.UtcNow);
            }
            catch (Exception ex)
            {
                // Requirement 18.3: AI service error during classification
                _logger.LogError(ex, 
                    "AI service error during classification. ConversationId={ConversationId}",
                    conversation.Id);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Không thể xử lý câu hỏi, vui lòng liên hệ admin.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            // Handle out-of-scope questions
            if (!classification.IsInScope)
            {
                // P3: Generate a more specific escalation message based on category
                var escalationMessage = classification.Category switch
                {
                    "OutOfScope" when classification.Reason.Contains("booking") ||
                                     classification.Reason.Contains("reservation") =>
                        "🛨 Câu hỏi của bạn liên quan đến thông tin đặt phòng cụ thể. " +
                        "Vui lòng liên hệ với admin để được hỗ trợ tra cứu booking của bạn.",

                    "OutOfScope" when classification.Reason.Contains("hóa đơn") ||
                                     classification.Reason.Contains("invoice") ||
                                     classification.Reason.Contains("vat") =>
                        "🗂️ Yêu cầu xuất hóa đơn/biên lai cần được admin xử lý trực tiếp. " +
                        "Vui lòng liên hệ để được hỗ trợ.",

                    "OutOfScope" when classification.Reason.Contains("sự cố") ||
                                     classification.Reason.Contains("hỏng") ||
                                     classification.Reason.Contains("maintenance") =>
                        "🔧 Báo cáo sự cố cần được kỹ thuật viên xử lý. " +
                        "Admin sẽ liên hệ để hỗ trợ bạn ngay.",

                    "OutOfScope" when classification.Reason.Contains("loyalty") ||
                                     classification.Reason.Contains("điểm") ||
                                     classification.Reason.Contains("upgrade") =>
                        "🏆 Yêu cầu về chương trình thành viên/nâng hạng cần admin xử lý trực tiếp. " +
                        "Vui lòng liên hệ để được hướng dẫn.",

                    _ =>
                        "Xin lỗi, câu hỏi của bạn nằm ngoài phạm vi hỗ trợ tự động của tôi. " +
                        "Vui lòng liên hệ với admin để được hỗ trợ tốt hơn."
                };

                // Requirement 13.3: Log escalation
                _logger.LogInformation(
                    "Out-of-scope question detected. ConversationId={ConversationId}, Category={Category}, Reason={Reason}, Timestamp={Timestamp}",
                    conversation.Id, classification.Category, classification.Reason, DateTime.UtcNow);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = escalationMessage,
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            // Sub-task 4.4: Get context data for in-scope questions
            string contextData;
            try
            {
                contextData = await GetContextDataAsync(classification.Category, request.MessageText);
            }
            catch (Exception ex)
            {
                // Requirement 18.1: MongoDB unavailable or Requirement 18.2: SQL Server unavailable
                var errorSource = ex.Message.Contains("MongoDB") ? "MongoDB" : "SQL Server";
                _logger.LogError(ex, 
                    "{ErrorSource} error retrieving context data. ConversationId={ConversationId}, Category={Category}",
                    errorSource, conversation.Id, classification.Category);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Hệ thống đang bảo trì, vui lòng thử lại sau.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            // Generate AI response
            string aiResponseText;
            var aiStartTime = DateTime.UtcNow;
            try
            {
                // P0 Fix: Sanitize message before sending to external AI provider
                // Removes passwords, credit card numbers, CVV codes to prevent data leakage
                var sanitizedMessage = _dataSanitizer.Sanitize(request.MessageText);
                if (_dataSanitizer.ContainsSensitiveData(request.MessageText))
                {
                    _logger.LogWarning(
                        "Sensitive data detected and sanitized before AI call. ConversationId={ConversationId}, SensitiveTypes={Types}",
                        conversation.Id,
                        string.Join(", ", _dataSanitizer.DetectSensitiveDataTypes(request.MessageText)));
                }

                // P2-Context: Fetch recent conversation history for context window (up to 10 messages)
                // This lets AI understand prior turns and respond coherently
                IEnumerable<ConversationHistoryMessage>? conversationHistory = null;
                try
                {
                    var recentMessages = await _dbContext.ChatMessages
                        .AsNoTracking()
                        .Where(m => m.ConversationId == conversation.Id)
                        .OrderByDescending(m => m.CreatedAt)
                        .Take(10)
                        .Select(m => new ConversationHistoryMessage
                        {
                            SenderType = m.SenderType,
                            MessageText = m.MessageText,
                            CreatedAt = m.CreatedAt
                        })
                        .ToListAsync();

                    // Reverse so they are in chronological order for the AI prompt
                    recentMessages.Reverse();
                    conversationHistory = recentMessages;

                    _logger.LogDebug(
                        "Fetched {Count} history messages for context window. ConversationId={ConversationId}",
                        recentMessages.Count, conversation.Id);
                }
                catch (Exception histEx)
                {
                    // Non-fatal: if history fetch fails, AI still answers without context
                    _logger.LogWarning(histEx,
                        "Failed to fetch conversation history for context window. ConversationId={ConversationId}",
                        conversation.Id);
                }

                aiResponseText = await _aiService.GenerateResponseAsync(
                    sanitizedMessage,
                    contextData,
                    classification.Category,
                    conversationHistory);

                var aiResponseTime = (DateTime.UtcNow - aiStartTime).TotalMilliseconds;

                // Requirement 13.2: Log AI response with response time
                _logger.LogInformation(
                    "AI response generated. ConversationId={ConversationId}, ResponseTime={ResponseTimeMs}ms, Timestamp={Timestamp}",
                    conversation.Id, aiResponseTime, DateTime.UtcNow);

                // Requirement 13.4: Log performance metrics
                _logger.LogInformation(
                    "Performance metric: AI response time={ResponseTimeMs}ms for ConversationId={ConversationId}",
                    aiResponseTime, conversation.Id);
            }
            catch (TimeoutException ex)
            {
                // Requirement 18.3: AI service timeout
                _logger.LogError(ex, 
                    "AI service timeout. ConversationId={ConversationId}, Timeout={TimeoutSeconds}s",
                    conversation.Id, 8);

                var fallbackResponse = await BuildFallbackResponseFromContextAsync(request.MessageText, contextData, classification.Category);
                if (!string.IsNullOrWhiteSpace(fallbackResponse))
                {
                    _logger.LogWarning(
                        "Using fallback DB-based response due to AI timeout. ConversationId={ConversationId}",
                        conversation.Id);
                    aiResponseText = fallbackResponse;
                }
                else
                {
                    return new ChatResponse
                    {
                        ConversationId = conversation.Id,
                        ResponseText = "Không thể xử lý câu hỏi, vui lòng liên hệ admin.",
                        ShowContactAdmin = true,
                        Timestamp = DateTime.UtcNow
                    };
                }
            }
            catch (Exception ex)
            {
                // Requirement 18.3: AI service error
                if (IsAiBillingOrQuotaError(ex))
                {
                    _logger.LogWarning(
                        ex,
                        "AI provider quota/billing issue. Falling back to DB-based response. ConversationId={ConversationId}",
                        conversation.Id);
                }
                else
                {
                    _logger.LogError(ex,
                        "AI service error generating response. ConversationId={ConversationId}",
                        conversation.Id);
                }

                var fallbackResponse = await BuildFallbackResponseFromContextAsync(request.MessageText, contextData, classification.Category);
                if (!string.IsNullOrWhiteSpace(fallbackResponse))
                {
                    _logger.LogWarning(
                        "Using fallback DB-based response due to AI generation error. ConversationId={ConversationId}",
                        conversation.Id);
                    aiResponseText = fallbackResponse;
                }
                else
                {
                    return new ChatResponse
                    {
                        ConversationId = conversation.Id,
                        ResponseText = "Không thể xử lý câu hỏi, vui lòng liên hệ admin.",
                        ShowContactAdmin = true,
                        Timestamp = DateTime.UtcNow
                    };
                }
            }

            // Validate AI response
            ValidationResult validationResult;
            try
            {
                validationResult = await _aiService.ValidateResponseAsync(aiResponseText);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, 
                    "Error validating AI response. ConversationId={ConversationId}",
                    conversation.Id);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Không thể xử lý câu hỏi, vui lòng liên hệ admin.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            if (!validationResult.IsValid)
            {
                _logger.LogWarning(
                    "AI response validation failed. ConversationId={ConversationId}, Violations={Violations}",
                    conversation.Id,
                    string.Join(", ", validationResult.Violations));

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Tôi không thể trả lời câu hỏi này một cách chính xác. Vui lòng liên hệ admin.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }

            // Save AI response
            try
            {
                var aiMessage = new ChatMessage
                {
                    ConversationId = conversation.Id,
                    SenderType = "AI",
                    MessageText = aiResponseText,
                    IsEscalationMessage = false,
                    CreatedAt = DateTime.UtcNow
                };

                _dbContext.ChatMessages.Add(aiMessage);
                await _dbContext.SaveChangesAsync();

                _logger.LogInformation("AI response saved for conversation {ConversationId}", conversation.Id);
            }
            catch (Exception ex)
            {
                // Requirement 18.2: SQL Server error saving AI response
                _logger.LogError(ex, 
                    "SQL Server error saving AI response. ConversationId={ConversationId}",
                    conversation.Id);

                // Return the AI response even if we couldn't save it
                // User gets the answer, but it won't be in history
                _logger.LogWarning(
                    "Returning AI response to user despite save failure. ConversationId={ConversationId}",
                    conversation.Id);
            }

            // Calculate total response time
            var totalResponseTime = (DateTime.UtcNow - startTime).TotalMilliseconds;

            // Requirement 13.4: Log performance metrics
            _logger.LogInformation(
                "Request completed. ConversationId={ConversationId}, TotalResponseTime={ResponseTimeMs}ms, Classification={Category}",
                conversation.Id, totalResponseTime, classification.Category);

            return new ChatResponse
            {
                ConversationId = conversation.Id,
                ResponseText = aiResponseText,
                ShowContactAdmin = false,
                Timestamp = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            // Requirement 18.5: Catch-all error handler - don't expose technical details
            _logger.LogError(ex, 
                "Unexpected error processing question. ConversationId={ConversationId}, UserId={UserId}",
                conversationId, userId);

            return new ChatResponse
            {
                ConversationId = conversationId,
                ResponseText = "Hệ thống đang bảo trì, vui lòng thử lại sau.",
                ShowContactAdmin = true,
                Timestamp = DateTime.UtcNow
            };
        }
    }

    /// <summary>
    /// Sub-task 4.2: Get existing conversation or create new one
    /// Validates: Requirements 2.2, 2.3, 14.1, 14.4, 15.1, 15.2
    /// </summary>
    private async Task<ChatConversation> GetOrCreateConversationAsync(SendMessageRequest request, int? userId)
    {
        // Try to get existing conversation
        if (request.ConversationId.HasValue)
        {
            var existing = await _dbContext.ChatConversations
                .FirstOrDefaultAsync(c => c.Id == request.ConversationId.Value);

            if (existing != null)
            {
                // For existing conversations, ignore new guest data parameters
                return existing;
            }
        }

        // Create new conversation
        var conversationCode = await _codeGenerator.GenerateCodeAsync();

        var conversation = new ChatConversation
        {
            ConversationCode = conversationCode,
            AccountId = userId,
            Status = "Open",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // For guest users: use provided guest data
        if (!userId.HasValue)
        {
            conversation.GuestName = request.GuestName;
            conversation.GuestEmail = request.GuestEmail;
            conversation.GuestPhone = request.GuestPhone;
        }
        else
        {
            // For authenticated users: auto-fill from account, set GuestPhone to null
            var account = await _dbContext.Accounts.FindAsync(userId.Value);
            if (account != null)
            {
                conversation.GuestName = account.FullName;
                conversation.GuestEmail = account.Email;
            }
            conversation.GuestPhone = null;
        }

        _dbContext.ChatConversations.Add(conversation);
        await _dbContext.SaveChangesAsync();

        _logger.LogInformation(
            "New conversation created: {ConversationCode}, AccountId={AccountId}",
            conversationCode, userId);

        return conversation;
    }

    /// <summary>
    /// Sub-task 4.4: Retrieve context data based on question category
    /// Validates: Requirements 4.1, 4.2, 5.1, 5.2, 6.1, 6.2, 19.2, 19.3
    /// Sub-task 9.1: Error handling for MongoDB and SQL Server queries
    /// Validates: Requirements 18.1, 18.2
    /// </summary>
    private async Task<string> GetContextDataAsync(string category, string messageText)
    {
        switch (category)
        {
            case "HotelAmenities":
            case "RoomDescription":
                try
                {
                    return await GetHotelCatalogDataAsync(messageText);
                }
                catch (Exception ex)
                {
                    // Requirement 18.1: MongoDB unavailable
                    _logger.LogError(ex, "MongoDB error retrieving hotel catalog data. Category={Category}", category);
                    throw new Exception("MongoDB unavailable", ex);
                }

            case "Policies":
            case "FAQ":
                try
                {
                    return await GetPoliciesAndFAQDataAsync(category);
                }
                catch (Exception ex)
                {
                    // Requirement 18.2: SQL Server unavailable
                    _logger.LogError(ex, "SQL Server error retrieving policies/FAQ data. Category={Category}", category);
                    throw new Exception("SQL Server unavailable", ex);
                }

            case "Pricing":
                try
                {
                    return await GetPricingDataAsync(messageText);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "SQL Server error retrieving pricing data");
                    throw new Exception("SQL Server unavailable", ex);
                }

            case "SearchExplanation":
                // For search explanation, we would retrieve from session/context
                // For now, return empty as session management is not in scope
                return "Không có dữ liệu tìm kiếm trong phiên hiện tại.";

            default:
                try
                {
                    return await GetGeneralHotelDataAsync(messageText);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error retrieving general hotel data");
                    return "";
                }
        }
    }

    /// <summary>
    /// Retrieve room pricing data from SQL Server.
    /// </summary>
    private async Task<string> GetPricingDataAsync(string messageText)
    {
        var rooms = await _dbContext.Rooms
            .AsNoTracking()
            .Include(r => r.Hotel)
            .Where(r => r.IsActive && r.Status == "ACTIVE")
            .OrderBy(r => r.Hotel.Name)
            .ThenBy(r => r.RoomType)
            .Take(40)
            .ToListAsync();

        if (!rooms.Any())
        {
            return "Không tìm thấy dữ liệu phòng và giá hiện tại.";
        }

        var contextBuilder = new System.Text.StringBuilder();
        contextBuilder.AppendLine("Bảng giá phòng tham khảo hiện tại:");

        foreach (var room in rooms)
        {
            var finalPrice = room.BasePricePerNight * room.Rate;
            contextBuilder.AppendLine(
                $"- Khách sạn {room.Hotel.Name} | {room.RoomType} - {room.Name}: giá cơ bản {room.BasePricePerNight:N0} VND/đêm, hệ số {room.Rate:N2}, giá tham khảo hiện tại {finalPrice:N0} VND/đêm, tối đa {room.MaxGuests} khách.");
        }

        return contextBuilder.ToString();
    }

    /// <summary>
    /// Retrieve mixed hotel data so AI can still answer broad hotel questions.
    /// </summary>
    private async Task<string> GetGeneralHotelDataAsync(string messageText)
    {
        var catalogData = await GetHotelCatalogDataAsync(messageText);
        var pricingData = await GetPricingDataAsync(messageText);

        return $"{catalogData}\n\n{pricingData}";
    }

    /// <summary>
    /// Retrieve hotel and room data from MongoDB with caching
    /// </summary>
    private async Task<string> GetHotelCatalogDataAsync(string messageText)
    {
        var cacheKey = $"{HOTEL_AMENITIES_CACHE_KEY_PREFIX}{messageText.GetHashCode()}";

        if (_cache.TryGetValue(cacheKey, out string? cachedData) && cachedData != null)
        {
            _logger.LogInformation("Hotel catalog data retrieved from cache");
            return cachedData;
        }

        try
        {
            // Query MongoDB for hotel catalog
            var hotels = await _mongoContext.HotelCatalog
                .Find(_ => true)
                .Limit(5)
                .ToListAsync();

            if (!hotels.Any())
            {
                return "Không tìm thấy thông tin khách sạn.";
            }

            // Build context string
            var contextBuilder = new System.Text.StringBuilder();
            contextBuilder.AppendLine("Thông tin khách sạn:");

            foreach (var hotel in hotels)
            {
                contextBuilder.AppendLine($"\n{hotel.HotelName}:");
                contextBuilder.AppendLine($"Thành phố: {hotel.City}, {hotel.Country}");
                contextBuilder.AppendLine($"Mô tả: {hotel.Description}");
                contextBuilder.AppendLine($"Tiện ích: {string.Join(", ", hotel.Amenities)}");

                if (hotel.Rooms.Any())
                {
                    contextBuilder.AppendLine("Phòng:");
                    foreach (var room in hotel.Rooms.Take(3))
                    {
                        contextBuilder.AppendLine($"  - {room.RoomType} ({room.RoomName}): {room.Description}");
                        contextBuilder.AppendLine($"    Tiện nghi: {string.Join(", ", room.Amenities)}");
                    }
                }
            }

            var contextData = contextBuilder.ToString();

            // Cache for 30 minutes
            _cache.Set(cacheKey, contextData, TimeSpan.FromMinutes(HOTEL_AMENITIES_CACHE_TTL_MINUTES));

            _logger.LogInformation("Hotel catalog data retrieved from MongoDB and cached");

            return contextData;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error querying MongoDB for hotel catalog");
            throw;
        }
    }

    /// <summary>
    /// Retrieve policies and FAQ data from SQL Server with caching
    /// </summary>
    private async Task<string> GetPoliciesAndFAQDataAsync(string category)
    {
        var cacheKey = $"{FAQ_CACHE_KEY_PREFIX}{category}";

        if (_cache.TryGetValue(cacheKey, out string? cachedData) && cachedData != null)
        {
            _logger.LogInformation("FAQ data retrieved from cache for category {Category}", category);
            return cachedData;
        }

        try
        {
            if (category == "FAQ")
            {
                // Query FAQ table
                var faqs = await _dbContext.FAQs
                    .Where(f => f.IsActive)
                    .OrderBy(f => f.Category)
                    .ToListAsync();

                if (!faqs.Any())
                {
                    return "Không tìm thấy câu hỏi thường gặp.";
                }

                var contextBuilder = new System.Text.StringBuilder();
                contextBuilder.AppendLine("Câu hỏi thường gặp:");

                foreach (var faq in faqs)
                {
                    contextBuilder.AppendLine($"\nQ: {faq.Question}");
                    contextBuilder.AppendLine($"A: {faq.Answer}");
                }

                var contextData = contextBuilder.ToString();

                // Cache for 1 hour
                _cache.Set(cacheKey, contextData, TimeSpan.FromMinutes(FAQ_CACHE_TTL_MINUTES));

                _logger.LogInformation("FAQ data retrieved from SQL Server and cached");

                return contextData;
            }
            else if (category == "Policies")
            {
                // P1-1 Fix: Read policies from HotelPolicies table (admin-configurable)
                var policyItems = await _dbContext.HotelPolicies
                    .Where(p => p.IsActive && p.Category == "Policies")
                    .OrderBy(p => p.SortOrder)
                    .ToListAsync();

                string policies;
                if (policyItems.Any())
                {
                    var sb = new System.Text.StringBuilder();
                    sb.AppendLine("Chính sách khách sạn:");
                    foreach (var item in policyItems)
                    {
                        sb.AppendLine($"\n{item.PolicyName}:");
                        sb.AppendLine(item.Content);
                    }
                    policies = sb.ToString();
                    _logger.LogInformation("Policies loaded from database ({Count} items)", policyItems.Count);
                }
                else
                {
                    // Fallback: default policies when table is empty
                    policies = @"Chính sách khách sạn:

Check-in: 14:00
Check-out: 12:00

Chính sách hủy phòng:
- Hủy trước 24 giờ: Hoàn tiền 100%
- Hủy trong vòng 24 giờ: Hoàn tiền 50%
- Không đến (No-show): Không hoàn tiền

Chính sách thanh toán:
- Chấp nhận thẻ tín dụng, thẻ ghi nợ, tiền mặt
- Thanh toán khi check-in hoặc trước khi check-out

Chính sách trẻ em:
- Trẻ em dưới 6 tuổi: Miễn phí (nếu không sử dụng giường phụ)
- Trẻ em từ 6-12 tuổi: 50% giá phòng
- Trẻ em trên 12 tuổi: Tính như người lớn";

                    _logger.LogWarning("HotelPolicies table empty \u2014 using built-in default policies");
                }

                // Cache for 5 minutes (shorter than FAQ since policies are admin-editable)
                _cache.Set(cacheKey, policies, TimeSpan.FromMinutes(5));

                return policies;
            }

            return "";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error querying SQL Server for policies/FAQ");
            throw;
        }
    }

    /// <summary>
    /// Sub-task 4.5: Escalate conversation to admin
    /// Validates: Requirements 8.4, 8.5, 9.1
    /// Sub-task 9.3: Structured logging for escalations
    /// Validates: Requirements 13.3, 17.2
    /// </summary>
    public async Task<bool> EscalateConversationAsync(int conversationId, string reason)
    {
        try
        {
            var conversation = await _dbContext.ChatConversations
                .FirstOrDefaultAsync(c => c.Id == conversationId);

            if (conversation == null)
            {
                _logger.LogWarning("Conversation {ConversationId} not found for escalation", conversationId);
                return false;
            }

            // Find the last user message before escalation to set EscalatedAt timestamp
            // This ensures admin sees the message that triggered the escalation
            var lastUserMessage = await _dbContext.ChatMessages
                .Where(m => m.ConversationId == conversationId && m.SenderType == "User")
                .OrderByDescending(m => m.CreatedAt)
                .FirstOrDefaultAsync();

            conversation.Status = "EscalatedToAdmin";
            conversation.EscalationReason = reason;
            
            // Set EscalatedAt to the timestamp of the last user message (or now if no messages)
            // This ensures the triggering message is included in admin's view
            conversation.EscalatedAt = lastUserMessage?.CreatedAt ?? DateTime.UtcNow;
            conversation.UpdatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            // Requirement 13.3: Log each escalation with masked sensitive data
            _logger.LogInformation(
                "Conversation escalated to admin. ConversationId={ConversationId}, ConversationCode={ConversationCode}, EscalationReason={MaskedReason}, EscalatedAt={EscalatedAt}, Timestamp={Timestamp}",
                conversationId, conversation.ConversationCode, _logMasker.Mask(reason), conversation.EscalatedAt, DateTime.UtcNow);

            // P1-3: Send email notification to admin
            _ = SendEscalationEmailAsync(conversation, reason);

            // P2-2: Push real-time SignalR event to all admin clients
            _ = _hubNotifier.NotifyNewEscalationAsync(
                conversation.Id,
                conversation.ConversationCode,
                conversation.GuestName ?? conversation.Account?.FullName ?? "Khách ẩn danh",
                conversation.GuestPhone,
                "EscalatedToAdmin",
                _logMasker.Mask(reason));

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error escalating conversation {ConversationId}", conversationId);
            return false;
        }
    }

    /// <summary>
    /// P1-3: Sends an email notification to the configured admin email
    /// when a new conversation is escalated. Fire-and-forget (non-blocking).
    /// </summary>
    private async Task SendEscalationEmailAsync(ChatConversation conversation, string reason)
    {
        try
        {
            var adminEmail = !string.IsNullOrWhiteSpace(_smtpSettings.AdminNotificationEmail)
                ? _smtpSettings.AdminNotificationEmail
                : _smtpSettings.FromEmail;

            if (string.IsNullOrWhiteSpace(adminEmail))
            {
                _logger.LogWarning("Admin email not configured — escalation notification skipped");
                return;
            }

            var guestInfo = conversation.Account != null
                ? $"{conversation.Account.FullName} (Thành viên)"
                : $"{conversation.GuestName ?? "Khách ẩn danh"} | SĐT: {conversation.GuestPhone ?? "Chưa có"}"
            ;

            var localTime = conversation.UpdatedAt.AddHours(7).ToString("HH:mm dd/MM/yyyy");
            var adminChatUrl = $"/AdminChat";

            var htmlBody = $@"
<!DOCTYPE html>
<html>
<head><meta charset='utf-8'></head>
<body style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #f5f5f5; padding: 20px;'>
  <div style='background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);'>
    <div style='background: linear-gradient(135deg, #c9a24a, #8B6914); padding: 20px 24px; color: #fff;'>
      <h2 style='margin:0; font-size:18px;'>🔔 Cuộc trò chuyện cần hỗ trợ</h2>
      <p style='margin:4px 0 0; opacity:0.85; font-size:13px;'>Royal Hotel — AI Chat</p>
    </div>
    <div style='padding: 24px;'>
      <table style='width:100%; border-collapse: collapse;'>
        <tr><td style='padding: 8px 0; color:#666; font-size:13px; width:140px;'>Mã hội thoại</td><td style='padding: 8px 0; font-weight:700; color:#1a1a1a;'>{conversation.ConversationCode}</td></tr>
        <tr><td style='padding: 8px 0; color:#666; font-size:13px;'>Khách</td><td style='padding: 8px 0; color:#1a1a1a;'>{System.Net.WebUtility.HtmlEncode(guestInfo)}</td></tr>
        <tr><td style='padding: 8px 0; color:#666; font-size:13px;'>Lý do</td><td style='padding: 8px 0; color:#1a1a1a;'>{System.Net.WebUtility.HtmlEncode(reason)}</td></tr>
        <tr><td style='padding: 8px 0; color:#666; font-size:13px;'>Thời gian</td><td style='padding: 8px 0; color:#1a1a1a;'>{localTime} (GMT+7)</td></tr>
      </table>
      <div style='margin-top:20px; text-align:center;'>
        <a href='{adminChatUrl}' style='display:inline-block; background:#c9a24a; color:#fff; text-decoration:none; padding:12px 28px; border-radius:6px; font-weight:700; font-size:14px;'>
          Xem và phản hồi ngay
        </a>
      </div>
    </div>
    <div style='background:#f8f8f8; padding:12px 24px; font-size:11px; color:#999; text-align:center;'>
      Email tự động từ hệ thống Royal Hotel. Vui lòng không reply email này.
    </div>
  </div>
</body>
</html>";

            await _emailSender.SendAsync(
                adminEmail,
                $"[Royal Hotel] Khách cần hỗ trợ — {conversation.ConversationCode}",
                htmlBody);

            _logger.LogInformation(
                "Escalation email sent to {AdminEmail} for conversation {ConversationCode}",
                adminEmail, conversation.ConversationCode);
        }
        catch (Exception ex)
        {
            // Non-fatal: email failure should not block the escalation flow
            _logger.LogError(ex, "Failed to send escalation email notification for conversation {ConversationCode}",
                conversation.ConversationCode);
        }
    }

    /// <summary>
    /// Sub-task 4.6: Close conversation
    /// Validates: Requirements 20.2, 20.4
    /// </summary>
    public async Task<bool> CloseConversationAsync(int conversationId)
    {
        try
        {
            var conversation = await _dbContext.ChatConversations
                .FirstOrDefaultAsync(c => c.Id == conversationId);

            if (conversation == null)
            {
                _logger.LogWarning("Conversation {ConversationId} not found for closure", conversationId);
                return false;
            }

            conversation.Status = "Closed";
            conversation.UpdatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Conversation {ConversationId} closed", conversationId);

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error closing conversation {ConversationId}", conversationId);
            return false;
        }
    }

    /// <summary>
    /// Sub-task 4.8: Get conversation history
    /// Validates: Requirements 1.3, 17.4
    /// </summary>
    public async Task<List<ChatMessage>> GetConversationHistoryAsync(int conversationId, int? userId)
    {
        try
        {
            // Validate user has permission to access conversation
            var conversation = await _dbContext.ChatConversations
                .FirstOrDefaultAsync(c => c.Id == conversationId);

            if (conversation == null)
            {
                _logger.LogWarning("Conversation {ConversationId} not found", conversationId);
                return new List<ChatMessage>();
            }

            // Check authorization: user must own the conversation or be admin
            if (userId.HasValue && conversation.AccountId.HasValue && conversation.AccountId.Value != userId.Value)
            {
                // Check if user is admin
                var user = await _dbContext.Accounts.FindAsync(userId.Value);
                if (user == null || user.Role != "admin")
                {
                    _logger.LogWarning(
                        "User {UserId} attempted unauthorized access to conversation {ConversationId}",
                        userId, conversationId);
                    return new List<ChatMessage>();
                }
            }

            // Query messages ordered by CreatedAt
            // IMPORTANT: Filter out AI messages - admin should only see User and Admin messages
            var messages = await _dbContext.ChatMessages
                .AsNoTracking()
                .Where(m => m.ConversationId == conversationId && m.SenderType != "AI")
                .OrderBy(m => m.CreatedAt)
                .Select(m => new ChatMessage
                {
                    Id = m.Id,
                    ConversationId = m.ConversationId,
                    SenderType = m.SenderType,
                    MessageText = m.MessageText,
                    IsEscalationMessage = m.IsEscalationMessage,
                    CreatedAt = m.CreatedAt
                })
                .ToListAsync();

            _logger.LogInformation(
                "Retrieved {Count} messages for conversation {ConversationId}",
                messages.Count, conversationId);

            return messages;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving conversation history for {ConversationId}", conversationId);
            return new List<ChatMessage>();
        }
    }

    /// <summary>
    /// Sub-task 4.9: Get user conversations
    /// Validates: Requirements 15.3
    /// </summary>
    public async Task<List<ChatConversation>> GetUserConversationsAsync(int userId)
    {
        try
        {
            var conversations = await _dbContext.ChatConversations
                .Where(c => c.AccountId == userId)
                .OrderByDescending(c => c.UpdatedAt)
                .ToListAsync();

            _logger.LogInformation(
                "Retrieved {Count} conversations for user {UserId}",
                conversations.Count, userId);

            return conversations;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving conversations for user {UserId}", userId);
            return new List<ChatConversation>();
        }
    }

    /// <summary>
    /// Fallback when external AI API is unavailable. The response is derived from
    /// already-retrieved database context, so user can still receive useful answers
    /// for hotel amenities, room types and pricing questions.
    /// </summary>
    private async Task<string> BuildFallbackResponseFromContextAsync(string question, string contextData, string category)
    {
        if (string.IsNullOrWhiteSpace(question))
        {
            return string.Empty;
        }

        try
        {
            // Vấn đề 1 Fix: Always prioritize returning raw context data for specific categories
            // If user asks about Policies, FAQ, or general HotelAmenities, we already have the perfect
            // answer in contextData (fetched from GetContextDataAsync). Do not attempt to parse room intents.
            if (category == "Policies" || category == "FAQ" || category == "HotelAmenities")
            {
                if (!string.IsNullOrWhiteSpace(contextData))
                {
                    // Truncate to reasonable length for chat response if too long (e.g. HotelAmenities can be huge)
                    var displayContext = contextData.Length > 1000 ? contextData.Substring(0, 1000) + "..." : contextData;
                    
                    var intro = category == "HotelAmenities" 
                        ? "Dưới đây là thông tin tiện ích chung của khách sạn:\n\n" 
                        : "Theo dữ liệu mình tra cứu được:\n\n";

                    return intro + displayContext;
                }
            }

            var questionNormalized = NormalizeText(question);
            var intent = DetectFallbackIntent(questionNormalized, category);
            var desiredRoomType = ExtractRequestedRoomType(questionNormalized);
            var desiredAmenityKeywords = ExtractRequestedAmenities(questionNormalized);

            // Room-level matcher from Mongo catalog
            var catalogs = await _mongoContext.HotelCatalog
                .Find(_ => true)
                .Limit(8)
                .ToListAsync();

            var rawRoomCandidates = catalogs
                .SelectMany(c => c.Rooms.Select(r => new
                {
                    HotelName = c.HotelName,
                    City = c.City,
                    RoomName = r.RoomName,
                    RoomType = r.RoomType,
                    Amenities = r.Amenities ?? new List<string>(),
                    Description = r.Description ?? string.Empty
                }))
                .ToList();

            var locationTerms = ExtractRequestedLocations(
                questionNormalized,
                rawRoomCandidates.Select(x => x.HotelName),
                rawRoomCandidates.Select(x => x.City));

            var roomCandidates = rawRoomCandidates
                .Select(r => new
                {
                    r.HotelName,
                    r.City,
                    r.RoomName,
                    r.RoomType,
                    r.Amenities,
                    r.Description,
                    Score = ScoreRoomCandidate(
                        questionNormalized,
                        intent,
                        desiredRoomType,
                        desiredAmenityKeywords,
                        locationTerms,
                        r.HotelName,
                        r.City,
                        r.RoomType,
                        r.RoomName,
                        r.Amenities,
                        r.Description)
                })
                .Where(x => x.Score > 0)
                .OrderByDescending(x => x.Score)
                .Take(5)
                .ToList();

            // Pricing matcher from SQL
            var priceCandidates = await _dbContext.Rooms
                .AsNoTracking()
                .Include(r => r.Hotel)
                .Where(r => r.IsActive && r.Status == "ACTIVE")
                .Select(r => new
                {
                    HotelName = r.Hotel.Name,
                    City = r.Hotel.City,
                    RoomName = r.Name,
                    RoomType = r.RoomType,
                    BasePrice = r.BasePricePerNight,
                    Rate = r.Rate,
                    MaxGuests = r.MaxGuests
                })
                .ToListAsync();

            var rankedPrices = priceCandidates
                .Select(p => new
                {
                    p.HotelName,
                    p.City,
                    p.RoomName,
                    p.RoomType,
                    p.BasePrice,
                    p.Rate,
                    p.MaxGuests,
                    Score = ScorePriceCandidate(
                        questionNormalized,
                        desiredRoomType,
                        locationTerms,
                        p.HotelName,
                        p.City,
                        p.RoomType,
                        p.RoomName)
                })
                .Where(x => x.Score > 0 || intent == FallbackIntent.Pricing)
                .OrderByDescending(x => x.Score)
                .ThenBy(x => x.BasePrice * x.Rate)
                .Take(5)
                .ToList();

            if (intent == FallbackIntent.Amenity && roomCandidates.Any())
            {
                var top = roomCandidates.First();
                var amenityPreview = top.Amenities.Any()
                    ? string.Join(", ", top.Amenities.Take(6))
                    : "chưa có dữ liệu tiện ích chi tiết";

                var responseBuilder = new StringBuilder();
                responseBuilder.AppendLine($"Mình đã tra cứu đúng nhóm phòng bạn hỏi: **{top.RoomType} - {top.RoomName}** tại {top.HotelName}.");
                responseBuilder.AppendLine($"Tiện ích nổi bật: {amenityPreview}.");

                if (desiredAmenityKeywords.Any())
                {
                    var amenityNormalized = top.Amenities.Select(NormalizeText).ToList();
                    var matched = desiredAmenityKeywords.Where(a => amenityNormalized.Any(am => am.Contains(a))).ToList();
                    if (matched.Any())
                    {
                        responseBuilder.AppendLine($"Theo dữ liệu hiện có, phòng này **có**: {string.Join(", ", matched)}.");
                    }
                    else
                    {
                        responseBuilder.AppendLine("Mình chưa thấy dữ liệu khẳng định tiện ích bạn hỏi trong phòng này.");
                    }
                }

                if (!string.IsNullOrWhiteSpace(top.Description))
                {
                    responseBuilder.AppendLine($"Mô tả thêm: {top.Description}");
                }

                responseBuilder.Append("Nếu bạn muốn mình kiểm tra thêm phòng tương đương ở chi nhánh khác, mình có thể tra cứu tiếp.");
                return responseBuilder.ToString();
            }

            if (intent == FallbackIntent.Pricing && rankedPrices.Any())
            {
                var lines = rankedPrices.Select(x =>
                {
                    var finalPrice = x.BasePrice * x.Rate;
                    return $"- {x.HotelName} ({x.City}) | {x.RoomType} - {x.RoomName}: khoảng {finalPrice:N0} VND/đêm (tối đa {x.MaxGuests} khách)";
                });

                return "Mình đã lọc theo nhu cầu của bạn và tìm được mức giá tham khảo:\n"
                    + string.Join("\n", lines)
                    + "\n\nGiá chính xác có thể thay đổi theo ngày lưu trú, nhưng bạn có thể dựa trên các mức trên để so sánh nhanh.";
            }

            if (intent == FallbackIntent.RoomType && roomCandidates.Any())
            {
                var lines = roomCandidates.Select(x =>
                {
                    var shortAmenities = x.Amenities.Any() ? string.Join(", ", x.Amenities.Take(4)) : "chưa có tiện ích chi tiết";
                    return $"- {x.HotelName} | {x.RoomType} - {x.RoomName}: {shortAmenities}";
                });

                return "Mình đã lọc các loại phòng phù hợp với câu hỏi của bạn:\n"
                    + string.Join("\n", lines)
                    + "\n\nNếu bạn muốn, mình có thể tiếp tục gợi ý theo ngân sách hoặc số người ở.";
            }

            // Generic fallback from context lines when matcher has no strong hit.
            if (!string.IsNullOrWhiteSpace(contextData))
            {
                var fallbackLines = contextData
                    .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .Where(l => l.Contains("giá", StringComparison.OrdinalIgnoreCase)
                             || l.Contains("VND", StringComparison.OrdinalIgnoreCase)
                             || l.Contains("Tiện ích", StringComparison.OrdinalIgnoreCase)
                             || l.Contains("Phòng", StringComparison.OrdinalIgnoreCase))
                    .Take(5)
                    .ToList();

                if (fallbackLines.Any())
                {
                    return "Mình đã tra cứu từ dữ liệu hệ thống và có thông tin sau:\n"
                        + string.Join("\n", fallbackLines.Select(l => $"- {l}"));
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error building smart fallback response");
        }

        return string.Empty;
    }

    private enum FallbackIntent
    {
        General = 0,
        Amenity = 1,
        Pricing = 2,
        RoomType = 3
    }

    private FallbackIntent DetectFallbackIntent(string normalizedQuestion, string category)
    {
        if (category == "Pricing"
            || normalizedQuestion.Contains("gia")
            || normalizedQuestion.Contains("price")
            || normalizedQuestion.Contains("bao nhieu"))
        {
            return FallbackIntent.Pricing;
        }

        if (normalizedQuestion.Contains("tien ich")
            || normalizedQuestion.Contains("amenity")
            || normalizedQuestion.Contains("co ")
            || normalizedQuestion.Contains("khong"))
        {
            return FallbackIntent.Amenity;
        }

        if (category == "RoomDescription"
            || normalizedQuestion.Contains("loai phong")
            || normalizedQuestion.Contains("room type")
            || normalizedQuestion.Contains("phong"))
        {
            return FallbackIntent.RoomType;
        }

        return FallbackIntent.General;
    }

    private string? ExtractRequestedRoomType(string normalizedQuestion)
    {
        var roomTypeAliases = new Dictionary<string, string[]>
        {
            ["standard"] = new[] { "standard", "tieu chuan", "thuong", "phong thuong" },
            ["deluxe"] = new[] { "deluxe", "de luxe", "cao cap" },
            ["suite"] = new[] { "suite", "suit", "can ho", "apartment", "vip" },
            ["family"] = new[] { "family", "gia dinh", "phong gia dinh" },
            ["executive"] = new[] { "executive", "dieu hanh", "business" },
            ["superior"] = new[] { "superior", "nang cao" },
            ["double"] = new[] { "double room", "phong doi", "giuong doi" },
            ["twin"] = new[] { "twin", "2 giuong don", "hai giuong don" },
            ["single"] = new[] { "single", "mot nguoi", "1 nguoi" }
        };

        foreach (var kvp in roomTypeAliases)
        {
            if (kvp.Value.Any(alias => normalizedQuestion.Contains(alias)))
            {
                return kvp.Key;
            }
        }

        var roomTypes = new[] { "standard", "deluxe", "suite", "family", "executive", "superior", "double", "twin", "single" };
        return roomTypes.FirstOrDefault(t => normalizedQuestion.Contains(t));
    }

    private List<string> ExtractRequestedAmenities(string normalizedQuestion)
    {
        var amenityAliases = new Dictionary<string, string[]>
        {
            ["bon tam"] = new[] { "bon tam", "bathtub", "bath tub", "tam bon" },
            ["wifi"] = new[] { "wifi", "wi fi", "internet" },
            ["ban cong"] = new[] { "ban cong", "balcony" },
            ["view bien"] = new[] { "view bien", "sea view", "ocean view" },
            ["view thanh pho"] = new[] { "view thanh pho", "city view" },
            ["view vuon"] = new[] { "view vuon", "garden view" },
            ["giuong doi"] = new[] { "giuong doi", "double bed", "king bed", "queen bed" },
            ["giuong don"] = new[] { "giuong don", "single bed", "twin bed" },
            ["may lanh"] = new[] { "may lanh", "air conditioning", "ac" },
            ["bep"] = new[] { "bep", "kitchen", "kitchenette" },
            ["ho boi"] = new[] { "ho boi", "swimming pool", "pool" },
            ["phong gym"] = new[] { "gym", "fitness", "phong tap" },
            ["an sang"] = new[] { "an sang", "breakfast", "buffet sang" },
            ["don san bay"] = new[] { "don san bay", "airport shuttle", "shuttle" },
            ["hut thuoc"] = new[] { "khong hut thuoc", "non smoking", "smoke free" },
            ["tam nhin bien"] = new[] { "tam nhin bien", "sea facing", "huong bien" }
        };

        return amenityAliases
            .Where(kvp => kvp.Value.Any(alias => normalizedQuestion.Contains(alias)))
            .Select(kvp => kvp.Key)
            .ToList();
    }

    private List<string> ExtractRequestedLocations(
        string normalizedQuestion,
        IEnumerable<string> candidateHotelNames,
        IEnumerable<string> candidateCities)
    {
        var terms = new HashSet<string>();
        var commonLocationAliases = new Dictionary<string, string[]>
        {
            ["ha noi"] = new[] { "ha noi", "hanoi", "thu do" },
            ["da nang"] = new[] { "da nang", "danang" },
            ["ho chi minh"] = new[] { "ho chi minh", "hcm", "sai gon", "saigon", "tphcm" },
            ["nha trang"] = new[] { "nha trang" },
            ["phu quoc"] = new[] { "phu quoc" },
            ["hoi an"] = new[] { "hoi an" },
            ["ha long"] = new[] { "ha long", "halong" }
        };

        foreach (var kvp in commonLocationAliases)
        {
            if (kvp.Value.Any(alias => normalizedQuestion.Contains(alias)))
            {
                terms.Add(kvp.Key);
            }
        }

        foreach (var hotel in candidateHotelNames.Distinct())
        {
            var normalized = NormalizeText(hotel);
            if (!string.IsNullOrWhiteSpace(normalized) && normalizedQuestion.Contains(normalized))
            {
                terms.Add(normalized);
            }
        }

        foreach (var city in candidateCities.Distinct())
        {
            var normalized = NormalizeText(city);
            if (!string.IsNullOrWhiteSpace(normalized) && normalizedQuestion.Contains(normalized))
            {
                terms.Add(normalized);
            }
        }

        return terms.ToList();
    }

    private int ScoreRoomCandidate(
        string normalizedQuestion,
        FallbackIntent intent,
        string? desiredRoomType,
        List<string> desiredAmenities,
        List<string> requestedLocations,
        string hotelName,
        string city,
        string roomType,
        string roomName,
        List<string> amenities,
        string description)
    {
        var score = 0;
        var hotelNameNormalized = NormalizeText(hotelName);
        var cityNormalized = NormalizeText(city);
        var roomTypeNormalized = NormalizeText(roomType);
        var roomNameNormalized = NormalizeText(roomName);
        var descriptionNormalized = NormalizeText(description);
        var amenityNormalized = amenities.Select(NormalizeText).ToList();

        if (!string.IsNullOrWhiteSpace(desiredRoomType) &&
            (roomTypeNormalized.Contains(desiredRoomType) || roomNameNormalized.Contains(desiredRoomType)))
        {
            score += 8;
        }

        if (intent == FallbackIntent.RoomType || intent == FallbackIntent.Amenity)
        {
            score += 2;
        }

        foreach (var amenity in desiredAmenities)
        {
            if (amenityNormalized.Any(a => a.Contains(amenity)))
            {
                score += 5;
            }
            else if (descriptionNormalized.Contains(amenity))
            {
                score += 3;
            }
        }

        if (normalizedQuestion.Contains(roomTypeNormalized) || normalizedQuestion.Contains(roomNameNormalized))
        {
            score += 2;
        }

        foreach (var location in requestedLocations)
        {
            if (hotelNameNormalized.Contains(location))
            {
                score += 10;
            }
            else if (cityNormalized.Contains(location))
            {
                score += 7;
            }
        }

        return score;
    }

    private int ScorePriceCandidate(
        string normalizedQuestion,
        string? desiredRoomType,
        List<string> requestedLocations,
        string hotelName,
        string city,
        string roomType,
        string roomName)
    {
        var score = 1;
        var hotelNameNormalized = NormalizeText(hotelName);
        var cityNormalized = NormalizeText(city);
        var roomTypeNormalized = NormalizeText(roomType);
        var roomNameNormalized = NormalizeText(roomName);

        if (!string.IsNullOrWhiteSpace(desiredRoomType) &&
            (roomTypeNormalized.Contains(desiredRoomType) || roomNameNormalized.Contains(desiredRoomType)))
        {
            score += 8;
        }

        if (normalizedQuestion.Contains(roomTypeNormalized) || normalizedQuestion.Contains(roomNameNormalized))
        {
            score += 2;
        }

        foreach (var location in requestedLocations)
        {
            if (hotelNameNormalized.Contains(location))
            {
                score += 10;
            }
            else if (cityNormalized.Contains(location))
            {
                score += 7;
            }
        }

        return score;
    }

    private string NormalizeText(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return string.Empty;
        }

        var normalized = input.ToLowerInvariant().Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var ch in normalized)
        {
            var unicodeCategory = CharUnicodeInfo.GetUnicodeCategory(ch);
            if (unicodeCategory != UnicodeCategory.NonSpacingMark)
            {
                sb.Append(ch);
            }
        }

        return sb
            .ToString()
            .Normalize(NormalizationForm.FormC)
            .Replace("đ", "d");
    }

    private bool IsAiBillingOrQuotaError(Exception ex)
    {
        if (ex is HttpRequestException httpEx)
        {
            var msg = httpEx.Message ?? string.Empty;
            return msg.Contains("402") || msg.Contains("Payment Required", StringComparison.OrdinalIgnoreCase);
        }

        return false;
    }
}
