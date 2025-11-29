## Bot Detection Methods

This survey uses 9 different bot detection flags:

### 1. **Honeypot Field** (`bot_flag_honeypot`)
- A text field asking for "favorite film director" that's hidden with CSS
- Humans won't see it, but bots filling all fields will complete it
- **Trigger**: Field is filled with any text

### 2. **Fake Service** (`bot_flag_fake_service`)
- Includes "MovieStream Pro" - a non-existent streaming service
- **Trigger**: User selects the fake service

### 3. **Non-Existent Movie** (`bot_flag_fake_movie`)
- Asks about "The Crimson Eclipse (2019)" which doesn't exist
- **Trigger**: User claims to have seen it

### 4. **Simple Math** (`bot_flag_math`)
- Basic CAPTCHA alternative: 7 + 5 = ?
- **Trigger**: Answer is not 12

### 5. **Attention Check** (`bot_flag_attention`)
- Explicitly instructs user to select "Action"
- **Trigger**: User selects anything other than "Action"

### 6. **Consistency Check** (`bot_flag_inconsistent_frequency`)
- Asks about movie frequency twice with different wording
- **Trigger**: Responses don't match (e.g., "Daily" vs "Less than once")

### 7. **Logic Trap** (`bot_flag_logic`)
- Cross-validates theater frequency with last theater visit
- **Trigger**: Claims to never watch movies but recently went to theater

### 8. **Text Length** (`bot_flag_short_text`)
- Asks for description of movie theater experience
- **Trigger**: Response is less than 10 characters

### 9. **Response Time** (`bot_flag_too_fast`)
- Tracks time spent on second page (should take at least 3 seconds to read)
- **Trigger**: Page completed in less than 3 seconds
 
## Other ideas

Consider adding:
- Mouse movement tracking
- Keystroke dynamics
- Image-based CAPTCHAs
- More complex logical contradictions
- Question order randomization
