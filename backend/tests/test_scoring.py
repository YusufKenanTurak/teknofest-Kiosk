from app.scoring import calculate_result, tally


def test_tally_counts_each_code():
    scores = tally(["B", "B", "K", "Ç"])
    assert scores["B"] == 2
    assert scores["K"] == 1
    assert scores["Ç"] == 1
    assert scores["N"] == 0


def test_clear_winner():
    codes = ["B"] * 8 + ["K"] * 7
    assert calculate_result(codes) == "B"


def test_tie_uses_last_tied_code_from_end():
    # 7-7 split: last tied code in reverse scan is K.
    codes = ["B", "K"] * 7 + ["Ç"]
    assert calculate_result(codes) == "K"


def test_three_way_tie_last_from_end():
    codes = ["B", "K", "Ç"] * 5
    assert calculate_result(codes) == "Ç"
