"""Domain-restricted web search and fetch tools using Claude's built-in capabilities."""

from urllib.parse import urlparse

import httpx
from bs4 import BeautifulSoup
from markdownify import markdownify

from agent.domain.validators import is_government_url, validate_government_url


def fetch_government_page(url: str) -> dict:
    """
    Fetch and parse content from an official Canadian government webpage.
    Only URLs matching *.canada.ca or *.gc.ca are allowed.
    """
    try:
        validate_government_url(url)
    except ValueError as e:
        return {"error": str(e)}

    try:
        resp = httpx.get(
            url,
            follow_redirects=True,
            timeout=30.0,
            headers={"User-Agent": "BuildCanada-Tracker/1.0"},
        )
        resp.raise_for_status()
    except httpx.HTTPError as e:
        return {"error": f"Failed to fetch {url}: {e}"}

    # Verify the final URL (after redirects) is still on a government domain
    if not is_government_url(str(resp.url)):
        return {"error": f"Redirect led to non-government domain: {resp.url}"}

    soup = BeautifulSoup(resp.text, "html.parser")

    # Remove nav, footer, scripts, styles
    for tag in soup.find_all(["nav", "footer", "script", "style", "header"]):
        tag.decompose()

    # Try to find the main content area (canada.ca uses specific IDs)
    main = (
        soup.find("main")
        or soup.find(id="wb-cont")
        or soup.find(class_="mwsgeneric-base-html")
        or soup.find("article")
        or soup.body
    )

    content_html = str(main) if main else str(soup)
    content_md = markdownify(content_html, strip=["img", "a"]).strip()

    # Truncate very long pages
    if len(content_md) > 15000:
        content_md = content_md[:15000] + "\n\n[Content truncated at 15,000 characters]"

    title = soup.title.string.strip() if soup.title and soup.title.string else ""

    # Try to find publication date
    published_date = None
    date_meta = soup.find("meta", {"name": "dcterms.modified"}) or soup.find(
        "meta", {"name": "dcterms.issued"}
    )
    if date_meta:
        published_date = date_meta.get("content")

    return {
        "url": str(resp.url),
        "title": title,
        "content_markdown": content_md,
        "published_date": published_date,
    }


def filter_search_results(results: list[dict]) -> list[dict]:
    """Post-filter search results to only include government domains."""
    return [r for r in results if is_government_url(r.get("url", ""))]
