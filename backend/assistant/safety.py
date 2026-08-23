import re

# Narrow by design: matches requests to AUTHOR/CONSTRUCT something harmful, not legal questions that mention a crime.
_HARMFUL_REQUEST_PATTERNS = [
    r"\bhow (do|can) i (make|build|create) (a |an )?(bomb|explosive|pipe bomb)\b",
    r"\b(write|create|generate) (me |us )?(a |an )?(malware|ransomware|keylogger|computer virus|virus code)\b",
    r"\bwrite (me |us )?(a |an )?(phishing|scam) (email|message|sms|text)\b",
    r"\bhack(ing)? into (someone|his|her|their|my (ex|boss|neighbour|neighbor))'?s? (account|phone|email|system)\b",
    r"\bhelp me (hack|break into)\b",
    r"\bwrite (me |us )?(a |an )?(threatening|blackmail|extortion) (message|letter|email|note)\b",
    r"\b(steal|get) (someone'?s|his|her|their) (password|otp|credit card)\b.*\bfor me\b",
    r"\bwithout (getting caught|leaving evidence|it being traced)\b",
]

_SELF_HARM_PATTERNS = [
    r"\b(i want to|i'?m going to|thinking about|planning to) (kill myself|end my life|die by suicide)\b",
    r"\bhow (do|can) i (commit suicide|kill myself)\b",
    r"\bi (don'?t|do not) want to (live|be alive) anymore\b",
]

# If the message also reads as an informational legal question, that framing wins — never flag it.
_LEGAL_QUESTION_MARKERS = [
    r"\b(is|are|was|were)\b.{0,60}\b(illegal|a crime|an offence|punishable|legal)\b",
    r"\bis it (a crime|illegal|an offence)\b",
    r"\bwhat (is|are) the (punishment|penalty|section|law)\b",
    r"\bwhat happens if\b",
    r"\bcan (i|someone|a person) be (charged|arrested|prosecuted|punished)\b",
    r"\bwhich section\b",
    r"\bexplain\b",
    r"\bdefine\b",
]

_harmful_re = re.compile("|".join(_HARMFUL_REQUEST_PATTERNS), re.IGNORECASE)
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

HARMFUL_REQUEST_RESPONSE = (
    "I can't help plan or carry out something illegal or harmful. If "
    "you'd like, I'm glad to explain the relevant law itself instead — "
    "for example, what counts as an offence here, what the punishment "
    "is, or what your options are if you're on the receiving end of "
    "something like this."
)


def classify_message_risk(text):
    """Heuristic pre-filter; returns 'self_harm', 'harmful_request', or None."""
    if _self_harm_re.search(text):
        return "self_harm"
    if _harmful_re.search(text) and not _legal_question_re.search(text):
        return "harmful_request"
    return None
