/**
 * Chat Widget - AI Live Chat Support
 * Handles user interactions with the chat widget
 */

class ChatWidget {
  constructor() {
    this.conversationId = null;
    this.isOpen = false;
    this.isProcessing = false;

    // DOM elements
    this.widget = document.getElementById("chat-widget");
    this.toggleBtn = document.getElementById("chat-widget-toggle");
    this.closeBtn = document.querySelector(".chat-widget__close");
    this.messagesContainer = document.getElementById("chat-messages");
    this.inputField = document.getElementById("chat-input");
    this.sendBtn = document.getElementById("chat-send-btn");
    this.typingIndicator = document.getElementById("chat-typing");
    this.escalationSection = document.getElementById("chat-escalation");
    this.escalationBtn = document.getElementById("chat-escalation-btn");

    this.init();
  }

  init() {
    // Load conversation ID from sessionStorage
    this.conversationId = sessionStorage.getItem("chatConversationId");

    // Event listeners
    this.toggleBtn.addEventListener("click", () => this.toggleWidget());
    this.closeBtn.addEventListener("click", () => this.closeWidget());
    this.sendBtn.addEventListener("click", () => this.sendMessage());
    this.inputField.addEventListener("keypress", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        this.sendMessage();
      }
    });
    this.escalationBtn.addEventListener("click", () => this.escalateToAdmin());

    // Load conversation history for authenticated users
    if (this.isAuthenticated()) {
      this.loadConversationHistory();
    }
  }

  toggleWidget() {
    if (this.isOpen) {
      this.closeWidget();
    } else {
      this.openWidget();
    }
  }

  openWidget() {
    this.widget.style.display = "flex";
    this.isOpen = true;
    this.inputField.focus();

    // Scroll to bottom
    setTimeout(() => {
      this.scrollToBottom();
    }, 100);
  }

  closeWidget() {
    this.widget.style.display = "none";
    this.isOpen = false;
  }

  async sendMessage() {
    const messageText = this.inputField.value.trim();

    // Validation
    if (!messageText) {
      return;
    }

    if (messageText.length > 2000) {
      this.displayError("Tin nhắn quá dài. Vui lòng nhập tối đa 2000 ký tự.");
      return;
    }

    if (this.isProcessing) {
      return;
    }

    // Clear input
    this.inputField.value = "";

    // Display user message immediately
    this.displayMessage("User", messageText, new Date());

    // Show typing indicator
    this.showTypingIndicator();

    // Disable input
    this.isProcessing = true;
    this.sendBtn.disabled = true;
    this.inputField.disabled = true;

    try {
      // Prepare request
      const requestData = {
        conversationId: this.conversationId,
        messageText: messageText,
      };

      // Make API call
      const response = await fetch("/api/chat/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestData),
      });

      if (!response.ok) {
        if (response.status === 429) {
          throw new Error("Quá nhiều yêu cầu, vui lòng thử lại sau.");
        }
        throw new Error("Không thể gửi tin nhắn. Vui lòng thử lại.");
      }

      const data = await response.json();

      // Save conversation ID
      if (data.conversationId) {
        this.conversationId = data.conversationId;
        sessionStorage.setItem("chatConversationId", data.conversationId);
      }

      // Hide typing indicator
      this.hideTypingIndicator();

      // Display AI response
      this.displayMessage("AI", data.responseText, new Date(data.timestamp));

      // Show escalation button if needed
      if (data.showContactAdmin) {
        this.showEscalationButton();
      }
    } catch (error) {
      console.error("Error sending message:", error);
      this.hideTypingIndicator();
      this.displayError(error.message || "Đã xảy ra lỗi. Vui lòng thử lại.");
    } finally {
      // Re-enable input
      this.isProcessing = false;
      this.sendBtn.disabled = false;
      this.inputField.disabled = false;
      this.inputField.focus();
    }
  }

  displayMessage(senderType, messageText, timestamp) {
    const messageDiv = document.createElement("div");
    messageDiv.className = `chat-widget__message chat-widget__message--${senderType.toLowerCase()}`;

    const bubbleDiv = document.createElement("div");
    bubbleDiv.className = "chat-widget__message-bubble";
    bubbleDiv.textContent = messageText;

    const metaDiv = document.createElement("div");
    metaDiv.className = "chat-widget__message-meta";

    const senderSpan = document.createElement("span");
    senderSpan.className = "chat-widget__message-sender";
    senderSpan.textContent = this.getSenderLabel(senderType);

    const timeSpan = document.createElement("span");
    timeSpan.className = "chat-widget__message-time";
    timeSpan.textContent = this.formatTime(timestamp);

    metaDiv.appendChild(senderSpan);
    metaDiv.appendChild(document.createTextNode("•"));
    metaDiv.appendChild(timeSpan);

    messageDiv.appendChild(bubbleDiv);
    messageDiv.appendChild(metaDiv);

    this.messagesContainer.appendChild(messageDiv);
    this.scrollToBottom();
  }

  displayError(errorMessage) {
    const errorDiv = document.createElement("div");
    errorDiv.className = "chat-widget__error";
    errorDiv.textContent = errorMessage;

    this.messagesContainer.appendChild(errorDiv);
    this.scrollToBottom();

    // Auto-remove after 5 seconds
    setTimeout(() => {
      errorDiv.remove();
    }, 5000);
  }

  showTypingIndicator() {
    this.typingIndicator.style.display = "inline-flex";
    this.messagesContainer.appendChild(this.typingIndicator);
    this.scrollToBottom();
  }

  hideTypingIndicator() {
    this.typingIndicator.style.display = "none";
  }

  showEscalationButton() {
    this.escalationSection.style.display = "block";
  }

  hideEscalationButton() {
    this.escalationSection.style.display = "none";
  }

  async escalateToAdmin() {
    if (!this.conversationId) {
      this.displayError(
        "Không thể liên hệ admin. Vui lòng gửi tin nhắn trước.",
      );
      return;
    }

    if (this.isProcessing) {
      return;
    }

    this.isProcessing = true;
    this.escalationBtn.disabled = true;

    try {
      const response = await fetch("/api/chat/escalate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          conversationId: this.conversationId,
          reason: "Yêu cầu hỗ trợ từ admin",
        }),
      });

      if (!response.ok) {
        throw new Error("Không thể chuyển cho admin. Vui lòng thử lại.");
      }

      // Display confirmation message
      const confirmationDiv = document.createElement("div");
      confirmationDiv.className =
        "chat-widget__message chat-widget__message--ai";

      const bubbleDiv = document.createElement("div");
      bubbleDiv.className = "chat-widget__message-bubble";
      bubbleDiv.textContent =
        "Yêu cầu của bạn đã được chuyển đến admin. Chúng tôi sẽ phản hồi sớm nhất có thể.";

      confirmationDiv.appendChild(bubbleDiv);
      this.messagesContainer.appendChild(confirmationDiv);
      this.scrollToBottom();

      // Hide escalation button
      this.hideEscalationButton();
    } catch (error) {
      console.error("Error escalating to admin:", error);
      this.displayError(error.message || "Đã xảy ra lỗi. Vui lòng thử lại.");
    } finally {
      this.isProcessing = false;
      this.escalationBtn.disabled = false;
    }
  }

  async loadConversationHistory() {
    try {
      // Get list of conversations
      const conversationsResponse = await fetch("/api/chat/conversations");

      if (!conversationsResponse.ok) {
        return; // Silently fail for unauthenticated users
      }

      const conversations = await conversationsResponse.json();

      if (conversations.length === 0) {
        return;
      }

      // Load the most recent conversation
      const latestConversation = conversations[0];
      this.conversationId = latestConversation.id;
      sessionStorage.setItem("chatConversationId", latestConversation.id);

      // Load messages for this conversation
      const historyResponse = await fetch(
        `/api/chat/history/${latestConversation.id}`,
      );

      if (!historyResponse.ok) {
        return;
      }

      const messages = await historyResponse.json();

      // Clear welcome message
      const welcomeMsg = this.messagesContainer.querySelector(
        ".chat-widget__welcome",
      );
      if (welcomeMsg) {
        welcomeMsg.remove();
      }

      // Display all messages
      messages.forEach((msg) => {
        this.displayMessage(
          msg.senderType,
          msg.messageText,
          new Date(msg.createdAt),
        );
      });
    } catch (error) {
      console.error("Error loading conversation history:", error);
      // Silently fail - don't disrupt user experience
    }
  }

  isAuthenticated() {
    // Check if user is authenticated by looking for auth cookie or session
    // This is a simple check - adjust based on your authentication mechanism
    return (
      document.cookie.includes(".AspNetCore.Session") ||
      document.cookie.includes("AuthToken")
    );
  }

  getSenderLabel(senderType) {
    switch (senderType) {
      case "User":
        return "Bạn";
      case "AI":
        return "Trợ lý AI";
      case "Admin":
        return "Admin";
      default:
        return senderType;
    }
  }

  formatTime(timestamp) {
    const date = new Date(timestamp);
    const hours = date.getHours().toString().padStart(2, "0");
    const minutes = date.getMinutes().toString().padStart(2, "0");
    return `${hours}:${minutes}`;
  }

  scrollToBottom() {
    this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
  }
}

// Initialize chat widget when DOM is ready
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => {
    new ChatWidget();
  });
} else {
  new ChatWidget();
}
