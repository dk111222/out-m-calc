#!/usr/bin/env python3
"""Write assets/tricks/catalog.json. Numbers are checked by the Dart engine."""

import json
from pathlib import Path

tricks = []


def add(trick):
    assert len(trick["acceptance"]) >= 5
    assert 2 <= len(trick["steps"]) <= 4
    tricks.append(trick)


def acc(args, steps, final):
    return {"args": args, "steps": steps, "final": final}


add({
    "id": "k-pairs-10",
    "grade": "K",
    "operation": "addition",
    "title": "Pairs to 10",
    "appliesWhen": "You know one number from 0 to 9 and need the partner that makes 10.",
    "notWhen": "The two numbers do not make 10, such as 6 + 6. Add those directly.",
    "steps": [
        {"n": 1, "title": "Find the gap", "body": "Subtract the number you have from 10."},
        {"n": 2, "title": "Check the pair", "body": "Add your number and the gap. The total is 10."},
    ],
    "example": {
        "prompt": "3 + ? = 10",
        "pieces": [
            {"text": "3", "step": 1},
            {"text": " + ? = ", "step": 0},
            {"text": "10", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "3 needs 7"},
            {"step": 2, "text": "3 + 7 = 10"},
        ],
    },
    "shortRange": "Partners for 1 through 5.",
    "standardRange": "Partners for 0 through 9.",
    "ready": True,
    "acceptance": [
        acc({"n": 3}, ["7", "10"], "7"),
        acc({"n": 1}, ["9", "10"], "9"),
        acc({"n": 8}, ["2", "10"], "2"),
        acc({"n": 5}, ["5", "10"], "5"),
        acc({"n": 0}, ["10", "10"], "10"),
    ],
})

bridge_steps = [
    {"n": 1, "title": "Reach 10", "body": "See how many the first number still needs to make 10."},
    {"n": 2, "title": "Split the other number", "body": "Take that many away from the second number."},
    {"n": 3, "title": "Add the leftover", "body": "Add what remains to 10."},
]
add({
    "id": "g1-make-10",
    "grade": "1",
    "operation": "addition",
    "title": "Make 10",
    "appliesWhen": "You add two one-digit numbers and the total is more than 10.",
    "notWhen": "The total is 10 or less, such as 4 + 5. Add those in one move.",
    "steps": bridge_steps,
    "example": {
        "prompt": "8 + 7",
        "pieces": [
            {"text": "8", "step": 1},
            {"text": " + ", "step": 0},
            {"text": "7", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "8 needs 2"},
            {"step": 2, "text": "7 leaves 5"},
            {"step": 3, "text": "10 + 5 = 15"},
        ],
    },
    "shortRange": "The first number is 8 or 9.",
    "standardRange": "Both numbers are from 2 to 9, and the total is over 10.",
    "ready": True,
    "acceptance": [
        acc({"a": 8, "b": 7}, ["2", "5", "15"], "15"),
        acc({"a": 9, "b": 6}, ["1", "5", "15"], "15"),
        acc({"a": 7, "b": 5}, ["3", "2", "12"], "12"),
        acc({"a": 6, "b": 8}, ["4", "4", "14"], "14"),
        acc({"a": 9, "b": 9}, ["1", "8", "18"], "18"),
    ],
})
add({
    "id": "g1-add-20",
    "grade": "1",
    "operation": "addition",
    "title": "Add within 20",
    "appliesWhen": "You add two one-digit numbers, the total stays within 20, and it crosses 10.",
    "notWhen": "The total is 10 or less. Those sums do not need a split.",
    "steps": [
        {"n": 1, "title": "Reach 10", "body": "Find the gap from the first number up to 10."},
        {"n": 2, "title": "Leftover", "body": "Subtract that gap from the second number."},
        {"n": 3, "title": "Finish", "body": "Add the leftover to 10. The total stays under 20."},
    ],
    "example": {
        "prompt": "9 + 6",
        "pieces": [
            {"text": "9", "step": 1},
            {"text": " + ", "step": 0},
            {"text": "6", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "9 needs 1"},
            {"step": 2, "text": "6 leaves 5"},
            {"step": 3, "text": "10 + 5 = 15"},
        ],
    },
    "shortRange": "One number is 8 or 9.",
    "standardRange": "Totals from 11 through 18.",
    "ready": True,
    "acceptance": [
        acc({"a": 9, "b": 4}, ["1", "3", "13"], "13"),
        acc({"a": 8, "b": 5}, ["2", "3", "13"], "13"),
        acc({"a": 7, "b": 7}, ["3", "4", "14"], "14"),
        acc({"a": 6, "b": 6}, ["4", "2", "12"], "12"),
        acc({"a": 5, "b": 9}, ["5", "4", "14"], "14"),
    ],
})
add({
    "id": "g2-near-100",
    "grade": "2",
    "operation": "addition",
    "title": "Near 100",
    "appliesWhen": "Both numbers are from 91 to 99.",
    "notWhen": "A number is more than 10 away from 100, such as 80 + 70.",
    "steps": [
        {"n": 1, "title": "First gap", "body": "See how far the first number is under 100."},
        {"n": 2, "title": "Second gap", "body": "See how far the second number is under 100."},
        {"n": 3, "title": "Combine the gaps", "body": "Add the two gaps."},
        {"n": 4, "title": "Take them off 200", "body": "Subtract that sum from 200."},
    ],
    "example": {
        "prompt": "97 + 96",
        "pieces": [
            {"text": "97", "step": 1},
            {"text": " + ", "step": 0},
            {"text": "96", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "97 is 3 under 100"},
            {"step": 2, "text": "96 is 4 under 100"},
            {"step": 3, "text": "The gaps add to 7"},
            {"step": 4, "text": "200 − 7 = 193"},
        ],
    },
    "shortRange": "Both numbers are from 95 to 99.",
    "standardRange": "Both numbers are from 91 to 99.",
    "ready": True,
    "acceptance": [
        acc({"a": 97, "b": 96}, ["3", "4", "7", "193"], "193"),
        acc({"a": 95, "b": 95}, ["5", "5", "10", "190"], "190"),
        acc({"a": 99, "b": 91}, ["1", "9", "10", "190"], "190"),
        acc({"a": 98, "b": 97}, ["2", "3", "5", "195"], "195"),
        acc({"a": 96, "b": 94}, ["4", "6", "10", "190"], "190"),
    ],
})
add({
    "id": "g2-sub-100",
    "grade": "2",
    "operation": "subtraction",
    "title": "Subtract near 100",
    "appliesWhen": "You subtract a number from 91 to 99 from a number that is at least 100.",
    "notWhen": "You subtract a small number, such as 150 − 6.",
    "steps": [
        {"n": 1, "title": "Gap under 100", "body": "See how far the number you subtract is under 100."},
        {"n": 2, "title": "Drop a hundred", "body": "Take 100 off the starting number."},
        {"n": 3, "title": "Give the gap back", "body": "Add that gap to what you have left."},
    ],
    "example": {
        "prompt": "150 − 97",
        "pieces": [
            {"text": "150", "step": 2},
            {"text": " − ", "step": 0},
            {"text": "97", "step": 1},
        ],
        "notes": [
            {"step": 1, "text": "97 is 3 under 100"},
            {"step": 2, "text": "150 − 100 = 50"},
            {"step": 3, "text": "50 + 3 = 53"},
        ],
    },
    "shortRange": "The starting number is from 100 to 130.",
    "standardRange": "The starting number is from 100 to 199.",
    "ready": True,
    "acceptance": [
        acc({"a": 150, "b": 97}, ["3", "50", "53"], "53"),
        acc({"a": 120, "b": 95}, ["5", "20", "25"], "25"),
        acc({"a": 200, "b": 99}, ["1", "100", "101"], "101"),
        acc({"a": 110, "b": 91}, ["9", "10", "19"], "19"),
        acc({"a": 180, "b": 96}, ["4", "80", "84"], "84"),
    ],
})
add({
    "id": "g3-times-5",
    "grade": "3",
    "operation": "multiplication",
    "title": "Multiply by 5",
    "appliesWhen": "You multiply a whole number by 5.",
    "notWhen": "You multiply by 10 or by 50. Those are different moves.",
    "steps": [
        {"n": 1, "title": "Times 10", "body": "Multiply the number by 10."},
        {"n": 2, "title": "Half", "body": "Take half of that. The half is the product."},
    ],
    "example": {
        "prompt": "48 × 5",
        "pieces": [
            {"text": "48", "step": 1},
            {"text": " × 5", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "48 × 10 = 480"},
            {"step": 2, "text": "Half of 480 is 240"},
        ],
    },
    "shortRange": "The number is from 10 to 40.",
    "standardRange": "The number is from 12 to 99.",
    "ready": True,
    "acceptance": [
        acc({"n": 48}, ["480", "240"], "240"),
        acc({"n": 16}, ["160", "80"], "80"),
        acc({"n": 25}, ["250", "125"], "125"),
        acc({"n": 70}, ["700", "350"], "350"),
        acc({"n": 13}, ["130", "65"], "65"),
    ],
})
add({
    "id": "g3-times-11",
    "grade": "3",
    "operation": "multiplication",
    "title": "Multiply by 11",
    "appliesWhen": "You multiply a two-digit number by 11 and the digits add to less than 10.",
    "notWhen": "The digits add to 10 or more, such as 48 × 11. That product needs a carry.",
    "steps": [
        {"n": 1, "title": "Add the digits", "body": "Add the tens digit and the ones digit."},
        {"n": 2, "title": "Place the sum", "body": "Write the tens digit, the sum, then the ones digit."},
    ],
    "example": {
        "prompt": "35 × 11",
        "pieces": [
            {"text": "3", "step": 1},
            {"text": "5", "step": 1},
            {"text": " × 11", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "3 + 5 = 8"},
            {"step": 2, "text": "The product is 385"},
        ],
    },
    "shortRange": "The tens digit is 1, 2, or 3.",
    "standardRange": "Any two-digit number whose digits add to less than 10.",
    "ready": True,
    "acceptance": [
        acc({"n": 35}, ["8", "385"], "385"),
        acc({"n": 24}, ["6", "264"], "264"),
        acc({"n": 18}, ["9", "198"], "198"),
        acc({"n": 42}, ["6", "462"], "462"),
        acc({"n": 63}, ["9", "693"], "693"),
    ],
})
add({
    "id": "g3-div-5",
    "grade": "3",
    "operation": "division",
    "title": "Divide by 5",
    "appliesWhen": "You divide a whole number by 5.",
    "notWhen": "You divide by 10 or by 2. Use those facts directly.",
    "steps": [
        {"n": 1, "title": "Double", "body": "Multiply the number by 2."},
        {"n": 2, "title": "Move the decimal", "body": "Divide that double by 10."},
    ],
    "example": {
        "prompt": "35 ÷ 5",
        "pieces": [
            {"text": "35", "step": 1},
            {"text": " ÷ 5", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "35 × 2 = 70"},
            {"step": 2, "text": "70 ÷ 10 = 7"},
        ],
    },
    "shortRange": "Multiples of 5.",
    "standardRange": "Whole numbers from 10 to 99. Some answers use one decimal place.",
    "ready": True,
    "acceptance": [
        acc({"n": 35}, ["70", "7"], "7"),
        acc({"n": 40}, ["80", "8"], "8"),
        acc({"n": 48}, ["96", "9.6"], "9.6"),
        acc({"n": 15}, ["30", "3"], "3"),
        acc({"n": 27}, ["54", "5.4"], "5.4"),
    ],
})
add({
    "id": "g4-times-11-carry",
    "grade": "4",
    "operation": "multiplication",
    "title": "Multiply by 11 with a carry",
    "appliesWhen": "You multiply a two-digit number by 11 and the digits add to 10 or more.",
    "notWhen": "The digits add to less than 10. Those products do not carry.",
    "steps": [
        {"n": 1, "title": "Add the digits", "body": "Add the tens digit and the ones digit."},
        {"n": 2, "title": "Middle digit", "body": "Keep the ones digit of that sum. The tens digit is a carry."},
        {"n": 3, "title": "Build the product", "body": "Add the carry to the first digit, then write the middle and last digits."},
    ],
    "example": {
        "prompt": "48 × 11",
        "pieces": [
            {"text": "4", "step": 1},
            {"text": "8", "step": 1},
            {"text": " × 11", "step": 3},
        ],
        "notes": [
            {"step": 1, "text": "4 + 8 = 12"},
            {"step": 2, "text": "The middle digit is 2"},
            {"step": 3, "text": "The product is 528"},
        ],
    },
    "shortRange": "The tens digit is 2, 3, or 4.",
    "standardRange": "Any two-digit number whose digits add to 10 or more.",
    "ready": True,
    "acceptance": [
        acc({"n": 48}, ["12", "2", "528"], "528"),
        acc({"n": 76}, ["13", "3", "836"], "836"),
        acc({"n": 59}, ["14", "4", "649"], "649"),
        acc({"n": 37}, ["10", "0", "407"], "407"),
        acc({"n": 85}, ["13", "3", "935"], "935"),
    ],
})
add({
    "id": "g4-complements",
    "grade": "4",
    "operation": "multiplication",
    "title": "Ends that add to 10",
    "appliesWhen": "Two two-digit numbers share a tens digit, and the ones digits add to 10.",
    "notWhen": "The ones digits do not add to 10, such as 26 × 23.",
    "steps": [
        {"n": 1, "title": "Check the ones", "body": "Add the ones digits. They should make 10."},
        {"n": 2, "title": "Front part", "body": "Multiply the tens digit by the next whole number."},
        {"n": 3, "title": "Back part", "body": "Multiply the ones digits. If the product is one digit, the tens place is 0."},
        {"n": 4, "title": "Join", "body": "Write the front part, then the back part as two digits."},
    ],
    "example": {
        "prompt": "26 × 24",
        "pieces": [
            {"text": "2", "step": 2},
            {"text": "6", "step": 3},
            {"text": " × ", "step": 0},
            {"text": "2", "step": 2},
            {"text": "4", "step": 3},
        ],
        "notes": [
            {"step": 1, "text": "6 + 4 = 10"},
            {"step": 2, "text": "2 × 3 = 6"},
            {"step": 3, "text": "6 × 4 = 24"},
            {"step": 4, "text": "The product is 624"},
        ],
    },
    "shortRange": "The tens digit is 1, 2, or 3.",
    "standardRange": "The tens digit is from 1 to 9.",
    "ready": True,
    "acceptance": [
        acc({"t": 2, "x": 6, "y": 4}, ["10", "6", "24", "624"], "624"),
        acc({"t": 3, "x": 5, "y": 5}, ["10", "12", "25", "1225"], "1225"),
        acc({"t": 4, "x": 2, "y": 8}, ["10", "20", "16", "2016"], "2016"),
        acc({"t": 1, "x": 3, "y": 7}, ["10", "2", "21", "221"], "221"),
        acc({"t": 8, "x": 1, "y": 9}, ["10", "72", "9", "7209"], "7209"),
    ],
})
add({
    "id": "g4-square-5",
    "grade": "4",
    "operation": "multiplication",
    "title": "Squares ending in 5",
    "appliesWhen": "You square a two-digit number that ends in 5.",
    "notWhen": "The number does not end in 5, such as 40² or 46².",
    "steps": [
        {"n": 1, "title": "Front part", "body": "Multiply the tens digit by the next whole number."},
        {"n": 2, "title": "Attach 25", "body": "Write that product in front of 25."},
    ],
    "example": {
        "prompt": "45²",
        "pieces": [
            {"text": "4", "step": 1},
            {"text": "5²", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "4 × 5 = 20"},
            {"step": 2, "text": "20 followed by 25 is 2025"},
        ],
    },
    "shortRange": "15, 25, 35, and 45.",
    "standardRange": "Every two-digit number that ends in 5.",
    "ready": True,
    "acceptance": [
        acc({"t": 4}, ["20", "2025"], "2025"),
        acc({"t": 1}, ["2", "225"], "225"),
        acc({"t": 2}, ["6", "625"], "625"),
        acc({"t": 8}, ["72", "7225"], "7225"),
        acc({"t": 9}, ["90", "9025"], "9025"),
    ],
})
add({
    "id": "g4-div-25",
    "grade": "4",
    "operation": "division",
    "title": "Divide by 25",
    "appliesWhen": "You divide a whole number by 25.",
    "notWhen": "You divide by 5 or by 50. Use those moves instead.",
    "steps": [
        {"n": 1, "title": "Times 4", "body": "Multiply the number by 4."},
        {"n": 2, "title": "Move two places", "body": "Divide that product by 100."},
    ],
    "example": {
        "prompt": "75 ÷ 25",
        "pieces": [
            {"text": "75", "step": 1},
            {"text": " ÷ 25", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "75 × 4 = 300"},
            {"step": 2, "text": "300 ÷ 100 = 3"},
        ],
    },
    "shortRange": "25, 50, 75, 100, and 125.",
    "standardRange": "Multiples of 5 up to 250, including every multiple of 25.",
    "ready": True,
    "acceptance": [
        acc({"n": 75}, ["300", "3"], "3"),
        acc({"n": 125}, ["500", "5"], "5"),
        acc({"n": 175}, ["700", "7"], "7"),
        acc({"n": 50}, ["200", "2"], "2"),
        acc({"n": 250}, ["1000", "10"], "10"),
    ],
})
add({
    "id": "g5-percent-10",
    "grade": "5",
    "operation": "percent",
    "title": "Ten percent",
    "appliesWhen": "You need 10% of a whole-dollar price.",
    "notWhen": "The percent is 15% or 20%. Those are not one tenth.",
    "steps": [
        {"n": 1, "title": "The divisor", "body": "10% means one tenth, so you divide by 10."},
        {"n": 2, "title": "The part", "body": "Divide the price by 10. That amount is 10%."},
    ],
    "example": {
        "prompt": "10% of $80",
        "pieces": [
            {"text": "10%", "step": 1},
            {"text": " of ", "step": 0},
            {"text": "$80", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "Divide by 10"},
            {"step": 2, "text": "80 ÷ 10 = 8"},
        ],
    },
    "shortRange": "Prices of $100 and $200.",
    "standardRange": "Multiples of $10 from $10 to $200.",
    "ready": True,
    "acceptance": [
        acc({"n": 80}, ["10", "8"], "8"),
        acc({"n": 50}, ["10", "5"], "5"),
        acc({"n": 10}, ["10", "1"], "1"),
        acc({"n": 200}, ["10", "20"], "20"),
        acc({"n": 120}, ["10", "12"], "12"),
    ],
})
add({
    "id": "g5-percent-5",
    "grade": "5",
    "operation": "percent",
    "title": "Five percent",
    "appliesWhen": "You need 5% of a whole-dollar price.",
    "notWhen": "The question asks for 10% only, or for a percent other than 5.",
    "steps": [
        {"n": 1, "title": "Ten percent first", "body": "Find 10% of the price."},
        {"n": 2, "title": "Take half", "body": "5% is half of that 10%."},
    ],
    "example": {
        "prompt": "5% of $80",
        "pieces": [
            {"text": "5%", "step": 2},
            {"text": " of ", "step": 0},
            {"text": "$80", "step": 1},
        ],
        "notes": [
            {"step": 1, "text": "10% of 80 is 8"},
            {"step": 2, "text": "Half of 8 is 4"},
        ],
    },
    "shortRange": "Multiples of $20.",
    "standardRange": "Multiples of $10 from $10 to $200.",
    "ready": True,
    "acceptance": [
        acc({"n": 80}, ["8", "4"], "4"),
        acc({"n": 40}, ["4", "2"], "2"),
        acc({"n": 20}, ["2", "1"], "1"),
        acc({"n": 100}, ["10", "5"], "5"),
        acc({"n": 60}, ["6", "3"], "3"),
    ],
})
add({
    "id": "g5-percent-1",
    "grade": "5",
    "operation": "percent",
    "title": "One percent",
    "appliesWhen": "You need 1% of a whole-dollar price.",
    "notWhen": "The question asks for 10%. One percent is a hundredth, not a tenth.",
    "steps": [
        {"n": 1, "title": "The divisor", "body": "1% means one hundredth, so you divide by 100."},
        {"n": 2, "title": "The part", "body": "Divide the price by 100."},
    ],
    "example": {
        "prompt": "1% of $80",
        "pieces": [
            {"text": "1%", "step": 1},
            {"text": " of ", "step": 0},
            {"text": "$80", "step": 2},
        ],
        "notes": [
            {"step": 1, "text": "Divide by 100"},
            {"step": 2, "text": "80 ÷ 100 = 0.8"},
        ],
    },
    "shortRange": "Multiples of $100.",
    "standardRange": "Multiples of $10 from $10 to $200.",
    "ready": True,
    "acceptance": [
        acc({"n": 80}, ["100", "0.8"], "0.8"),
        acc({"n": 50}, ["100", "0.5"], "0.5"),
        acc({"n": 100}, ["100", "1"], "1"),
        acc({"n": 25}, ["100", "0.25"], "0.25"),
        acc({"n": 10}, ["100", "0.1"], "0.1"),
    ],
})

path = Path(__file__).resolve().parents[1] / "assets" / "tricks" / "catalog.json"
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps({"tricks": tricks}, indent=2) + "\n")
print(f"wrote {len(tricks)} tricks to {path}")
