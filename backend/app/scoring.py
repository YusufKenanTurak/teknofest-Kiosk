from __future__ import annotations

CALCULATION_VERSION = "score-v1-endscan"

VALID_CODES = ("B", "K", "Ç", "M", "E", "İ", "N")


def tally(codes: list[str]) -> dict[str, int]:
    scores = {code: 0 for code in VALID_CODES}
    for code in codes:
        if code not in scores:
            raise ValueError(f"Unknown engineering code: {code}")
        scores[code] += 1
    return scores


def calculate_result(codes: list[str]) -> str:
    """Same rule as Flutter ScoreEngine: +1 per answer, last tied code wins."""
    if not codes:
        raise ValueError("Cannot calculate a result from an empty answer list.")
    scores = tally(codes)
    max_score = max(scores.values())
    if max_score <= 0:
        raise ValueError("Cannot resolve a winner from empty scores.")
    tied = {code for code, score in scores.items() if score == max_score}
    if len(tied) == 1:
        return next(iter(tied))
    for code in reversed(codes):
        if code in tied:
            return code
    raise ValueError("Cannot resolve a winner; answers do not contain a max-score field.")
