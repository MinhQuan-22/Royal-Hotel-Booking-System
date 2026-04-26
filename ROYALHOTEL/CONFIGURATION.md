# Configuration Guide

## OpenAI API Key Configuration

The application requires an OpenAI API key for the AI Live Chat Support feature.

### Using User Secrets (Recommended for Development)

For security, do not commit your API key to source control. Use .NET User Secrets instead:

```bash
cd ROYALHOTEL
dotnet user-secrets init
dotnet user-secrets set "OpenAI:ApiKey" "your-actual-openai-api-key"
```

### Using Environment Variables (Recommended for Production)

Set the environment variable:

```bash
export OpenAI__ApiKey="your-actual-openai-api-key"
```

Or in Docker/Kubernetes, configure the environment variable in your deployment configuration.

### Configuration Values

The following OpenAI settings are configured in `appsettings.json`:

- **ApiKey**: Your OpenAI API key (use user secrets or environment variables)
- **Model**: `gpt-4` (the AI model to use)
- **Timeout**: `8` seconds (request timeout)
- **MaxRetries**: `2` (number of retry attempts for 5xx errors)

## Other Configuration

### Database Connection Strings

- **SQL Server**: Configured in `ConnectionStrings:DefaultConnection`
- **MongoDB**: Configured in `MongoDb` section

### SMTP Settings

Email notification settings are in the `Smtp` section of `appsettings.Development.json`.
