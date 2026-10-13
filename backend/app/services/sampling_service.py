CENTER_ONLY = ["center"]
TWO_CORNERS_AND_CENTER = ["corner_1", "corner_2", "center"]
FOUR_CORNERS_AND_CENTER = ["corner_1", "corner_2", "corner_3", "corner_4", "center"]
QUADRANTS_AND_CENTER = ["quadrant_1", "quadrant_2", "quadrant_3", "quadrant_4", "center"]


def required_points_for_area(size_acres: float) -> list[str]:
    """Single source of truth for soil-sample point tiers, mirrored in Flutter for layout.

    | Area          | Points | Labels                                |
    |---------------|--------|----------------------------------------|
    | < 0.5 acre    | 1      | center                                 |
    | 0.5-2 acres   | 3      | corner_1, corner_2, center              |
    | 2-5 acres     | 5      | corner_1..corner_4, center              |
    | > 5 acres     | 5      | quadrant_1..quadrant_4, center          |
    """
    if size_acres < 0.5:
        return list(CENTER_ONLY)
    if size_acres <= 2:
        return list(TWO_CORNERS_AND_CENTER)
    if size_acres <= 5:
        return list(FOUR_CORNERS_AND_CENTER)
    return list(QUADRANTS_AND_CENTER)
