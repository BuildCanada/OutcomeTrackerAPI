"""CLI entry point for the commitment evaluation agent."""

import os
import time
import uuid

import click
import httpx

from agent.evaluator import (
    evaluate_commitment,
    process_bill_change,
    process_entry,
    weekly_scan_commitment,
)


def _fetch_commitments(status=None, policy_area=None, limit=100):
    """Fetch commitments from the Rails REST API, oldest-assessed first."""
    rails_url = os.environ.get("RAILS_API_URL", "http://localhost:3000")
    params = {"per_page": limit, "sort": "last_assessed_at", "direction": "asc"}
    if status:
        params["status"] = status
    if policy_area:
        params["policy_area"] = policy_area

    resp = httpx.get(f"{rails_url}/commitments", params=params, timeout=30.0)
    resp.raise_for_status()
    return resp.json().get("commitments", [])


@click.group()
def cli():
    """Build Canada Commitment Evaluation Agent."""
    pass


@cli.command()
@click.option("--commitment-id", required=True, type=int, help="Commitment ID to evaluate")
@click.option("--as-of", default=None, help="Evaluate as of this date (YYYY-MM-DD) for backfilling")
def evaluate(commitment_id: int, as_of: str | None):
    """Evaluate a single commitment end-to-end."""
    click.echo(f"Evaluating commitment {commitment_id}...")
    start = time.time()
    result = evaluate_commitment(commitment_id, as_of_date=as_of)
    elapsed = time.time() - start
    click.echo(f"\n{result}")
    click.echo(f"\nCompleted in {elapsed:.1f}s")


@cli.command("process-entry")
@click.option("--entry-id", required=True, type=int, help="Entry ID to process")
@click.option("--as-of", default=None, help="Process as of this date (YYYY-MM-DD)")
def process_entry_cmd(entry_id: int, as_of: str | None):
    """Process a new scraped entry and match to commitments."""
    click.echo(f"Processing entry {entry_id}...")
    start = time.time()
    result = process_entry(entry_id, as_of_date=as_of)
    elapsed = time.time() - start
    click.echo(f"\n{result}")
    click.echo(f"\nCompleted in {elapsed:.1f}s")


@cli.command("process-bill-change")
@click.option("--bill-id", required=True, type=int, help="Bill database ID")
@click.option("--as-of", default=None, help="Process as of this date (YYYY-MM-DD)")
def process_bill_change_cmd(bill_id: int, as_of: str | None):
    """Process a bill stage change and re-evaluate linked commitments."""
    click.echo(f"Processing bill change for bill {bill_id}...")
    start = time.time()
    result = process_bill_change(bill_id, as_of_date=as_of)
    elapsed = time.time() - start
    click.echo(f"\n{result}")
    click.echo(f"\nCompleted in {elapsed:.1f}s")


@cli.command("scan-all")
@click.option("--limit", default=100, help="Max commitments to evaluate per run")
@click.option("--status", default=None, help="Filter by status")
@click.option("--policy-area", default=None, help="Filter by policy area slug")
@click.option("--as-of", default=None, help="Evaluate as of this date (YYYY-MM-DD)")
def scan_all(limit: int, status: str | None, policy_area: str | None, as_of: str | None):
    """Weekly proactive scan — evaluate all commitments."""
    click.echo("Starting weekly scan...")
    run_id = str(uuid.uuid4())

    commitments = _fetch_commitments(
        status=status,
        policy_area=policy_area,
        limit=limit,
    )

    click.echo(f"Found {len(commitments)} commitments to evaluate (run {run_id})")

    for i, c in enumerate(commitments, 1):
        cid = c["id"]
        title = c.get("title", "")[:60]
        click.echo(f"\n[{i}/{len(commitments)}] Commitment {cid}: {title}")

        try:
            start = time.time()
            result = weekly_scan_commitment(cid, as_of_date=as_of)
            elapsed = time.time() - start
            click.echo(f"  Done in {elapsed:.1f}s")
        except Exception as e:
            click.echo(f"  ERROR: {e}", err=True)

    click.echo(f"\nWeekly scan complete. Evaluated {len(commitments)} commitments.")


if __name__ == "__main__":
    cli()
