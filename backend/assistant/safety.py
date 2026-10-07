import re

# Specific harmful request patterns: matches requests to COMMIT, FACILITATE, or HIDE wrongdoing
_HACK_PATTERNS = [
    r"\bhow (do|can) i (hack|break into|steal from)\b.*\b(bank|account|upi|wallet|card|phone|email)\b",
    r"\bhack(ing)? into (someone|his|her|their|my|a)?'?s? (bank|account|phone|email|system|upi)\b",
    r"\bhelp me (hack|break into)\b",
]

_FORGERY_PATTERNS = [
    r"\bhow (do|can) i (make|create|generate|forge|get)\b.*\b(fake|forged|fraudulent)\b.*\b(licence|license|rc|passport|aadhaar|pan|id|document)\b",
    r"\bhow (do|can) i forge (a |an )?(driving )?(licence|license|rc|passport|aadhaar|pan|id|document)\b",
    r"\b(make|create|forge) (a |an )?(fake|forged) (driving licence|driving license|rc|passport|aadhaar|pan)\b",
    r"\bforge (a |an )?(driving )?(licence|license|rc|passport|aadhaar|pan)\b",
]

_HIDE_EVIDENCE_PATTERNS = [
    r"\bhow (do|can) i (hide|destroy|dispose of|erase|delete|wipe)\b.*\b(evidence|body|weapon|crime scene|fingerprint|traces|blood)\b",
    r"\b(hide|destroy|conceal|dispose of) (evidence|the body|the weapon)\b.*\bafter (committing |a )?crime\b",
]

_GENERAL_HARMFUL_PATTERNS = [
    r"\bhow (do|can) i (make|build|create) (a |an )?(bomb|explosive|pipe bomb)\b",
    r"\b(write|create|generate) (me |us )?(a |an )?(malware|ransomware|keylogger|computer virus|virus code)\b",
    r"\bwrite (me |us )?(a |an )?(phishing|scam) (email|message|sms|text)\b",
    r"\bwrite (me |us )?(a |an )?(threatening|blackmail|extortion) (message|letter|email|note)\b",
    r"\b(steal|get) (someone'?s|his|her|their) (password|otp|credit card)\b.*\bfor me\b",
    r"\bwithout (getting caught|leaving evidence|it being traced)\b",
]

_SELF_HARM_PATTERNS = [
    r"\b(i want to|i'?m going to|thinking about|planning to) (kill myself|end my life|die by suicide)\b",
    r"\bhow (do|can) i (commit suicide|kill myself)\b",
    r"\bi (don'?t|do not) want to (live|be alive) anymore\b",
]

# If the message reads as an informational legal question about the law/rights/penalties,
# that framing wins — NEVER flag it as harmful.
_LEGAL_QUESTION_MARKERS = [
    r"\b(is|are|was|were)\b.{0,60}\b(illegal|a crime|an offence|punishable|legal)\b",
    r"\bis it (a crime|illegal|an offence)\b",
    r"\bwhat (is|are) the (punishment|penalty|section|law|fine)\b",
    r"\bwhat happens if\b",
    r"\bcan (i|someone|a person) be (charged|arrested|prosecuted|punished)\b",
    r"\bwhich section\b",
    r"\brights if\b",
    r"\bmy rights\b",
    r"\bwhat are my rights\b",
    r"\bwhat should i do\b",
    r"\bwhat can i do\b",
    r"\bexplain\b",
    r"\bdefine\b",
    r"\bprocedure for\b",
    r"\bhow to report\b",
    r"\bhow to complain\b",
    r"\bhow to file\b",
    r"\bhow to contest\b",
]

_hack_re = re.compile("|".join(_HACK_PATTERNS), re.IGNORECASE)
_forgery_re = re.compile("|".join(_FORGERY_PATTERNS), re.IGNORECASE)
_hide_evidence_re = re.compile("|".join(_HIDE_EVIDENCE_PATTERNS), re.IGNORECASE)
_harmful_re = re.compile("|".join(_GENERAL_HARMFUL_PATTERNS), re.IGNORECASE)
_self_harm_re = re.compile("|".join(_SELF_HARM_PATTERNS), re.IGNORECASE)
_legal_question_re = re.compile("|".join(_LEGAL_QUESTION_MARKERS), re.IGNORECASE)

SELF_HARM_RESPONSE = (
    "It sounds like you might be going through something really difficult "
    "right now. I'm not able to help with that, but you don't have to "
    "face it alone — the KIRAN Mental Health Rehabilitation Helpline "
    "(1800-599-0019) is a free, 24x7, government-run helpline in India "
    "with trained counsellors who can talk this through with you in your "
    "own language. Please consider reaching out to them, or to someone "
    "you trust, right now."
)

HACK_REFUSAL_RESPONSE = (
    "I can't provide instructions for hacking or stealing from someone. "
    "If your goal is legitimate cybersecurity testing, I can help with ethical "
    "security testing, account protection, or reporting a vulnerability."
)

FORGERY_REFUSAL_RESPONSE = (
    "I can't help create or use a forged document. "
    "I can explain the lawful process for obtaining or replacing a driving licence."
)

HIDE_EVIDENCE_REFUSAL_RESPONSE = (
    "I can't provide instructions for hiding or destroying evidence. "
    "I can explain general legal rights, the investigation process, and how "
    "to seek qualified legal assistance."
)

HARMFUL_REQUEST_RESPONSE = (
    "I can't help plan or carry out something illegal or harmful. If "
    "you'd like, I'm glad to explain the relevant law itself instead — "
    "for example, what counts as an offence here, what the punishment "
    "is, or what your options are if you're on the receiving end of "
    "something like this."
)


def classify_message_risk(text: str):
    """
    Classifies risk: returns 'self_harm', 'hack', 'forgery', 'hide_evidence',
    'harmful_request', or None.
    Legitimate legal inquiries (e.g. asking about penalties for illegal drugs or rights upon arrest)
    are explicitly allowed.
    """
    clean_text = text.strip()
    if _self_harm_re.search(clean_text):
        return "self_harm"

    # If it is clearly framed as an informational legal question, it is safe
    if _legal_question_re.search(clean_text):
        # But if it explicitly asks "how to hack" or "how to make a fake licence", reject it
        if _hack_re.search(clean_text):
            return "hack"
        if _forgery_re.search(clean_text):
            return "forgery"
        if _hide_evidence_re.search(clean_text):
            return "hide_evidence"
        return None

    if _hack_re.search(clean_text):
        return "hack"
    if _forgery_re.search(clean_text):
        return "forgery"
    if _hide_evidence_re.search(clean_text):
        return "hide_evidence"
    if _harmful_re.search(clean_text):
        return "harmful_request"

    return None


def get_risk_response(risk_type: str) -> str:
    """Returns the tailored response for the identified risk category."""
    if risk_type == "self_harm":
        return SELF_HARM_RESPONSE
    if risk_type == "hack":
        return HACK_REFUSAL_RESPONSE
    if risk_type == "forgery":
        return FORGERY_REFUSAL_RESPONSE
    if risk_type == "hide_evidence":
        return HIDE_EVIDENCE_REFUSAL_RESPONSE
    return HARMFUL_REQUEST_RESPONSE
