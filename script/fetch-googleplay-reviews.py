from google_play_scraper import reviews, Sort
import csv

APP_PACKAGES = {
    # 替换成真实包名
    "Math Fact Master": "com.xxx.mathfactmaster",
    "Matharoo Flashcards": "com.xxx.matharoo"
}
OUTPUT_CSV = "googleplay_reviews.csv"

all_rows = []
for app_name, pkg in APP_PACKAGES.items():
    try:
        result, token = reviews(
            pkg,
            lang="en",
            country="us",
            sort=Sort.NEWEST,
            count=100
        )
        for item in result:
            if item["score"] <=3:
                all_rows.append({
                    "app": app_name,
                    "score": item["score"],
                    "content": item["content"],
                    "title": item["title"]
                })
    except Exception as e:
        print(f"google play err {app_name}: {e}")

with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["app","score","title","content"])
    w.writeheader()
    w.writerows(all_rows)
print(f"Google play scrape done, {len(all_rows)} negative reviews")
