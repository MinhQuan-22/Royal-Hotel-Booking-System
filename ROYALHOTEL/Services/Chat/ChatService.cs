using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using MongoDB.Driver;
using ROYALHOTEL.Data;
using ROYALHOTEL.DTOs;
using ROYALHOTEL.Models;

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
        LogMasker logMasker)
    {
        _dbContext = dbContext;
        _mongoContext = mongoContext;
        _aiService = aiService;
        _cache = cache;
        _logger = logger;
        _codeGenerator = codeGenerator;
        _logMasker = logMasker;
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

            // Validate conversation is not closed
            if (conversation.Status == "Closed")
            {
                _logger.LogWarning("Attempt to send message to closed conversation {ConversationId}", conversation.Id);
                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Cuộc hội thoại này đã được đóng. Vui lòng bắt đầu cuộc hội thoại mới.",
                    ShowContactAdmin = false,
                    Timestamp = DateTime.UtcNow
                };
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
                var escalationMessage = "Xin lỗi, câu hỏi của bạn nằm ngoài phạm vi hỗ trợ tự động của tôi. " +
                                      "Vui lòng liên hệ với admin để được hỗ trợ tốt hơn.";

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
                aiResponseText = await _aiService.GenerateResponseAsync(
                    request.MessageText,
                    contextData,
                    classification.Category);

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

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Không thể xử lý câu hỏi, vui lòng liên hệ admin.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
            }
            catch (Exception ex)
            {
                // Requirement 18.3: AI service error
                _logger.LogError(ex, 
                    "AI service error generating response. ConversationId={ConversationId}",
                    conversation.Id);

                return new ChatResponse
                {
                    ConversationId = conversation.Id,
                    ResponseText = "Không thể xử lý câu hỏi, vui lòng liên hệ admin.",
                    ShowContactAdmin = true,
                    Timestamp = DateTime.UtcNow
                };
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

        // For guest users: require GuestName and GuestEmail
        if (!userId.HasValue)
        {
            conversation.GuestName = request.GuestName;
            conversation.GuestEmail = request.GuestEmail;
        }
        else
        {
            // For authenticated users: auto-fill from account
            var account = await _dbContext.Accounts.FindAsync(userId.Value);
            if (account != null)
            {
                conversation.GuestName = account.FullName;
                conversation.GuestEmail = account.Email;
            }
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

            case "SearchExplanation":
                // For search explanation, we would retrieve from session/context
                // For now, return empty as session management is not in scope
                return "Không có dữ liệu tìm kiếm trong phiên hiện tại.";

            default:
                return "";
        }
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
                // Hardcoded policies for now
                var policies = @"Chính sách khách sạn:

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

                // Cache for 1 hour
                _cache.Set(cacheKey, policies, TimeSpan.FromMinutes(FAQ_CACHE_TTL_MINUTES));

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

            conversation.Status = "EscalatedToAdmin";
            conversation.EscalationReason = reason;
            conversation.UpdatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            // Requirement 13.3: Log each escalation with masked sensitive data
            _logger.LogInformation(
                "Conversation escalated to admin. ConversationId={ConversationId}, ConversationCode={ConversationCode}, EscalationReason={MaskedReason}, Timestamp={Timestamp}",
                conversationId, conversation.ConversationCode, _logMasker.Mask(reason), DateTime.UtcNow);

            // Create notification for admin (log-based for now)
            _logger.LogWarning(
                "ADMIN NOTIFICATION: New escalated conversation {ConversationCode} - {MaskedReason}",
                conversation.ConversationCode, _logMasker.Mask(reason));

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error escalating conversation {ConversationId}", conversationId);
            return false;
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
            var messages = await _dbContext.ChatMessages
                .Where(m => m.ConversationId == conversationId)
                .OrderBy(m => m.CreatedAt)
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
}
