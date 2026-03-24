from urllib.parse import urlparse

ALLOWED_SUFFIXES = (".canada.ca", ".gc.ca")


def is_government_url(url: str) -> bool:
    """Check if a URL belongs to an allowed Canadian government domain."""
    try:
        parsed = urlparse(url)
        hostname = parsed.hostname
        if hostname is None:
            return False
        return any(
            hostname == suffix.lstrip(".") or hostname.endswith(suffix)
            for suffix in ALLOWED_SUFFIXES
        )
    except Exception:
        return False


def validate_government_url(url: str) -> str:
    """Validate and return the URL, or raise ValueError if not a government domain."""
    if not is_government_url(url):
        raise ValueError(
            f"URL rejected: {url} is not on an allowed government domain "
            f"(must end with {' or '.join(ALLOWED_SUFFIXES)})"
        )
    return url
